#!/usr/bin/env python3

import argparse
from contextlib import contextmanager
import fcntl
import hashlib
import json
import os
from pathlib import Path
import re
import sys
import tempfile


class HistoryError(Exception):
    pass


def digest(value):
    return hashlib.sha256(value).hexdigest()


def encoded(value):
    return json.dumps(value, ensure_ascii=False, sort_keys=True, separators=(',', ':')).encode()


def absolute(value):
    path = Path(value).expanduser()
    if not path.is_absolute():
        raise HistoryError('paths must be absolute')
    return path.resolve()


def contains(root, path):
    return path == root or root in path.parents


def read_json(path):
    try:
        return json.loads(path.read_text())
    except (OSError, ValueError) as error:
        raise HistoryError(f'cannot read JSON from {path}: {error}') from error


def fingerprint(path):
    before = path.stat()
    if not path.is_file():
        raise HistoryError(f'not a transcript file: {path}')
    checksum = hashlib.sha256()
    lines = 0
    last = b''
    with path.open('rb') as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b''):
            checksum.update(chunk)
            lines += chunk.count(b'\n')
            last = chunk[-1:]
    after = path.stat()
    if (before.st_ino, before.st_size, before.st_mtime_ns) != (after.st_ino, after.st_size, after.st_mtime_ns):
        raise HistoryError(f'transcript changed during scan: {path}')
    return {'path': str(path), 'mtime_ns': after.st_mtime_ns, 'size': after.st_size,
            'sha256': checksum.hexdigest(), 'lines': lines + int(bool(last) and last != b'\n')}


class History:
    def __init__(self, project, state_dir=None):
        self.project = absolute(project)
        if not self.project.is_dir():
            raise HistoryError('project must be an existing directory')
        base = Path(os.environ.get('XDG_STATE_HOME', Path.home() / '.local/state')).expanduser()
        self.directory = absolute(state_dir) if state_dir else base.resolve() / 'agentic-devkit/learn' / digest(str(self.project).encode())[:16]
        if contains(self.project, self.directory) or self.directory.name.casefold() in {'agents.md', 'claude.md'}:
            raise HistoryError('learning state must be outside the project and instruction files')
        if self.directory.exists() and not self.directory.is_dir():
            raise HistoryError('state directory is not a directory')
        self.path = self.directory / 'state.json'

    def load(self):
        state = read_json(self.path) if self.path.exists() else {
            'version': 1, 'project': str(self.project), 'files': {}, 'candidates': {}}
        if (not isinstance(state, dict) or state.get('version') != 1 or state.get('project') != str(self.project)
                or not isinstance(state.get('files'), dict) or not isinstance(state.get('candidates'), dict)):
            raise HistoryError('state schema or project does not match')
        return state

    @contextmanager
    def locked(self):
        self.directory.mkdir(mode=0o700, parents=True, exist_ok=True)
        if self.directory.stat().st_mode & 0o077:
            raise HistoryError('state directory must be private (mode 0700)')
        descriptor = os.open(self.directory / '.lock', os.O_CREAT | os.O_RDWR, 0o600)
        with os.fdopen(descriptor, 'r+') as lock:
            fcntl.flock(lock, fcntl.LOCK_EX)
            yield

    def save(self, state):
        descriptor, name = tempfile.mkstemp(prefix='.state-', dir=self.directory)
        try:
            with os.fdopen(descriptor, 'wb') as output:
                output.write(encoded(state) + b'\n')
                output.flush()
                os.fsync(output.fileno())
            os.replace(name, self.path)
        finally:
            if os.path.exists(name):
                os.unlink(name)

    def scan(self, sources, limit):
        if not 1 <= limit <= 100:
            raise HistoryError('limit must be between 1 and 100')
        state = self.load()
        roots = sorted({absolute(source) for source in sources})
        files, valid_roots, errors, skipped = {}, [], [], 0
        for root in roots:
            if not root.exists() and any(contains(root, Path(path)) for path in state['files']):
                valid_roots.append(root)
                continue
            if not root.exists() or (root.is_file() and root.suffix != '.jsonl'):
                errors.append({'path': str(root), 'error': 'source must be an existing JSONL file or directory'})
                continue
            valid_roots.append(root)
            paths = root.rglob('*.jsonl') if root.is_dir() else [root]
            for path in paths:
                resolved = path.resolve()
                if (not contains(root, resolved) or {'subagents', 'compaction'} & set(path.relative_to(root).parts)):
                    skipped += 1
                    continue
                try:
                    current = fingerprint(resolved)
                    if state['files'].get(str(resolved)) != current:
                        files[str(resolved)] = current
                except (OSError, HistoryError) as error:
                    errors.append({'path': str(path), 'error': str(error)})
        ordered = sorted(files.values(), key=lambda item: item['path'])
        removed = [path for path in state['files'] if not Path(path).exists()
                   and any(contains(root, Path(path)) for root in valid_roots)]
        return {'version': 1, 'project': str(self.project), 'state_revision': digest(encoded(state)),
                'sources': [str(root) for root in valid_roots], 'files': ordered[:limit],
                'removed': sorted(removed), 'remaining': max(0, len(ordered) - limit),
                'skipped': skipped, 'errors': errors}

    def record(self, manifest, result):
        if (not isinstance(manifest, dict) or manifest.get('version') != 1
                or manifest.get('project') != str(self.project)
                or not isinstance(manifest.get('files'), list) or not isinstance(manifest.get('sources'), list)
                or not isinstance(manifest.get('removed'), list)):
            raise HistoryError('invalid manifest or project')
        if (not isinstance(result, dict) or set(result) != {'processed', 'candidates'}
                or not isinstance(result['processed'], list) or not isinstance(result['candidates'], list)
                or len(result['candidates']) > 12):
            raise HistoryError('result needs processed paths and at most 12 candidates')
        sources = [absolute(value) for value in manifest['sources']]
        files = {}
        for entry in manifest['files']:
            if not isinstance(entry, dict) or not isinstance(entry.get('path'), str):
                raise HistoryError('invalid manifest file')
            path = absolute(entry['path'])
            if str(path) != entry['path'] or path.suffix != '.jsonl' or not any(contains(root, path) for root in sources):
                raise HistoryError('manifest file is outside its source scope')
            if str(path) in files:
                raise HistoryError('duplicate manifest file')
            files[str(path)] = entry
        processed = result['processed']
        if any(not isinstance(path, str) or path not in files for path in processed) or len(set(processed)) != len(processed):
            raise HistoryError('processed paths must be unique manifest files')
        candidates = []
        for candidate in result['candidates']:
            if (not isinstance(candidate, dict) or set(candidate) != {'text', 'kind', 'evidence'}
                    or not isinstance(candidate['text'], str) or not candidate['text'].strip()
                    or len(candidate['text']) > 2000 or candidate['kind'] not in {'project', 'personal'}
                    or not isinstance(candidate['evidence'], list) or not candidate['evidence']):
                raise HistoryError('invalid candidate')
            evidence = []
            for item in candidate['evidence']:
                if (not isinstance(item, dict) or set(item) != {'path', 'line'} or item['path'] not in processed
                        or type(item['line']) is not int or not 1 <= item['line'] <= files[item['path']].get('lines', 0)):
                    raise HistoryError('candidate evidence must reference a processed source line')
                evidence.append({**item, 'sha256': files[item['path']]['sha256']})
            text = candidate['text'].strip()
            key = digest((candidate['kind'] + '\n' + re.sub(r'\s+', ' ', text.casefold())).encode())
            candidates.append({'id': key, 'text': text, 'kind': candidate['kind'], 'evidence': evidence, 'status': 'pending'})
        with self.locked():
            state = self.load()
            if manifest.get('state_revision') != digest(encoded(state)):
                raise HistoryError('stale state revision; scan again')
            for path in processed:
                if fingerprint(Path(path)) != files[path]:
                    raise HistoryError(f'transcript changed since scan: {path}')
            removed = manifest['removed']
            if any(not isinstance(path, str) or path not in state['files'] or Path(path).exists()
                   or not any(contains(root, Path(path)) for root in sources) for path in removed):
                raise HistoryError('invalid removed source')
            for path in processed:
                state['files'][path] = files[path]
            for path in removed:
                del state['files'][path]
            for candidate in candidates:
                existing = state['candidates'].get(candidate['id'])
                if existing:
                    if existing['status'] == 'pending':
                        existing['evidence'] = list({encoded(item): item for item in existing['evidence'] + candidate['evidence']}.values())
                else:
                    state['candidates'][candidate['id']] = candidate
            self.save(state)
            return {'recorded': len(processed), 'removed': len(removed), 'pending': len(self.pending(state)['candidates'])}

    def pending(self, state=None):
        state = state if state is not None else self.load()
        return {'version': 1, 'project': str(self.project), 'state_revision': digest(encoded(state)),
                'candidates': [item for item in state['candidates'].values() if item['status'] == 'pending']}

    def resolve(self, ids, decision):
        with self.locked():
            state = self.load()
            if any(key not in state['candidates'] or state['candidates'][key]['status'] != 'pending' for key in ids):
                raise HistoryError('every id must identify a pending candidate')
            for key in ids:
                state['candidates'][key]['status'] = decision
            self.save(state)
            return {'resolved': len(set(ids)), 'decision': decision}


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--project', required=True)
    parser.add_argument('--state-dir')
    commands = parser.add_subparsers(dest='command', required=True)
    scan = commands.add_parser('scan')
    scan.add_argument('--source', action='append', required=True)
    scan.add_argument('--limit', type=int, default=20)
    record = commands.add_parser('record')
    record.add_argument('--manifest', required=True)
    record.add_argument('--result', required=True)
    commands.add_parser('pending')
    resolve = commands.add_parser('resolve')
    resolve.add_argument('--id', action='append', required=True)
    resolve.add_argument('--decision', choices=['saved', 'dismissed'], required=True)
    args = parser.parse_args()
    try:
        history = History(args.project, args.state_dir)
        if args.command == 'scan':
            output = history.scan(args.source, args.limit)
        elif args.command == 'record':
            output = history.record(read_json(Path(args.manifest)), read_json(Path(args.result)))
        elif args.command == 'pending':
            output = history.pending()
        else:
            output = history.resolve(args.id, args.decision)
        print(json.dumps(output, ensure_ascii=False))
    except (HistoryError, OSError, ValueError, TypeError, KeyError) as error:
        print(f'learning history: {error}', file=sys.stderr)
        return 1
    return 0


if __name__ == '__main__':
    raise SystemExit(main())

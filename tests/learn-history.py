#!/usr/bin/env python3

import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest


HELPER = Path(__file__).resolve().parents[1] / 'plugins/core/skills/learn/scripts/history.py'


class HistoryTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='devkit-learn-')
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name).resolve()
        self.project = self.root / 'project'
        self.project.mkdir()
        self.source = self.root / 'transcripts'
        self.source.mkdir()
        self.state = self.root / 'state'

    def argv(self, *args):
        return [sys.executable, str(HELPER), '--project', str(self.project),
                '--state-dir', str(self.state), *args]

    def command(self, *args, fail=False):
        result = subprocess.run(self.argv(*args),
                                stdin=subprocess.DEVNULL, capture_output=True, text=True)
        if fail:
            self.assertNotEqual(result.returncode, 0, result.stdout)
            return result.stderr
        self.assertEqual(result.returncode, 0, result.stderr)
        return json.loads(result.stdout)

    def transcript(self, name='session.jsonl', text='Stable project guidance.\n'):
        path = self.source / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(text)
        return path

    def scan(self, *sources, limit=20):
        args = ['scan', '--limit', str(limit)]
        for source in sources or [self.source]:
            args.extend(['--source', str(source)])
        return self.command(*args)

    def payload(self, name, value):
        path = self.root / name
        path.write_text(json.dumps(value))
        return str(path)

    def record(self, scan, processed=None, candidates=None, fail=False):
        result = {'processed': processed if processed is not None else [item['path'] for item in scan['files']],
                  'candidates': candidates or []}
        return self.command('record', '--manifest', self.payload('manifest.json', scan),
                            '--result', self.payload('result.json', result), fail=fail)

    def candidate(self, path, text='Use the established integration entrypoint.', kind='project', line=1):
        return {'text': text, 'kind': kind, 'evidence': [{'path': str(path), 'line': line}]}

    def state_bytes(self):
        path = self.state / 'state.json'
        return path.read_bytes() if path.exists() else None

    def test_initial_scan_is_read_only(self):
        path = self.transcript()
        scan = self.scan()
        self.assertEqual([row['path'] for row in scan['files']], [str(path)])
        self.assertEqual(scan['files'][0]['lines'], 1)
        self.assertEqual(len(scan['files'][0]['sha256']), 64)
        self.assertFalse(self.state.exists())

    def test_empty_record_acknowledges_only_processed_files(self):
        first = self.transcript('a.jsonl')
        second = self.transcript('b.jsonl')
        initial = self.scan()
        self.assertEqual(self.record(initial, [str(first)])['recorded'], 1)
        self.assertEqual([item['path'] for item in self.scan()['files']], [str(second)])
        self.record(self.scan())
        self.assertEqual(self.scan()['files'], [])
        self.assertEqual(self.command('pending')['candidates'], [])

    def test_changed_content_is_detected_even_with_unchanged_mtime_and_size(self):
        path = self.transcript(text='first\n')
        self.record(self.scan())
        timestamp = path.stat().st_mtime_ns
        path.write_text('other\n')
        os.utime(path, ns=(timestamp, timestamp))
        self.assertEqual(len(self.scan()['files']), 1)

    def test_scoped_deletion_preserves_other_sources_and_pending_candidates(self):
        first = self.transcript('a/session.jsonl')
        second = self.transcript('b/session.jsonl')
        self.record(self.scan(), candidates=[self.candidate(first)])
        first.unlink()
        second.unlink()
        scan = self.scan(self.source / 'a')
        self.assertEqual(scan['removed'], [str(first)])
        self.record(scan)
        state = json.loads(self.state_bytes())
        self.assertNotIn(str(first), state['files'])
        self.assertIn(str(second), state['files'])
        self.assertEqual(len(self.command('pending')['candidates']), 1)

    def test_deleted_explicit_source_retains_only_its_previously_indexed_scope(self):
        for source_is_directory in [False, True]:
            with self.subTest(source_is_directory=source_is_directory):
                self.state = self.root / ('directory-state' if source_is_directory else 'file-state')
                first = self.transcript('gone/session.jsonl')
                second = self.transcript('retained/session.jsonl')
                selected = first.parent if source_is_directory else first
                self.record(self.scan(selected, second), candidates=[self.candidate(first)])
                first.unlink()
                if source_is_directory:
                    first.parent.rmdir()
                scan = self.scan(selected)
                self.assertEqual(scan['errors'], [])
                self.assertEqual(scan['removed'], [str(first)])
                self.record(scan)
                state = json.loads(self.state_bytes())
                self.assertNotIn(str(first), state['files'])
                self.assertIn(str(second), state['files'])
                self.assertEqual(len(self.command('pending')['candidates']), 1)

    def test_failed_or_unread_processing_does_not_advance_index(self):
        path = self.transcript()
        scan = self.scan()
        self.record(scan, processed=[])
        self.assertEqual([item['path'] for item in self.scan()['files']], [str(path)])
        before = self.state_bytes()
        self.record(self.scan(), candidates=[self.candidate(path, line=2)], fail=True)
        self.assertEqual(self.state_bytes(), before)
        self.assertEqual(len(self.scan()['files']), 1)

    def test_stale_source_rejects_the_whole_batch(self):
        first = self.transcript('a.jsonl')
        second = self.transcript('b.jsonl')
        scan = self.scan()
        second.write_text('Changed during mining.\n')
        self.assertIn('changed since scan', self.record(scan, fail=True))
        self.assertIsNone(self.state_bytes())
        self.assertEqual(len(self.scan()['files']), 2)

    def test_stale_revision_preserves_later_updates(self):
        path = self.transcript()
        first, stale = self.scan(), self.scan()
        self.record(first, candidates=[self.candidate(path)])
        before = self.state_bytes()
        self.assertIn('stale state revision', self.record(stale, fail=True))
        self.assertEqual(self.state_bytes(), before)

    def test_pending_is_durable_deduplicated_and_evidence_is_fingerprinted(self):
        path = self.transcript(text='First line.\nSecond line.')
        self.record(self.scan(), candidates=[self.candidate(path)])
        pending = self.command('pending')['candidates']
        self.assertEqual(len(pending), 1)
        self.assertEqual(len(pending[0]['evidence'][0]['sha256']), 64)
        path.write_text('First line updated.\nSecond line.')
        duplicate = self.candidate(path, text='  USE   the established integration ENTRYPOINT. ', line=2)
        self.record(self.scan(), candidates=[duplicate])
        pending = self.command('pending')['candidates']
        self.assertEqual(len(pending), 1)
        self.assertEqual(len(pending[0]['evidence']), 2)
        self.assertEqual(self.scan()['files'], [])

    def test_resolution_is_explicit_transactional_and_suppresses_requeue(self):
        path = self.transcript()
        self.record(self.scan(), candidates=[self.candidate(path)])
        key = self.command('pending')['candidates'][0]['id']
        before = self.state_bytes()
        self.command('resolve', '--id', key, '--id', 'unknown', '--decision', 'saved', fail=True)
        self.assertEqual(self.state_bytes(), before)
        self.command('resolve', '--id', key, '--decision', 'saved')
        self.assertEqual(self.command('pending')['candidates'], [])
        path.write_text('More evidence of the same rule.\n')
        self.record(self.scan(), candidates=[self.candidate(path)])
        self.assertEqual(self.command('pending')['candidates'], [])
        state = json.loads(self.state_bytes())
        self.assertEqual(state['candidates'][key]['status'], 'saved')

    def test_personal_candidates_remain_separate_and_no_instruction_files_are_touched(self):
        path = self.transcript()
        original = b'# Existing project instructions\n'
        (self.project / 'CLAUDE.md').write_bytes(original)
        candidate = self.candidate(path, text='Prefer compact status updates.', kind='personal')
        self.record(self.scan(), candidates=[candidate])
        self.assertEqual(self.command('pending')['candidates'][0]['kind'], 'personal')
        self.assertEqual((self.project / 'CLAUDE.md').read_bytes(), original)
        self.assertFalse((self.project / 'AGENTS.md').exists())

    def test_invalid_candidate_evidence_and_raw_fields_are_rejected(self):
        path = self.transcript()
        invalid = [self.candidate(self.root / 'elsewhere.jsonl'),
                   self.candidate(path, line=True), self.candidate(path, line=0),
                   self.candidate(path, text='x' * 2001)]
        raw = self.candidate(path)
        raw['quote'] = 'Raw transcript material'
        invalid.append(raw)
        for candidate in invalid:
            with self.subTest(candidate=candidate):
                self.record(self.scan(), candidates=[candidate], fail=True)
                self.assertIsNone(self.state_bytes())

    def test_manifest_must_match_project_and_source_scope(self):
        self.transcript()
        scan = self.scan()
        scan['project'] = str(self.root)
        self.record(scan, fail=True)
        scan = self.scan()
        scan['sources'] = [str(self.project)]
        self.record(scan, fail=True)
        self.assertIsNone(self.state_bytes())

    def test_scan_is_bounded_skips_worker_logs_and_reports_missing_sources(self):
        self.transcript('a.jsonl')
        self.transcript('b.jsonl')
        self.transcript('subagents/worker.jsonl')
        self.transcript('compaction/summary.jsonl')
        scan = self.scan(self.source, self.root / 'missing', limit=1)
        self.assertEqual(len(scan['files']), 1)
        self.assertEqual(scan['remaining'], 1)
        self.assertEqual(scan['skipped'], 2)
        self.assertEqual(len(scan['errors']), 1)
        self.assertFalse(self.state.exists())

    def test_scan_does_not_follow_transcript_symlinks_outside_scope(self):
        outside = self.root / 'outside.jsonl'
        outside.write_text('Unrelated transcript.\n')
        (self.source / 'linked.jsonl').symlink_to(outside)
        self.assertEqual(self.scan()['files'], [])
        self.assertEqual(self.scan()['skipped'], 1)

    def test_state_is_private_and_cannot_be_placed_in_project(self):
        self.transcript()
        self.record(self.scan())
        self.assertEqual(self.state.stat().st_mode & 0o777, 0o700)
        self.assertEqual((self.state / 'state.json').stat().st_mode & 0o777, 0o600)
        for target in [self.project, self.project / '.state', self.root / 'AGENTS.md']:
            result = subprocess.run([sys.executable, str(HELPER), '--project', str(self.project),
                                     '--state-dir', str(target), 'pending'],
                                    stdin=subprocess.DEVNULL, capture_output=True, text=True)
            self.assertNotEqual(result.returncode, 0)

    def test_default_state_is_project_specific_and_pending_is_read_only(self):
        env = {**os.environ, 'XDG_STATE_HOME': str(self.root / 'xdg')}
        result = subprocess.run([sys.executable, str(HELPER), '--project', str(self.project), 'pending'],
                                env=env, stdin=subprocess.DEVNULL, capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(json.loads(result.stdout)['candidates'], [])
        self.assertFalse((self.root / 'xdg').exists())

    def test_concurrent_recorders_preserve_one_result_and_reject_stale_writer(self):
        path = self.transcript()
        scan = self.scan()
        manifest = self.payload('manifest.json', scan)
        result = self.payload('result.json', {'processed': [str(path)], 'candidates': [self.candidate(path)]})
        args = self.argv('record', '--manifest', manifest, '--result', result)
        processes = [subprocess.Popen(args, stdin=subprocess.DEVNULL, stdout=subprocess.PIPE,
                                      stderr=subprocess.PIPE, text=True) for _ in range(2)]
        for process in processes:
            process.communicate(timeout=5)
        self.assertEqual(sorted(process.returncode for process in processes), [0, 1])
        self.assertEqual(len(self.command('pending')['candidates']), 1)
        self.assertEqual(self.scan()['files'], [])

    def test_concurrent_resolutions_preserve_both_changes(self):
        path = self.transcript()
        self.record(self.scan(), candidates=[self.candidate(path, text='Use entrypoint A.'),
                                             self.candidate(path, text='Use entrypoint B.')])
        keys = [item['id'] for item in self.command('pending')['candidates']]
        processes = [subprocess.Popen(self.argv('resolve', '--id', key, '--decision', 'dismissed'),
                                      stdin=subprocess.DEVNULL, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                                      text=True) for key in keys]
        for process in processes:
            _, error = process.communicate(timeout=5)
            self.assertEqual(process.returncode, 0, error)
        self.assertEqual(self.command('pending')['candidates'], [])


if __name__ == '__main__':
    unittest.main()

#!/usr/bin/env python3
"""Normalise human activity from agent transcripts, input history and read-only caches."""
import argparse, collections, datetime as dt, glob, json, os, re, sqlite3
from pathlib import Path
from contextlib import closing

p = argparse.ArgumentParser()
p.add_argument('--config', required=True)
p.add_argument('--out', required=True)
p.add_argument('--hermes', action='append', default=[])
p.add_argument('--home', default=os.path.expanduser('~'))
p.add_argument('--codex-home')
a = p.parse_args()
cfg = json.load(open(a.config))
HOME = a.home
CODEX_HOME = Path(a.codex_home or os.environ.get('CODEX_HOME', f'{HOME}/.codex'))
TZ = dt.timedelta(hours=cfg.get('tz_offset_hours', 0))
UTC = dt.timezone.utc
W0 = (dt.datetime.fromisoformat(cfg['period']['from']) - TZ).replace(tzinfo=UTC)
W1 = (dt.datetime.fromisoformat(cfg['period']['to']) + dt.timedelta(days=1) - TZ).replace(tzinfo=UTC)
AUTO = tuple(cfg.get('auto_prefixes', [])) + (
    'Chat from', '<task-notification', '<codex_internal_context', '↻ Automatic capacity retry',
    'This session is being continued from a previous conversation', 'Base directory for this skill:',
    '[Earlier usage-limit', '[Your previous response', '<realtime_delegation>', '<skill>',
)
AGENT_RX = {k: re.compile(v['agent'], re.I) for k, v in cfg['projects'].items() if v.get('agent')}
coverage = {'period': cfg['period'], 'sources': {}, 'codex': {}, 'warnings': []}


def instant(value, millis=False):
    try:
        if isinstance(value, (int, float)):
            return dt.datetime.fromtimestamp(value / (1000 if millis else 1), UTC)
        when = dt.datetime.fromisoformat(value.replace('Z', '+00:00'))
        return when.replace(tzinfo=UTC) if when.tzinfo is None else when.astimezone(UTC)
    except (TypeError, ValueError, OverflowError, OSError, AttributeError):
        return None


def in_window(value):
    when = value if isinstance(value, dt.datetime) else instant(value)
    return when is not None and W0 <= when < W1


def iso(when):
    return when.astimezone(UTC).isoformat().replace('+00:00', 'Z')


def auto(txt):
    return not txt or txt.lstrip().startswith(AUTO)


def text_of(content):
    if isinstance(content, str):
        return content
    if isinstance(content, list):
        text = ' '.join(c['text'] for c in content if isinstance(c, dict)
                        and c.get('type') in ('text', 'input_text') and isinstance(c.get('text'), str))
        if not text and any(c.get('type') in ('image', 'input_image', 'localImage')
                            for c in content if isinstance(c, dict)):
            return '[User attached an image]'
        return text
    return ''


def human_text(txt):
    text = text_of(txt).strip()
    had_image = bool(re.search(r'<image\b|\[Image #\d+\]', text))
    text = re.sub(r'<image\b[^>]*>.*?</image>', '', text, flags=re.S)
    text = re.sub(r'\[Image #\d+\]', '', text).strip()
    text = re.sub(r'\[(\$[\w-]+)\]\([^)]*\)', r'\1', text)
    if not text and had_image:
        text = '[User attached an image]'
    if text.startswith('<send_user_message_question_reply>'):
        body = text[len('<send_user_message_question_reply>'):].split('</send_user_message_question_reply>', 1)[0]
        try:
            replies = json.loads(body)
            if isinstance(replies, dict):
                replies = replies.get('answers', [])
            text = '\n'.join(str(r['answer']) for r in replies if isinstance(r, dict) and 'answer' in r)
        except (TypeError, ValueError):
            return ''
    if text.startswith(('<command-name>', '<command-message>')):
        name = re.search(r'<command-name>(.*?)</command-name>', text, re.S)
        args = re.search(r'<command-args>(.*?)</command-args>', text, re.S)
        text = ' '.join(x.group(1) for x in (name, args) if x).strip()
    return '' if auto(text) else text


def hits(txt):
    return {k: len(r.findall(txt)) for k, r in AGENT_RX.items() if r.search(txt)}


def records(path, windowed=False):
    try:
        with open(path, errors='ignore') as f:
            for line in f:
                if windowed:
                    match = re.search(r'"timestamp"\s*:\s*"([^"]+)"', line[:600])
                    if match and not in_window(match.group(1)):
                        continue
                try:
                    record = json.loads(line)
                    if isinstance(record, dict):
                        yield record
                except (ValueError, TypeError):
                    continue
    except OSError:
        coverage['warnings'].append(f'Unable to read {Path(path).name}')


def session(tool, sid, cwd=None):
    return dict(tool=tool, id=sid, cwd=cwd, entry='human', branches=[], prompts=[], bhits=[], _inputs=[])


def add_prompt(s, value, txt, source, event_id=None):
    when = value if isinstance(value, dt.datetime) else instant(value)
    text = human_text(txt)
    if not in_window(when) or not text:
        return
    s['_inputs'].append((when, text, source, event_id))
    info = coverage['sources'].setdefault(source, {'records': 0, 'first': iso(when), 'last': iso(when), 'weeks': {}})
    info['records'] += 1
    info['first'], info['last'] = min(info['first'], iso(when)), max(info['last'], iso(when))
    local = when + TZ
    week = f'{local.isocalendar().year}-W{local.isocalendar().week:02d}'
    info['weeks'][week] = info['weeks'].get(week, 0) + 1


def finish(s):
    ranks = {'claude-history': 0, 'codex-history': 0, 'claude': 1, 'codex-rollout': 1,
             'codex-event': 2, 'codex-cache': 3}
    groups, by_text, by_id = [], collections.defaultdict(list), {}
    for when, text, source, event_id in sorted(s.pop('_inputs'), key=lambda x: (ranks.get(x[2], 1), x[0])):
        signature = ' '.join(text.split())
        group = by_id.get(event_id) if event_id else None
        if group is None:
            candidates = [g for g in by_text[signature] if
                          (g['when'] == when or source not in g['sources'])
                          and abs((g['when'] - when).total_seconds()) <= 60]
            if candidates:
                group = min(candidates, key=lambda g: abs((g['when'] - when).total_seconds()))
        if group is None:
            group = dict(when=when, text=text, sources=set())
            groups.append(group)
            by_text[signature].append(group)
        group['sources'].add(source)
        if event_id:
            by_id[event_id] = group
    s['prompts'] = [(iso(g['when']), g['text'][:800]) for g in sorted(groups, key=lambda g: g['when'])]
    s['sources'] = sorted({source for g in groups for source in g['sources']})
    s['branches'] = sorted(set(s['branches']))
    return s


def claude():
    sessions, transcripts = {}, set()
    for path in glob.glob(f'{HOME}/.claude/projects/*/*.jsonl'):
        sid = Path(path).stem
        s = sessions.setdefault(sid, session('claude', sid))
        for d in records(path, windowed=True):
            ts = d.get('timestamp')
            if not in_window(ts) or d.get('isSidechain') or d.get('type') not in ('user', 'assistant'):
                continue
            s['cwd'] = s['cwd'] or d.get('cwd')
            if d.get('gitBranch'):
                s['branches'].append(d['gitBranch'])
            transcripts.add(sid)
            if d['type'] == 'assistant':
                h = hits(json.dumps(d.get('message', {}).get('content', ''), ensure_ascii=False))
                if h:
                    s['bhits'].append((iso(instant(ts)), h))
                continue
            if d.get('isCompactSummary') or d.get('isMeta'):
                continue
            if d.get('turnOrigin') in ('peer', 'scheduled', 'task_notification', 'sdk', 'auto_continuation', 'subagent'):
                continue
            if d.get('promptSource') in ('system', 'sdk'):
                continue
            add_prompt(s, ts, d.get('message', {}).get('content'), 'claude', d.get('uuid'))
    for n, d in enumerate(records(f'{HOME}/.claude/history.jsonl')):
        ts = instant(d.get('timestamp'), millis=True)
        if not in_window(ts):
            continue
        sid = d.get('sessionId') or f'history-{n}'
        s = sessions.setdefault(sid, session('claude-history', sid, d.get('project')))
        s['cwd'] = s['cwd'] or d.get('project')
        text = d.get('display') or ''
        for v in (d.get('pastedContents') or {}).values():
            if isinstance(v, dict) and v.get('content'):
                text += ' ' + v['content']
        add_prompt(s, ts, text, 'claude-history')
    for sid, s in sessions.items():
        if sid not in transcripts:
            s['content_routed'] = True
        if s['_inputs'] or s['bhits']:
            yield finish(s)


def latest_db(pattern):
    paths = [path for path in CODEX_HOME.glob(pattern) if re.search(r'_(\d+)\.sqlite$', path.name)]
    return max(paths, key=lambda x: int(re.search(r'_(\d+)\.sqlite$', x.name).group(1))) if paths else None


def readonly(path):
    return sqlite3.connect(Path(path).resolve().as_uri() + '?mode=ro', uri=True)


def human_thread(meta):
    source = meta.get('source')
    if isinstance(source, dict) or source in ('exec', 'subagent') or (isinstance(source, str) and source.startswith('{')):
        return False
    if meta.get('originator') == 'codex_exec' or meta.get('attached_thread_parent_id'):
        return False
    return source in (None, 'vscode', 'cli', 'app') and meta.get('thread_source') in (None, 'user', 'voice_chat')


def thread_index():
    path = latest_db('state_*.sqlite')
    if path is None:
        return {}
    wanted = ('id', 'cwd', 'rollout_path', 'git_branch', 'source', 'thread_source', 'originator',
              'attached_thread_parent_id', 'created_at', 'updated_at')
    try:
        with closing(readonly(path)) as db:
            columns = {r[1] for r in db.execute('pragma table_info(threads)')}
            selected = [c for c in wanted if c in columns]
            if 'id' not in selected:
                raise ValueError('No thread identity column')
            return {r[0]: dict(zip(selected, r)) for r in db.execute('select ' + ','.join(selected) + ' from threads')}
    except (sqlite3.Error, OSError, ValueError):
        coverage['warnings'].append('Codex thread index unavailable; history without verified session identity is not attributed')
        return {}


def codex():
    metadata, sessions, active = thread_index(), {}, set()

    def get(sid):
        meta = metadata[sid]
        s = sessions.setdefault(sid, session('codex', sid, meta.get('cwd')))
        s['cwd'] = s['cwd'] or meta.get('cwd')
        branch = meta.get('git_branch') or (meta.get('git') or {}).get('branch')
        if branch:
            s['branches'].append(branch)
        return s

    paths = glob.glob(str(CODEX_HOME / 'sessions/*/*/*/*.jsonl'))
    paths += glob.glob(str(CODEX_HOME / 'archived_sessions/**/*.jsonl'), recursive=True)
    for path in paths:
        try:
            with open(path, errors='ignore') as f:
                first = json.loads(f.readline())
            if first.get('type') != 'session_meta':
                continue
            meta = first['payload']
        except (OSError, ValueError, KeyError):
            continue
        sid = meta.get('id') or meta.get('session_id') or Path(path).stem
        merged = dict(metadata.get(sid, {}))
        merged.update({k: v for k, v in meta.items() if v is not None})
        metadata[sid] = merged
        if not human_thread(merged):
            continue
        s = get(sid)
        for d in records(path, windowed=True):
            ts, pl = d.get('timestamp'), d.get('payload') or {}
            if not in_window(ts):
                continue
            if d.get('isCompactSummary') or pl.get('isCompactSummary') or pl.get('isMeta'):
                continue
            if pl.get('type') == 'user_message':
                add_prompt(s, ts, pl.get('message'), 'codex-event', pl.get('id'))
            elif pl.get('type') == 'message' and pl.get('role') == 'user':
                add_prompt(s, ts, pl.get('content'), 'codex-rollout', pl.get('id'))
            elif pl.get('role') == 'assistant' or pl.get('type') in ('function_call', 'custom_tool_call'):
                h = hits(json.dumps(pl, ensure_ascii=False))
                if h:
                    s['bhits'].append((iso(instant(ts)), h))
        if s['_inputs']:
            active.add(sid)
    unknown = 0
    for d in records(CODEX_HOME / 'history.jsonl'):
        ts, sid = instant(d.get('ts')), d.get('session_id')
        if not in_window(ts):
            continue
        meta = metadata.get(sid)
        if meta is None:
            unknown += 1
            continue
        if human_thread(meta):
            add_prompt(get(sid), ts, d.get('text'), 'codex-history')
            active.add(sid)
    for sid, meta in metadata.items():
        created, updated = instant(meta.get('created_at')), instant(meta.get('updated_at'))
        if human_thread(meta) and (created is None or updated is None or (created < W1 and updated >= W0)):
            active.add(sid)
    eligible = [sid for sid in active if human_thread(metadata[sid])]
    missing = sum(bool(metadata[sid].get('rollout_path')) and not Path(metadata[sid]['rollout_path']).is_file()
                  for sid in eligible)
    coverage['codex'].update(eligible_threads=len(eligible), missing_rollout_files=missing,
                             unmapped_history_records=unknown)
    cache = latest_db('thread_history_*.sqlite')
    if cache is not None:
        try:
            with closing(readonly(cache)) as db:
                columns = {r[1] for r in db.execute('pragma table_info(thread_items)')}
                if not {'thread_id', 'created_at_ms', 'item_json'} <= columns:
                    raise ValueError('Unsupported cached message schema')
                typed = " and item_type='userMessage'" if 'item_type' in columns else ''
                query = ('select created_at_ms,item_json from thread_items where thread_id=?'
                         + typed + ' and created_at_ms>=? and created_at_ms<?')
                for sid in eligible:
                    for ts, raw in db.execute(query, (sid, int(W0.timestamp() * 1000), int(W1.timestamp() * 1000))):
                        try:
                            item = json.loads(raw)
                        except (ValueError, TypeError):
                            continue
                        if item.get('type') != 'userMessage':
                            continue
                        add_prompt(get(sid), instant(ts, millis=True), item.get('content'), 'codex-cache', item.get('id'))
        except (sqlite3.Error, OSError, ValueError):
            coverage['warnings'].append('Codex cached user messages unavailable; remaining history coverage may be partial')
    for s in sessions.values():
        if s['_inputs'] or s['bhits']:
            yield finish(s)


def cursor():
    path = Path(HOME) / 'Library/Application Support/Cursor/User/globalStorage/state.vscdb'
    if not path.exists():
        path = Path(HOME) / '.config/Cursor/User/globalStorage/state.vscdb'
    if not path.exists():
        return
    with closing(readonly(path)) as db:
        for key, val in db.execute("select key,value from cursorDiskKV where key>='composerData:' and key<'composerData;'"):
            try:
                c = json.loads(val)
            except (TypeError, ValueError):
                continue
            if (c.get('lastUpdatedAt') or c.get('createdAt') or 0) < W0.timestamp() * 1000:
                continue
            sid = key.split(':', 1)[1]
            s = session('cursor', sid)
            repos = collections.Counter()
            for _, raw in db.execute("select key,value from cursorDiskKV where key>=? and key<?",
                                     (f'bubbleId:{sid}:', f'bubbleId:{sid};')):
                if raw is None:
                    continue
                text = raw if isinstance(raw, str) else raw.decode('utf8', 'ignore')
                repos.update(re.findall(re.escape(HOME) + r'/[^/\s"]+/([A-Za-z0-9._-]+)', text[:100000]))
                try:
                    d = json.loads(raw)
                except (TypeError, ValueError):
                    continue
                if d.get('type') != 1 or d.get('isSimulatedMsg'):
                    continue
                add_prompt(s, d.get('createdAt'), d.get('text') or text_of(d.get('images')), 'cursor')
            if repos:
                s['cwd'] = str(Path(HOME) / 'www' / repos.most_common(1)[0][0])
            if s['_inputs']:
                first = min(s['_inputs'], key=lambda x: x[0])[1]
                if first.startswith(('Act as ', 'Run exhaustive ', 'Review the latest commit ', 'You are one reviewer')):
                    continue
                yield finish(s)


def hermes():
    for path in a.hermes:
        d = json.load(open(path))
        s = session('hermes', Path(path).name, cfg.get('hermes_cwd', 'hermes'))
        s['content_routed'] = True
        for ts, text in d['prompts']:
            add_prompt(s, ts, text, 'hermes')
        if s['_inputs']:
            yield finish(s)


counts = collections.Counter()
with open(a.out, 'w') as out:
    for gen in (claude(), codex(), cursor(), hermes()):
        for s in gen:
            counts[s['tool']] += len(s['prompts'])
            out.write(json.dumps(s, ensure_ascii=False) + '\n')
for tool, count in sorted(counts.items()):
    print(f'{tool:15s} human prompts={count}')
coverage['normalized_prompts'] = dict(counts)
coverage['total_prompts'] = sum(counts.values())
Path(a.out + '.coverage.json').write_text(json.dumps(coverage, ensure_ascii=False, indent=2) + '\n')

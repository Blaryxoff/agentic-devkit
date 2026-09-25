#!/usr/bin/env python3
"""Normalise local agent logs into one sessions.jsonl.

Sources: Claude Code transcripts + ~/.claude/history.jsonl, Codex rollouts, Cursor IDE composers,
optional Hermes/Telegram-bot dumps (see hermes_dump.py). Stdlib only.

Usage: extract_sessions.py --config timesheet.json --out sessions.jsonl [--hermes dump.json ...]
"""
import argparse, collections, datetime as dt, glob, json, os, re, sqlite3

p = argparse.ArgumentParser()
p.add_argument('--config', required=True)
p.add_argument('--out', required=True)
p.add_argument('--hermes', action='append', default=[], help='JSON produced by hermes_dump.py; repeatable')
a = p.parse_args()
cfg = json.load(open(a.config))
TZ = dt.timedelta(hours=cfg.get('tz_offset_hours', 0))
START = (dt.datetime.fromisoformat(cfg['period']['from']) - TZ).strftime('%Y-%m-%dT%H')
END = (dt.datetime.fromisoformat(cfg['period']['to']) + dt.timedelta(days=1) - TZ).strftime('%Y-%m-%dT%H')
AUTO = tuple(cfg.get('auto_prefixes', []))
AGENT_RX = {k: re.compile(v['agent'], re.I) for k, v in cfg['projects'].items() if v.get('agent')}
HOME = os.path.expanduser('~')


def in_window(ts):
    return ts and START <= ts < END


def auto(txt):
    s = (txt or '').lstrip()
    return not s or s.startswith(AUTO)


def text_of(content):
    if isinstance(content, str):
        return content
    if isinstance(content, list):
        return ' '.join(c.get('text', '') for c in content if isinstance(c, dict) and c.get('type') in ('text', 'input_text'))
    return ''


def hits(txt):
    return {k: len(r.findall(txt)) for k, r in AGENT_RX.items() if r.search(txt)}


def ts_of(line):
    m = re.search(r'"timestamp":"([0-9T:\-\.]+Z)"', line[:600])
    return m.group(1) if m else None


def session(tool, sid, cwd, entry):
    return dict(tool=tool, id=sid, cwd=cwd, entry=entry, branches=[], prompts=[], bhits=[])


def claude():
    seen = set()
    for f in glob.glob(f'{HOME}/.claude/projects/*/*.jsonl'):
        sid = os.path.basename(f)[:-6]
        s = session('claude', sid, None, 'human')
        br = set()
        for line in open(f, errors='ignore'):
            ts = ts_of(line)
            if not in_window(ts):
                continue
            try:
                d = json.loads(line)
            except ValueError:
                continue
            if d.get('isSidechain') or d.get('type') not in ('user', 'assistant'):
                continue
            s['cwd'] = s['cwd'] or d.get('cwd')
            if d.get('gitBranch'):
                br.add(d['gitBranch'])
            if d['type'] == 'assistant':
                h = hits(json.dumps(d.get('message', {}).get('content', ''), ensure_ascii=False))
                if h:
                    s['bhits'].append((ts, h))
                continue
            origin, src = d.get('turnOrigin'), d.get('promptSource')
            if origin in ('peer', 'scheduled', 'task_notification', 'sdk') or src in ('system', 'sdk'):
                continue
            if origin != 'human' and src not in ('typed', 'queued', 'suggestion_accepted'):
                continue
            txt = text_of(d.get('message', {}).get('content'))
            if not auto(txt):
                s['prompts'].append((ts, txt[:800]))
        s['branches'] = sorted(br)
        seen.add(sid)
        if s['prompts'] or s['bhits']:
            yield s
    # history.jsonl survives transcript retention (cleanupPeriodDays): typed prompts only, launch dir only
    hist = collections.defaultdict(list)
    proj = {}
    hp = f'{HOME}/.claude/history.jsonl'
    for line in open(hp, errors='ignore') if os.path.exists(hp) else []:
        try:
            d = json.loads(line)
        except ValueError:
            continue
        sid = d.get('sessionId') or 'nosid'
        if not d.get('timestamp') or sid in seen:
            continue
        ts = dt.datetime.fromtimestamp(d['timestamp'] / 1000, dt.timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ')
        txt = d.get('display') or ''
        for v in (d.get('pastedContents') or {}).values():
            if isinstance(v, dict) and v.get('content'):
                txt += ' ' + v['content'][:300]
        if in_window(ts) and not auto(txt):
            hist[sid].append((ts, txt[:800]))
            proj[sid] = d.get('project')
    for sid, ps in hist.items():
        s = session('claude-history', sid, proj[sid], 'human')
        s['prompts'] = sorted(ps)
        s['content_routed'] = True  # launch dir may differ from the repo actually worked on
        yield s


def codex():
    root = os.environ.get('CODEX_HOME', f'{HOME}/.codex')
    for f in glob.glob(f'{root}/sessions/*/*/*/*.jsonl'):
        s = session('codex', os.path.basename(f), None, 'human')
        dedupe = set()
        for line in open(f, errors='ignore'):
            ts = ts_of(line)
            if not ts:
                continue
            head = line[:400]
            if '"session_meta"' in head:
                try:
                    m = json.loads(line)['payload']
                except (ValueError, KeyError):
                    continue
                s['cwd'] = m.get('cwd')
                s['entry'] = 'exec' if m.get('originator') == 'codex_exec' else 'human'
                if (m.get('git') or {}).get('branch'):
                    s['branches'] = [m['git']['branch']]
                continue
            if not in_window(ts):
                continue
            is_user = '"user_message"' in head or ('"role":"user"' in head and '"type":"message"' in head)
            is_agent = any(k in head for k in ('"function_call"', '"custom_tool_call"', '"role":"assistant"'))
            if not (is_user or is_agent):
                continue
            try:
                pl = json.loads(line).get('payload', {})
            except ValueError:
                continue
            if is_agent:
                h = hits(json.dumps(pl, ensure_ascii=False))
                if h:
                    s['bhits'].append((ts, h))
                continue
            txt = pl.get('message') if pl.get('type') == 'user_message' else text_of(pl.get('content'))
            if isinstance(txt, str) and not auto(txt) and txt[:200] not in dedupe:
                dedupe.add(txt[:200])
                s['prompts'].append((ts, txt[:800]))
        if s['prompts'] or s['bhits']:
            yield s


def cursor():
    db_path = f'{HOME}/Library/Application Support/Cursor/User/globalStorage/state.vscdb'
    if not os.path.exists(db_path):
        db_path = f'{HOME}/.config/Cursor/User/globalStorage/state.vscdb'
    if not os.path.exists(db_path):
        return
    db = sqlite3.connect(f'file:{db_path}?immutable=1', uri=True)  # multi-GB, never copy; key-range queries only
    lo = int(dt.datetime.fromisoformat(START + ':00+00:00').timestamp() * 1000)
    repo_rx = re.compile(re.escape(HOME) + r'/[^/\s"]+/([A-Za-z0-9._-]+)')
    for key, val in db.execute("select key, value from cursorDiskKV where key >= 'composerData:' and key < 'composerData;'"):
        try:
            c = json.loads(val)
        except (TypeError, ValueError):
            continue
        if (c.get('lastUpdatedAt') or c.get('createdAt') or 0) < lo:
            continue
        cid = key.split(':', 1)[1]
        repos = collections.Counter(repo_rx.findall(val if isinstance(val, str) else ''))
        s = session('cursor', cid, None, 'human')
        for _, b in db.execute("select key, value from cursorDiskKV where key >= ? and key < ?", (f'bubbleId:{cid}:', f'bubbleId:{cid};')):
            if b is None:
                continue
            b = b if isinstance(b, str) else b.decode('utf8', 'ignore')
            repos.update(repo_rx.findall(b[:100000]))
            if '"type":1' not in b[:3000]:
                continue
            try:
                d = json.loads(b)
            except ValueError:
                continue
            if d.get('type') == 1 and d.get('createdAt') and in_window(d['createdAt']):
                s['prompts'].append((d['createdAt'][:19] + 'Z', (d.get('text') or '')[:800]))
        s['prompts'].sort()
        if s['prompts'] and auto(s['prompts'][0][1]):
            continue  # a composer opened by machine text is a subagent chat, not the person
        s['prompts'] = [p for p in s['prompts'] if not auto(p[1])]
        if repos:
            s['cwd'] = f'{HOME}/www/{repos.most_common(1)[0][0]}'
        if s['prompts']:
            yield s


def hermes():
    for f in a.hermes:
        d = json.load(open(f))
        s = session('hermes', os.path.basename(f), cfg.get('hermes_cwd', 'hermes'), 'human')
        s['content_routed'] = True
        s['prompts'] = [(ts, txt) for ts, txt in d['prompts'] if in_window(ts) and not auto(txt)]
        if s['prompts']:
            yield s


n = collections.Counter()
with open(a.out, 'w') as o:
    for gen in (claude(), codex(), cursor(), hermes()):
        for s in gen:
            n[(s['tool'], s['entry'])] += len(s['prompts'])
            o.write(json.dumps(s, ensure_ascii=False) + '\n')
for k, v in sorted(n.items()):
    print(f'{k[0]:15s} {k[1]:6s} prompts={v}')

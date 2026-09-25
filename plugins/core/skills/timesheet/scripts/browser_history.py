#!/usr/bin/env python3
"""Extract work-site visits and video calls from Chrome/Chromium History databases (copied, never opened live).

Usage: browser_history.py --config timesheet.json --out-visits visits.json --out-calls calls.json
Visits: [iso_ts, project] for URLs matching config.browser.domains_regex (label by config.browser.project_rules).
Calls:  one row per (day, room) with start/end/minutes, from Telemost/Zoom/Meet/Jitsi/ghostflow voice-room URLs.
visit_duration is tab-focus time: a forgotten tab inflates it, so calls are capped by first..last visit span.
"""
import argparse, collections, datetime as dt, glob, json, os, re, shutil, sqlite3, tempfile

p = argparse.ArgumentParser()
p.add_argument('--config', required=True)
p.add_argument('--out-visits', required=True)
p.add_argument('--out-calls', required=True)
a = p.parse_args()
cfg = json.load(open(a.config))
b = cfg.get('browser', {})
TZ = dt.timedelta(hours=cfg.get('tz_offset_hours', 0))
EPOCH = dt.datetime(1601, 1, 1)
lo = dt.datetime.fromisoformat(cfg['period']['from']) - TZ
hi = dt.datetime.fromisoformat(cfg['period']['to']) + dt.timedelta(days=1) - TZ
DOM = re.compile(b.get('domains_regex', r'$^'), re.I)
EXC = re.compile(b.get('exclude_regex', r'$^'), re.I)
RULES = [(re.compile(rx, re.I), proj) for rx, proj in b.get('project_rules', [])]
CALL = re.compile(r'telemost[^/]*/j/(\d+)|voice-rooms/(\d+)|zoom\.us/j/(\d+)|meet\.google\.com/([a-z-]{8,})|meet\.jit\.si/([^/?#]+)', re.I)
KIND = ['telemost', 'ghostflow', 'zoom', 'meet', 'jitsi']

patterns = b.get('history_globs', [
    '~/Library/Application Support/Google/Chrome/*/History',
    '~/Library/Application Support/Chromium/*/History',
    '~/.config/google-chrome/*/History',
])
files = [f for pat in patterns for f in glob.glob(os.path.expanduser(pat))]
visits, calls_raw = [], []
for f in files:
    tmp = tempfile.mktemp(suffix='.db')
    shutil.copy(f, tmp)  # the live file is locked while the browser runs
    db = sqlite3.connect(tmp)
    q = """select v.visit_time, v.visit_duration, u.url, u.title from visits v join urls u on u.id = v.url
           where v.visit_time between ? and ? order by v.visit_time"""
    rng = (int((lo - EPOCH).total_seconds() * 1e6), int((hi - EPOCH).total_seconds() * 1e6))
    for t, dur, url, title in db.execute(q, rng):
        when = EPOCH + dt.timedelta(microseconds=t)
        m = CALL.search(url)
        if m and dur and dur > 20e6:
            idx = next(i for i, g in enumerate(m.groups()) if g)
            calls_raw.append((when, dur / 1e6, f'{KIND[idx]}:{m.group(idx + 1)}', title or ''))
            continue
        if DOM.search(url) and not EXC.search(url + ' ' + (title or '')):
            proj = next((pj for rx, pj in RULES if rx.search(url + ' ' + (title or ''))), cfg['common_project'])
            visits.append((when.strftime('%Y-%m-%dT%H:%M:%SZ'), proj))
    db.close()
    os.unlink(tmp)

grouped = collections.defaultdict(list)
for when, dur, room, _ in calls_raw:
    grouped[((when + TZ).date(), room)].append((when, dur))
calls = []
for (day, room), xs in sorted(grouped.items()):
    start = min(w for w, _ in xs)
    end = max(w + dt.timedelta(seconds=d) for w, d in xs)
    minutes = round(min(sum(d for _, d in xs), (end - start).total_seconds()) / 60)
    if minutes >= 5:
        calls.append(dict(room=room, start=(start + TZ).isoformat(timespec='minutes'), minutes=minutes))
json.dump(sorted(visits), open(a.out_visits, 'w'))
json.dump(calls, open(a.out_calls, 'w'), ensure_ascii=False, indent=1)
print(f'profiles={len(files)} visits={len(visits)} calls={len(calls)} ({round(sum(c["minutes"] for c in calls) / 60, 1)} h)')
for c in calls:
    print(f"  {c['start']}  {c['minutes']:4d}m  {c['room']}")

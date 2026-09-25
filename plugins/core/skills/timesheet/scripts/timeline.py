#!/usr/bin/env python3
"""Reconstruct human working time per project/task from normalised activity (stdlib only).

Model (see references/method.md):
- anchors are the person's own prompts/messages; a prompt covers the time until the next prompt of the same session
  when the gap is <= gap_minutes, otherwise tail_minutes;
- before transcript_cutoff (transcripts expired) commit times and exec-session starts are added as low-confidence anchors;
- browser visits to work sites are anchors with a stricter gap/tail; calls override the whole minute;
- one global minute timeline: parallel sessions never add wall-clock time; a minute is split between the labels
  active in it ('union' ignores other clients, 'split' shares the minute with them).

Usage:
  timeline.py --config timesheet.json --sessions sessions.jsonl --out out/ \
      [--commits repo=commits.txt ...] [--visits visits.json] [--calls calls.json] [--gap 30 --tail 15]
commits.txt is `git log --all --since ... --author ... --name-only --format='@@%H|%aI|%s'`.
"""
import argparse, collections, datetime as dt, json, os, re

p = argparse.ArgumentParser()
p.add_argument('--config', required=True)
p.add_argument('--sessions', required=True)
p.add_argument('--out', required=True)
p.add_argument('--commits', action='append', default=[])
p.add_argument('--visits')
p.add_argument('--calls')
p.add_argument('--gap', type=int)
p.add_argument('--tail', type=int)
a = p.parse_args()
cfg = json.load(open(a.config))
os.makedirs(a.out, exist_ok=True)
GAP = a.gap or cfg.get('gap_minutes', 30)
TAIL = a.tail or cfg.get('tail_minutes', 15)
TZ = dt.timedelta(hours=cfg.get('tz_offset_hours', 0))
CUTOFF = dt.date.fromisoformat(cfg['transcript_cutoff']) if cfg.get('transcript_cutoff') else dt.date.min
W0 = dt.datetime.fromisoformat(cfg['period']['from'])
W1 = dt.datetime.fromisoformat(cfg['period']['to']) + dt.timedelta(days=1)
MODE = cfg.get('parallel_other_clients', 'union')
COMMON, DEVOPS = cfg['common_project'], cfg.get('devops_project')
CALL = cfg.get('calls_project', 'Calls')
rx = lambda s: re.compile(s, re.I) if s else None
TARGET = rx(cfg['target_repo_rx'])
OUTSIDE_REPOS = rx(cfg.get('outside_repo_rx'))
TARGET_MENTION = rx(cfg.get('target_mention_rx'))
OTHER_CLIENT = rx(cfg.get('other_client_rx'))
DEVOPS_WEAK = rx(cfg.get('devops_weak_rx'))
PROMPT_RX = {k: rx(v['prompt']) for k, v in cfg['projects'].items() if v.get('prompt')}
PATH_RX = {k: rx(v['path']) for k, v in cfg['projects'].items() if v.get('path')}
AGENT_W = {k: v.get('agent_weight', 1) for k, v in cfg['projects'].items()}
TASKS = [(rx(t['re']), t.get('project'), t['name']) for t in cfg.get('tasks', [])]
GENERIC = set(cfg.get('generic_tasks', []))
REROUTE = [(rx(r['re']), r.get('project'), r.get('task'), r.get('drop', False)) for r in cfg.get('reroute', [])]
SKIP_PREFIX = tuple(cfg.get('auto_prefixes', []))
EXEC_SKIP = tuple(cfg.get('exec_skip_prefixes', []))


def minute(ts):
    d = dt.datetime.fromisoformat(ts.replace('Z', '+00:00'))
    if d.tzinfo:
        d = d.astimezone(dt.timezone.utc).replace(tzinfo=None)
    return (d + TZ).replace(second=0, microsecond=0)


def score(txt, w=1.0, out=None):
    out = out if out is not None else collections.Counter()
    for k, r in PROMPT_RX.items():
        n = len(r.findall(txt))
        if n:
            out[k] += n * w
    if DEVOPS and DEVOPS_WEAK:
        n = len(DEVOPS_WEAK.findall(txt))
        if n:
            out[DEVOPS] += n * w * 0.4
    return out


def find_task(txt):
    return next(((proj, name) for r, proj, name in TASKS if r.search(txt)), None)


def repo_kind(cwd):
    cwd = cwd or ''
    if TARGET.search(cwd):
        return 'target'
    if cwd and '/' not in cwd:
        return cwd  # synthetic sources such as bot dumps name themselves
    m = re.search(r'/(?:www|src|code|projects)/([^/]+)', cwd)
    return m.group(1) if m else 'other'


sessions = [json.loads(l) for l in open(a.sessions)]
anchors = []  # (minute, key, label, conf, text, task)
covered_days = collections.defaultdict(set)
for i, s in enumerate(sessions):
    kind = repo_kind(s.get('cwd'))
    if s.get('content_routed') and kind == 'target' and OTHER_CLIENT:
        o = sum(1 for _, t in s['prompts'] if OTHER_CLIENT.search(t))
        g = sum(1 for _, t in s['prompts'] if TARGET_MENTION and TARGET_MENTION.search(t))
        if o > g:
            kind = 'other-client'
    if s['entry'] != 'human':
        continue
    hint_str = (s.get('cwd') or '') + ' ' + ' '.join(s.get('branches', []))
    hint = collections.Counter({k: 3 for k, r in PATH_RX.items() if r.search(hint_str)})
    bh = [(minute(t), h) for t, h in s.get('bhits', [])]
    prompts = sorted((minute(t), txt) for t, txt in s['prompts'] if not txt.lstrip().startswith(SKIP_PREFIX))
    sess = collections.Counter(hint)
    for _, txt in prompts:
        score(txt, 5, sess)
    for _, h in bh:
        for k, n in h.items():
            sess[k] += n * AGENT_W.get(k, 1)
    last = last_task = None
    for j, (t, txt) in enumerate(prompts):
        nxt = prompts[j + 1][0] if j + 1 < len(prompts) else t + dt.timedelta(hours=6)
        sc = score(txt, 5)
        own = sum(sc.values())
        task = find_task(txt) or find_task(hint_str) or last_task
        if task and task[1] in GENERIC and last_task and last_task[1] not in GENERIC:
            task = last_task
        last_task = task
        if task and task[0] and not own:
            sc[task[0]] += 6
        for k, n in hint.items():
            sc[k] += n
        for tm, h in bh:
            if t <= tm < nxt:
                for k, n in h.items():
                    sc[k] += n * AGENT_W.get(k, 1)
        if sc and max(sc.values()) >= 2:
            lab = sc.most_common(1)[0][0]
        elif last:
            lab = last
        elif sess and max(sess.values()) >= 3:
            lab = sess.most_common(1)[0][0]
        else:
            lab = COMMON
        weak_devops = lab == DEVOPS and not (PROMPT_RX.get(DEVOPS) and PROMPT_RX[DEVOPS].search(txt))
        if not weak_devops:
            last = lab
        tname = task[1] if task else '—'
        label = ('target', lab)
        if kind != 'target':
            if OUTSIDE_REPOS and OUTSIDE_REPOS.search(kind) and TARGET_MENTION and TARGET_MENTION.search(txt):
                own_sc = score(txt, 5)
                best = own_sc.most_common(1)[0] if own_sc else (None, 0)
                if best[1] >= 2 and best[0] not in (DEVOPS, COMMON):
                    label, tname = ('target', best[0]), (task[1] if task else '—')
                else:
                    label, tname = ('target', DEVOPS or COMMON), cfg.get('outside_task', 'Infrastructure from the infra repo')
            else:
                label, tname = (kind, kind), '—'
        for r, proj, rtask, drop in REROUTE:
            if r.search(txt) and label[0] == 'target':
                label = ('dropped', 'dropped') if drop else ('target', proj or label[1])
                tname = rtask or tname
                break
        anchors.append((t, i, label, 'high', txt, tname))
        covered_days[(t.date(), kind)].add(i)

fallback = []
for spec in a.commits:
    repo, path = spec.split('=', 1)
    kind = 'target' if TARGET.search(repo) else repo
    cur = None
    for line in open(path):
        line = line.rstrip('\n')
        if line.startswith('@@'):
            sha, ts, subj = line[2:].split('|', 2)
            cur = dict(sha=sha, ts=ts, subj=subj, files=[])
            fallback.append((kind, cur))
        elif line and cur:
            cur['files'].append(line)
fb = []
for kind, c in {c['sha']: (k, c) for k, c in fallback}.values():
    t = minute(c['ts'])
    if covered_days.get((t.date(), kind)) and t.date() >= CUTOFF:
        continue
    if kind == 'target':
        sc = score(c['subj'], 5)
        for f in c['files']:
            for k, r in PATH_RX.items():
                if r.search(f):
                    sc[k] += 1
        tk = find_task(c['subj'] + ' ' + ' '.join(c['files'][:5]))
        lab = sc.most_common(1)[0][0] if sc and max(sc.values()) >= 2 else (tk[0] if tk and tk[0] else COMMON)
        fb.append((t, 'fb:' + kind, ('target', lab), 'low', c['subj'], tk[1] if tk else '—'))
    else:
        fb.append((t, 'fb:' + kind, (kind, kind), 'low', c['subj'], '—'))
for i, s in enumerate(sessions):
    if s['entry'] != 'exec':
        continue
    real = [x for x in s['prompts'] if not x[1].lstrip().startswith(EXEC_SKIP + SKIP_PREFIX)]
    if not real:
        continue
    kind = repo_kind(s.get('cwd'))
    t = minute(real[0][0])
    if covered_days.get((t.date(), kind)) and t.date() >= CUTOFF:
        continue
    tk = find_task(real[0][1][:400] + ' ' + (s.get('cwd') or '')) if kind == 'target' else None
    lab = ('target', tk[0] if tk and tk[0] else COMMON) if kind == 'target' else (kind, kind)
    fb.append((t, 'fb:' + kind, lab, 'low', real[0][1][:200], tk[1] if tk else '—'))

timeline = collections.defaultdict(list)


def cover(seq, key, gap, tail):
    seq.sort(key=lambda x: x[0])
    for j, x in enumerate(seq):
        nxt = seq[j + 1][0] if j + 1 < len(seq) else None
        g = (nxt - x[0]).total_seconds() / 60 if nxt else 10 ** 9
        for m in range(int(g if g <= gap else tail)):
            timeline[x[0] + dt.timedelta(minutes=m)].append((x[2], x[3], key, x[5]))


per = collections.defaultdict(list)
for x in anchors:
    per[x[1]].append(x)
for k, seq in per.items():
    cover(seq, k, GAP, TAIL)
per_fb = collections.defaultdict(list)
for x in fb:
    per_fb[x[1]].append(x)
for k, seq in per_fb.items():
    cover(seq, k, GAP, TAIL)
if a.visits:
    bcfg = cfg.get('browser', {})
    seq = [(minute(ts), 'browser', ('target', proj), 'browser', '', bcfg.get('task', 'Browser work on the projects'))
           for ts, proj in json.load(open(a.visits))]
    cover(seq, 'browser', bcfg.get('gap_minutes', 10), bcfg.get('tail_minutes', 5))
if a.calls:
    inc = cfg.get('calls', {}).get('include', [])
    for c in json.load(open(a.calls)):
        key = f"{c['room']}@{c['start'][:10]}"
        if not any(r in (c['room'], key) or (r.endswith('*') and c['room'].startswith(r[:-1])) for r in inc):
            continue
        st = dt.datetime.fromisoformat(c['start'])
        for m in range(c['minutes']):
            timeline[st + dt.timedelta(minutes=m)].append((('target', CALL), 'call', 'call', c['room']))

hours = collections.defaultdict(lambda: collections.defaultdict(float))
tasks = collections.defaultdict(lambda: collections.defaultdict(float))
days = collections.defaultdict(float)
low = collections.defaultdict(float)
for m, labs in timeline.items():
    if not (W0 <= m < W1):
        continue
    if any(x[0] == ('target', CALL) for x in labs):
        labs = [x for x in labs if x[0] == ('target', CALL)]
    uniq, tset = {}, collections.defaultdict(set)
    for lab, conf, _, task in labs:
        uniq.setdefault(lab, conf)
        tset[lab].add(task)
    tgt = [l for l in uniq if l[0] == 'target']
    if not tgt:
        continue
    share = 1 / (len(tgt) if MODE == 'union' else len(uniq)) / 60
    days[str(m.date())] += share * len(tgt)
    for lab in tgt:
        mon = m.strftime('%Y-%m')
        hours[lab[1]][mon] += share
        if uniq[lab] == 'low':
            low[lab[1]] += share
        for tk in tset[lab]:
            tasks[lab[1]][tk] += share / len(tset[lab])

json.dump(hours, open(f'{a.out}/hours.json', 'w'), ensure_ascii=False, indent=1)
json.dump(tasks, open(f'{a.out}/tasks.json', 'w'), ensure_ascii=False, indent=1)
json.dump(days, open(f'{a.out}/days.json', 'w'), indent=1)
json.dump([(str(x[0]), x[2][1], x[3], x[5], x[4][:300]) for x in anchors + fb if x[2][0] == 'target' and W0 <= x[0] < W1],
          open(f'{a.out}/anchors.json', 'w'), ensure_ascii=False)

total = sum(sum(v.values()) for v in hours.values())
print(f'mode={MODE} gap={GAP} tail={TAIL} total={total:.1f} h')
for proj, mv in sorted(hours.items(), key=lambda x: -sum(x[1].values())):
    months = '  '.join(f'{k}: {v:5.1f}' for k, v in sorted(mv.items()))
    print(f'  {proj:36s} {sum(mv.values()):6.1f}  [{months}]  low-confidence {low[proj]:.1f}')
print(f'unclassified ({COMMON}) share: {100 * sum(hours[COMMON].values()) / max(total, 1):.0f}%')
print('top days:', ', '.join(f'{d} {v:.1f}' for d, v in sorted(days.items(), key=lambda x: -x[1])[:8]))

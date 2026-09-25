#!/usr/bin/env python3
"""Turn timeline output into report.json: overhead factor, per-bullet hours, whole-hour rounding that reconciles.

Usage: allocate.py --config timesheet.json --in out/ --out out/report.json

Per project: task hours whose task name a bullet owns go to that bullet; the rest (generic prompts, browser time,
unowned tasks) is a pool split 50% equally across the project's bullets and 50% in proportion to their matched hours.
Rounding uses the largest-remainder method on whole hours so bullets sum to the project and months sum to the total.
"""
import argparse, datetime as dt, json, math

p = argparse.ArgumentParser()
p.add_argument('--config', required=True)
p.add_argument('--in', dest='inp', required=True)
p.add_argument('--out', required=True)
a = p.parse_args()
cfg = json.load(open(a.config))
K = cfg.get('overhead_factor', 1.0)
hours = json.load(open(f'{a.inp}/hours.json'))
tasks = json.load(open(f'{a.inp}/tasks.json'))
measured = {dt.date.fromisoformat(k): v for k, v in json.load(open(f'{a.inp}/days.json')).items()}
days = {d: v * K for d, v in measured.items()}
bullets = cfg['bullets']
order = [p for p in cfg.get('order', list(bullets)) if p in hours or p in bullets]
months = sorted({m for mv in hours.values() for m in mv})


def lr(vals, total):
    fl = [math.floor(v) for v in vals]
    for i in sorted(range(len(vals)), key=lambda i: -(vals[i] - fl[i]))[:max(0, total - sum(fl))]:
        fl[i] += 1
    return fl


per_month = {}
for m in months:
    vals = [hours.get(p, {}).get(m, 0) * K for p in order]
    per_month[m] = dict(zip(order, lr(vals, round(sum(vals)))))

projects = []
for p in order:
    total = sum(per_month[m][p] for m in months)
    bl = bullets.get(p, [[cfg.get('fallback_bullet', 'Work on the project'), []]])
    th = {k: v * K for k, v in tasks.get(p, {}).items()}
    owned = {t for _, keys in bl for t in keys}
    matched = [sum(th.get(t, 0) for t in keys) for _, keys in bl]
    pool = sum(v for t, v in th.items() if t not in owned)
    n, msum = len(bl), sum(matched)
    exact = [m + pool * 0.5 / n + (pool * 0.5 * m / msum if msum else pool * 0.5 / n) for m in matched]
    scale = total / sum(exact) if sum(exact) else 0
    hrs = lr([e * scale for e in exact], total) if total else [0] * n
    projects.append(dict(name=p, title=cfg.get('titles', {}).get(p, p), total=total,
                         months={m: per_month[m][p] for m in months}, raw=sum(hours.get(p, {}).values()) * K,
                         bullets=[[t, h] for (t, _), h in zip(bl, hrs)],
                         matched_share=round(msum / (msum + pool), 2) if msum + pool else 0))

vac = [(dt.date.fromisoformat(x), dt.date.fromisoformat(y)) for x, y in cfg.get('vacation', [])]
hol = {dt.date.fromisoformat(x) for x in cfg.get('holidays', [])}
wk = {dt.date.fromisoformat(x) for x in cfg.get('extra_workdays', [])}
d0, d1 = dt.date.fromisoformat(cfg['period']['from']), dt.date.fromisoformat(cfg['period']['to'])
cal = [d0 + dt.timedelta(days=i) for i in range((d1 - d0).days + 1)]
is_work = lambda d: (d.weekday() < 5 and d not in hol) or d in wk
on_vac = lambda d: any(x <= d <= y for x, y in vac)
calendar_days = [d for d in cal if is_work(d)]
norm_days = [d for d in calendar_days if not on_vac(d)]
min_day_minutes = round(cfg.get('min_day_hours', 0.5) * 60)
worked = [d for d, v in measured.items() if round(v * 60) >= min_day_minutes]
extra = [d for d in worked if d not in norm_days]
total = sum(x['total'] for x in projects)
hpd = cfg.get('hours_per_day', 8)
report = dict(
    person=cfg.get('person', ''), period=cfg['period'], months=months, total=total,
    month_totals={m: sum(per_month[m].values()) for m in months},
    calendar=dict(calendar_days=len(calendar_days), vacation_days=len(calendar_days) - len(norm_days),
                  norm_days=len(norm_days), norm_hours=len(norm_days) * hpd, hours_per_day=hpd,
                  worked_days=len(worked), worked_norm_days=len([d for d in norm_days if d in worked]),
                  extra_days=len(extra), extra_weekend=len([d for d in extra if not on_vac(d)]),
                  extra_vacation=len([d for d in extra if on_vac(d)]),
                  extra_hours=round(sum(days[d] for d in extra)), min_day_minutes=min_day_minutes,
                  short_off_hours=round(sum(v for d, v in days.items() if d not in norm_days and d not in extra)),
                  norm_day_hours=round(sum(days.get(d, 0) for d in norm_days)),
                  worked_by_month={m: len([d for d in norm_days if d in worked and d.strftime('%Y-%m') == m]) for m in months}),
    projects=projects, overhead_factor=K)
json.dump(report, open(a.out, 'w'), ensure_ascii=False, indent=1)
c = report['calendar']
print(f"total {total} h  months {report['month_totals']}  norm {c['norm_hours']} h / {c['norm_days']} d  "
      f"worked {c['worked_days']} d  overtime {total - c['norm_hours']:+d} h")
for x in projects:
    print(f"{x['title']} — {x['total']} ч  {x['months']}  [bullets matched {int(x['matched_share'] * 100)}%]")
    for t, h in x['bullets']:
        print(f'  • {t} — {h} ч')

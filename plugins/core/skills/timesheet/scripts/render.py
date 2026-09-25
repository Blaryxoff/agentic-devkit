#!/usr/bin/env python3
"""Render report.json into report.md, report.html and (optionally) a PDF via headless Chrome.

Usage: render.py --config timesheet.json --report out/report.json --out out/ [--pdf "/path/Report.pdf"]
Labels default to Russian; override any of them with config "labels".
"""
import argparse, html, json, os, subprocess, sys, tempfile, time

p = argparse.ArgumentParser()
p.add_argument('--config', required=True)
p.add_argument('--report', required=True)
p.add_argument('--out', required=True)
p.add_argument('--pdf')
a = p.parse_args()
cfg = json.load(open(a.config))
r = json.load(open(a.report))
MONTHS_RU = {'01': 'Январь', '02': 'Февраль', '03': 'Март', '04': 'Апрель', '05': 'Май', '06': 'Июнь', '07': 'Июль',
             '08': 'Август', '09': 'Сентябрь', '10': 'Октябрь', '11': 'Ноябрь', '12': 'Декабрь'}
L = dict(title='Отчёт по затраченному времени', norm='Норма и переработка', days='Дни', hours='Часы',
         col_norm='Норма', col_fact='Факт', col_over='Переработка', projects='Часы по проектам', project='Проект',
         total='Всего', share='Доля', grand='Итого', tasks='Задачи по проектам', method_title='Как считал.',
         h='ч', method=cfg.get('method_text', ''))
L.update(cfg.get('labels', {}))
e = html.escape
c = r['calendar']
tot, norm = r['total'], c['norm_hours']
over = tot - norm
pct_over = f'{round(100 * over / norm):+d}%' if norm else '—'
mon = [MONTHS_RU.get(m[5:], m) for m in r['months']]
short = [x[:3].lower() for x in mon]
fmt_h = lambda x: f"{x} {L['h']}" if x >= 1 else f"&lt;1 {L['h']}"
num = lambda x: str(x) if x >= 1 else '—'
share = lambda x: f'{max(1, round(100 * x / tot))}%' if tot and 100 * x / tot >= 0.5 else '&lt;1%'
period = f"{r['period']['from'][8:10]}.{r['period']['from'][5:7]}–{r['period']['to'][8:10]}.{r['period']['to'][5:7]}.{r['period']['to'][:4]}"
avg = round(c['norm_day_hours'] / max(c['norm_days'], 1))
notes = [
    f"Норма: по производственному календарю — {c['calendar_days']} рабочих дней ({c['calendar_days'] * c['hours_per_day']} {L['h']})"
    + (f", минус отпуск ({c['vacation_days']} рабочих дней)" if c['vacation_days'] else '')
    + f" = {c['norm_days']} дней × {c['hours_per_day']} {L['h']} = {norm} {L['h']}",
    f"Отработано {c['worked_norm_days']} из {c['norm_days']} рабочих дней, в среднем ~{avg} {L['h']} в день — это ~{c['norm_day_hours'] - norm} {L['h']} сверх нормы",
]
if c['extra_days']:
    parts = [f"{c['extra_weekend']} выходных"] + ([f"{c['extra_vacation']} дня отпуска"] if c['extra_vacation'] else [])
    notes.append(f"Ещё {c['extra_days']} дней работы вне графика: {' и '.join(parts)} — ~{c['extra_hours']} {L['h']}"
                 + (f"; короткие подключения в другие выходные — ~{c['short_off_hours']} {L['h']}" if c.get('short_off_hours') else ''))

rows = ''.join(
    f"<tr><td>{e(x['title'])}</td>" + ''.join(f"<td class=n>{num(x['months'][m]) if x['total'] else '&lt;1'}</td>" for m in r['months'])
    + f"<td class=n><b>{num(x['total']) if x['total'] else '&lt;1'}</b></td><td class=n>{share(x['total'])}</td></tr>"
    for x in r['projects'])
month_line = lambda x: ' / '.join(f"{s} {x['months'][m]}" for s, m in zip(short, r['months']))
sections = ''.join(
    f"<section><h3>{e(x['title'])} <span class=sub>{month_line(x)}</span>"
    f"<span class=tot>{fmt_h(x['total'])}</span></h3><table class=tasks>"
    + ''.join(f"<tr><td>{e(t)}</td><td class=n>{fmt_h(h)}</td></tr>" for t, h in x['bullets']) + '</table></section>'
    for x in r['projects'])
css = """@page { size: A4; margin: 16mm 15mm; }
body { font-family: -apple-system, 'Helvetica Neue', Arial, sans-serif; color:#1d1d1f; font-size:10.5pt; line-height:1.4; }
h1 { font-size:18pt; margin:0 0 2mm; } .meta { color:#666; margin-bottom:6mm; }
h2 { font-size:12.5pt; margin:6mm 0 2mm; border-bottom:2px solid #1d1d1f; padding-bottom:1mm; }
h2.newpage { break-before:page; margin-top:0; }
table { width:100%; border-collapse:collapse; } td, th { padding:1.2mm 2mm; border-bottom:1px solid #eee; vertical-align:top; }
th { text-align:left; font-size:9pt; color:#666; font-weight:600; } .n { text-align:right; white-space:nowrap; width:18mm; }
tr.total td { font-weight:700; border-top:2px solid #1d1d1f; border-bottom:none; }
table.ot { width:60%; } .projects { break-inside:avoid; }
ul.note { margin:2mm 0 0; padding-left:5mm; color:#444; font-size:9.5pt; } li { margin:0.6mm 0; }
section { break-inside:avoid; margin-top:3mm; }
h3 { font-size:11pt; margin:0 0 1mm; } .tot { float:right; } .sub { color:#888; font-weight:400; font-size:9pt; margin-left:2mm; }
.tasks td.n { width:20mm; }
.method { break-inside:avoid; color:#555; font-size:9pt; margin-top:6mm; border-top:1px solid #ddd; padding-top:3mm; }"""
doc = f"""<!doctype html><html lang=ru><head><meta charset=utf-8><title>{e(L['title'])}</title><style>{css}</style></head><body>
<h1>{e(L['title'])}</h1><div class=meta>{e(r['person'])} · {period}</div>
<h2>{L['norm']}</h2>
<table class=ot><thead><tr><th></th><th class=n>{L['col_norm']}</th><th class=n>{L['col_fact']}</th><th class=n>{L['col_over']}</th></tr></thead><tbody>
<tr><td>{L['days']}</td><td class=n>{c['norm_days']}</td><td class=n>{c['worked_days']}</td><td class=n><b>{c['worked_days'] - c['norm_days']:+d}</b></td></tr>
<tr><td>{L['hours']}</td><td class=n>{norm}</td><td class=n>~{tot}</td><td class=n><b>{over:+d} ({pct_over})</b></td></tr></tbody></table>
<ul class=note>{''.join(f'<li>{e(n)}</li>' for n in notes)}</ul>
<h2>{L['projects']}</h2>
<table class=projects><thead><tr><th>{L['project']}</th>{''.join(f'<th class=n>{m}</th>' for m in mon)}<th class=n>{L['total']}</th><th class=n>{L['share']}</th></tr></thead>
<tbody>{rows}<tr class=total><td>{L['grand']}</td>{''.join(f"<td class=n>{r['month_totals'][m]}</td>" for m in r['months'])}<td class=n>{tot}</td><td class=n>100%</td></tr></tbody></table>
<h2 class=newpage>{L['tasks']}</h2>{sections}
<div class=method><b>{L['method_title']}</b> {e(L['method'])}</div></body></html>"""
os.makedirs(a.out, exist_ok=True)
open(f'{a.out}/report.html', 'w').write(doc)

md = [f"{L['title']}, {period} ({r['person']})", '', f"{L['norm']}:",
      f"• {L['days']}: {L['col_norm'].lower()} {c['norm_days']}, {L['col_fact'].lower()} {c['worked_days']}, {L['col_over'].lower()} {c['worked_days'] - c['norm_days']:+d}",
      f"• {L['hours']}: {L['col_norm'].lower()} {norm}, {L['col_fact'].lower()} ~{tot}, {L['col_over'].lower()} {over:+d} ({pct_over})"]
md += [f'• {n}' for n in notes]
md += ['', f"{L['grand']}: ~{tot} {L['h']} (" + ', '.join(f"{m.lower()} {r['month_totals'][k]} {L['h']}" for m, k in zip(mon, r['months'])) + ')']
for x in r['projects']:
    md += ['', f"{x['title']} — {x['total'] if x['total'] else '<1'} {L['h']} ({month_line(x)})"]
    md += [f"• {t} — {h if h >= 1 else '<1'} {L['h']}" for t, h in x['bullets']]
md += ['', f"{L['method_title']} {L['method']}"]
open(f'{a.out}/report.md', 'w').write('\n'.join(md) + '\n')

if a.pdf:
    chrome = cfg.get('chrome_binary', '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome')
    profile = tempfile.mkdtemp(prefix='timesheet-chrome-')  # own profile: never touch the user's or an MCP browser
    if os.path.exists(a.pdf):
        os.remove(a.pdf)
    cmd = [chrome, '--headless=new', '--disable-gpu', '--no-pdf-header-footer', f'--user-data-dir={profile}',
           f'--print-to-pdf={a.pdf}', 'file://' + os.path.abspath(f'{a.out}/report.html')]
    proc = subprocess.Popen(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    last = -1
    for _ in range(120):  # headless Chrome often writes the PDF and then never exits: stop once the file is stable
        if proc.poll() is not None:
            break
        size = os.path.getsize(a.pdf) if os.path.exists(a.pdf) else -1
        if size > 0 and size == last:
            break
        last = size
        time.sleep(1)
    subprocess.run(['pkill', '-f', f'user-data-dir={profile}'])
    if not os.path.exists(a.pdf) or os.path.getsize(a.pdf) == 0:
        sys.exit(f'pdf NOT WRITTEN: {a.pdf}')
    print('pdf:', a.pdf, os.path.getsize(a.pdf))
print('written:', f'{a.out}/report.md', f'{a.out}/report.html')

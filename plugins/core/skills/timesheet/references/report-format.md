# Report format

## Structure

1. Title, person, period.
2. **Норма и переработка** — one neutral table: days (norm / fact / difference), hours (norm / fact / difference, %).
   Under it, three plain lines: how the norm is derived (calendar days, minus vacation, × hours), average per working
   day and hours above the norm, extra days (weekends, vacation days) and their hours.
3. **Часы по проектам** — rows per project with one column per month, total, share; an «Итого» row. Order by size,
   keep «Общее ядро», «DevOps и инфраструктура», «Созвоны…» as their own rows. The whole table stays on one page.
4. **Задачи по проектам** — starts on a new page. Per project: header with total and month split, then one-line
   bullets with whole hours. Tracker keys in parentheses when the bullet is a tracked task.
5. **Как считал** — one paragraph: sources, "parallel work counted once", the overhead factor if any, period end,
   "project hours are measured; task hours distribute the project's time".

## Wording

- Plain language a manager reads without context: no commit prefixes, class names, internal codes, session ids.
- Every bullet fits one line (≈ 75 characters in the default PDF layout). Shorten wording, not facts; "закрыто 46 из
  56" only after checking the closed items are a subset of the added ones.
- Name what was done, not activity ("Редизайн ЛК", not "работа над ЛК").
- Other clients, personal work and excluded items never appear — not even as "excluded".
- Browser time without a project is a bullet like «Работа в браузере по проектам: трекер, GitHub».

## Tone

- Overtime is a fact line, not a complaint: no red, no warning boxes, no duplicated KPI cards repeating the table.
- The report answers the requester's question. Salary or workload arguments do not belong in it; if the user asks,
  advise a separate conversation built on results (money saved, scope owned, shipped features) rather than hours,
  and to route the report through whoever requested it.

## PDF

- `scripts/render.py` writes HTML and prints it with headless Chrome using a throwaway `--user-data-dir`; it stops
  Chrome once the PDF size is stable (headless Chrome often never exits) and kills only that profile.
- CSS rules that matter: `section { break-inside: avoid }`, projects table `break-inside: avoid`, the tasks heading
  `break-before: page`, method block `break-inside: avoid`. A doubled `}` in CSS silently disables the rest of the
  rules — re-read the page after every style edit.
- Always open the rendered pages and check: no orphaned heading, no table split with a repeated total, no bullet
  wrapping, the method paragraph not alone on a page.
- Default output path: the user's Downloads folder, file named after the report and period.

## Paste-ready text

Deliver the same content as text in the reply (`report.md`), so it can go into a tracker comment or chat without the PDF.

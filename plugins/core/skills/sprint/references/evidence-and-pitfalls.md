# Sprint workbook evidence and pitfalls

## Workbook discovery

- Detect sprint tables from normalized header labels, not sheet names. Historical workbooks mix old, transitional, and
  current layouts, multiple task blocks per sheet, and non-sprint helper tabs.
- Enumerate `visible`, `hidden`, and `veryHidden` sheets. Scan hidden rows inside visible sheets; hidden task estimates can
  materially change capacity.
- Find the real used range from non-empty cells, not styled `max_row`/`max_column` alone.
- Locate task, capacity, and actual-estimate blocks separately. Do not count summary rows as tasks.
- Read data validation and mapping sheets before writing direction, priority, status, or executor values.
- Inventory native hyperlinks, hyperlink formulas, and URLs stored as plain text. Deduplicate specifications by
  `(provider, file_id, tab_or_gid, fragment)`, not file ID alone.

## Historical matching

- Normalize whitespace, punctuation, spelling variants, and obvious epic typos while retaining the original cell text.
- Preserve `epic → task → subtask` context. A task ID alone can refer to an intentional duplicate or a mislabeled row.
- Build carry-over chains across consecutive sprints. A repeated estimate is continuing work, not another completed
  analogue; a falling estimate can represent remaining work.
- Prefer explicit actual estimates when the workbook has them. Planned estimates remain the baseline when actuals are
  absent.
- Separate meetings/testing, coding, review, QA, deploy, data work, and leave before comparing historical throughput.

## Git and session evidence

- Inspect local heads, remotes, tags, and relevant worktrees with `git log --all`; the implementation may not be on the
  current branch.
- Normalize author identities from Git names/emails, workbook assignee maps, and established aliases.
- Use non-merge implementation commits for ownership. Release integrators and merge authors do not inherit feature credit.
- Confirm task association through task ID, branch, changed paths, or distinctive specification details. Timing proximity
  alone is insufficient.
- Classify direction from meaningful production paths across repositories. Workbook labels can be stale or copied.
- Scope Claude/Codex/Cursor transcripts by recorded `cwd`, repo worktrees, task date, and task identity. Read top-level
  user requests/final summaries first; inspect tool events only to resolve scope or completion.
- Treat session elapsed time as context, never billable developer time. Parallel agents, review loops, browser QA, and
  waiting inflate it.

## Specification signals

- Resolve Google Docs tabs and outline headings through the live UI. Follow the exact URL and fail closed when a requested
  tab redirects to another tab.
- Preserve Docs headings/bookmarks, Sheets `gid`, and Figma `node-id`. A base file URL proves only the file, not the task.
- Treat blank descriptions and labels such as `waiting for mockup`, `awaiting`, `received in chat`, or `no design` as
  incomplete specification evidence.
- Count roles, UI surfaces, API/database changes, state transitions, integrations, money movement, scheduled work,
  notifications, admin/PDF output, and test/QA matrices when estimating scope.

## Corrections this workflow prevents

1. **Wrong active export:** Google Sheets CSV export can return a stale/different sheet. Export the workbook as XLSX and
   select the target by verified title and `gid`.
2. **Blank-assignee totals:** `SUMIF` returns zero for unassigned rows even when estimates exist. Sum rows independently
   before diagnosing a formula.
3. **Offset formulas:** Criteria and sum ranges copied from different start/end rows produce plausible but wrong totals.
   Generate both from the exact task block.
4. **Locale parse errors:** XLSX shows normalized comma-separated formulas while live Sheets may require semicolons.
   Inspect live syntax and verify calculated values, not formula presence.
5. **Collateral clearing:** A stale contenteditable/formula-bar locator can clear the wrong range. Use bounded range paste
   for constants and re-export immediately.
6. **Formula links:** `HYPERLINK()` produces ordinary underlined text, not the Drive file chips used by surrounding rows.
7. **Generic links:** Reusing one file URL for every row loses task-level navigation. Resolve each Docs heading or tab.
8. **Premature chip conversion:** Pressing `Tab` before the `replace with` prompt appears leaves raw URLs. Detect the prompt
   per cell.
9. **Flattened chip export:** XLSX can preserve a hyperlink while discarding rich-chip metadata or its fragment. Verify
   native appearance and the live popover destination.
10. **History by stereotype:** Broad domain frequency can contradict the latest exact continuation. Weight exact task and
    recent ownership first.
11. **Capacity-shaped estimates:** Making every task smaller until the summary reaches zero deviation falsifies scope.
    Keep estimates honest and leave overflow unassigned.
12. **False equality:** Equal calendar totals can hide unequal coding work when meetings differ. Compare coding and
    meetings separately.
13. **Artificial epic splitting:** Row-by-row bin packing maximizes numerical fit but creates handoffs. Allocate whole
    epics first.
14. **Nominal balance:** Equal task counts, formula totals, or calendar hours do not prove equal engineering load. Sum
    only remaining coding work per executor, exclude meetings and completed work, and state the residual hour difference.

## Final evidence record

Retain a concise private record of:

- workbook export timestamp, workbook ID, target sheet/gid, and every included sheet state;
- pre/post values for touched cells;
- exact task URL expected for every chip and its live verified URL;
- independent per-executor coding and meeting sums;
- capacity, assigned work, overflow, and epic splits;
- the independently minimized coding-hour difference between executors and any indivisible epic that prevents equality;
- estimate confidence and missing evidence;
- inaccessible or redirected specifications;
- formula text plus calculated values after save.

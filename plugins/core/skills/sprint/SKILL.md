---
name: devkit-sprint
description: >-
  audit and update sprint-planning Google Sheets workbooks using a project-local historical evidence snapshot plus
  target/changed specification, Git, and session evidence; estimate remaining coding hours, classify
  back/front/common/full work, assign executors, balance real coding capacity, and add native task-specific Drive smart
  chips. Use for sprint estimation, capacity allocation, executor assignment, or repairing planning-workbook links and
  totals. Does not implement product code.
---

# Sprint Workbook Planner

Build an evidence-backed, capacity-feasible sprint plan. Treat the workbook as a historical planning database, not as a
single visible table.

## Inputs and boundaries

1. Resolve the exact workbook URL, target sprint sheet, and related repository roots. Use the user's named browser when
   specified; otherwise select the browser or connector that can preserve authenticated Google Sheets state.
2. Stay read-only unless the user asked to update the workbook. Never change linked specifications, source repositories,
   tracker tasks, sharing settings, or hidden support sheets as a side effect.
3. Read executor aliases from workbook validation and mapping sheets. Never translate or guess a person's canonical cell
   value from a conversational nickname.
4. Record the target `gid`, visible sheet title, allowed mutation columns, and pre-change values before editing.
5. Obtain the required action-time confirmation before clearing existing cloud values or assignments.

## Workbook inventory

Export the workbook as XLSX from the exact live spreadsheet and inventory it before estimating:
Include every visible, `hidden`/`veryHidden` sheet and hidden row in this mechanical inventory.

```bash
SPRINT_SKILL_FILE=/absolute/path/to/the/loaded/devkit-sprint/SKILL.md
DEVKIT_HOME="${DEVKIT_HOME:-$(git -C "$(dirname "$(python3 -c 'from pathlib import Path; import sys; print(Path(sys.argv[1]).resolve())' "$SPRINT_SKILL_FILE")")" rev-parse --show-toplevel)}"
python3 -c 'import openpyxl'
python3 "$DEVKIT_HOME/plugins/core/skills/sprint/scripts/audit_workbook.py" <workbook.xlsx> --pretty
```

Use an existing environment that provides `openpyxl`; if installation is not authorized or possible, inspect the XLSX
OOXML directly and explicitly report that the bundled audit was unavailable. Do not use an active CSV export as the
workbook authority; it can return a stale or different sheet.

## Historical evidence snapshot

Locate the workbook snapshot before dispatching research. Check `SPRINT_HISTORY_SNAPSHOT`, then
`docs/sprint-history.json` under each related repository root. Follow
[history-snapshots.md](references/history-snapshots.md).

1. Validate the snapshot quality gates, match `workbook_id`, and compare the audit's `content_fingerprint` for every
   archived sheet recorded in the snapshot.
2. Reuse matching historical task, estimate, ownership, specification, and Git evidence. Do not re-open or re-summarize
   a cached specification whose exact identity is complete, immutable, and sufficiently specific for the target task.
3. Refresh only new sheets, mismatched sheet fingerprints, new exact source identities, and Git/session evidence after
   the recorded baseline. Reinspect incomplete, mutable, generic, or low-confidence sources when the target depends on
   missing detail. A changed sheet does not invalidate unchanged linked-source summaries.
4. Run a full historical rebuild only when no compatible snapshot exists, the snapshot schema is obsolete, or the user
   explicitly requests a new exhaustive audit.
5. After a successful planning run, prepare the target-sprint and new-source snapshot delta. Persist it only when the
   user authorized repository changes or project instructions designate the snapshot as planner state. Preserve prior
   provenance; never replace a confident historical record with a weaker inference.

The XLSX auditor still inventories every sheet mechanically. The snapshot removes repeated semantic investigation; it
does not permit ignoring a detected historical change.

## Investigation wave

Dispatch three independent read-only investigation lanes in parallel. Use `gpt-5.6-luna` at high or xhigh reasoning on
Codex; use the fastest available research subagent on another harness and report the substitution. Each lane must cover
its complete scoped delta, including inaccessible-item reporting; sampling within that delta is not sufficient.

| Lane | Required coverage | Output |
|---|---|---|
| Workbook delta | Target sheet and capacity block, plus new or fingerprint-mismatched sheets; use cached history for matching archived sheets | Target ledger, changed-history records, capacity/formula defects, ownership continuity |
| Linked specifications | Target and changed-sheet source identities absent from the snapshot or cached as incomplete; preserve Docs `tab`, `#heading`/bookmark, Sheets `gid`, and Figma `node-id` | New row-to-exact-link records, complete scope summaries, confidence, inaccessible items |
| Git and sessions | Target-specific refs plus commits and repo-scoped Claude/Codex/Cursor sessions after the snapshot baseline; widen only when an exact match remains ambiguous | New task-to-code evidence, direction, owner continuity, complexity signals, ambiguous/unproven matches |

The primary agent must directly inspect the target sprint, capacity block, proposed mutations, and final workbook. Subagent
summaries do not replace final verification. Evidence collection rules and failure patterns are in
[evidence-and-pitfalls.md](references/evidence-and-pitfalls.md).

Before dispatch, query only the matching task, title, epic, source, and Git-baseline records. Give each lane that scoped
evidence packet and delta; never make descendants load the complete snapshot.

## Evidence ledger

Create one private ledger row per target task before deciding estimates or ownership:

| Field | Required value |
|---|---|
| Identity | sheet, row, epic, task, subtask, task ID |
| Specification | exact URL, completeness, roles/surfaces/states, missing inputs |
| History | matching prior rows, carry-over chain, prior estimate/actual estimate, prior executor |
| Code | repos/refs, implementation commits, changed layers, tests/review/QA evidence, evidence strength |
| Decision | direction, remaining-hours estimate, confidence, preferred executor, capacity result |
| Mutation | exact cells, old values, intended values, link target |

Match evidence in this order:

1. Exact task ID plus matching epic/task/subtask context.
2. Exact or normalized title plus epic, adjacent sprint, branch, and changed paths.
3. Complete linked specification and closest implemented analogue.
4. Recent repeated ownership of the same feature area.
5. Broader executor history only as a tie-breaker.

Treat a repeated task ID across sprints as a continuation unless evidence proves separate work. Do not collapse duplicate
IDs with different task/subtask context.

## Direction

Classify from required production changes and real diffs. Treat the workbook's prior direction as evidence, not truth.
Write only a value allowed by the target sheet's validation; map `common` to the workbook's canonical equivalent.

| Direction | Meaning |
|---|---|
| `back` | Server/API, database, admin, jobs, integrations, backend configuration, or backend-only tests |
| `front` | Web/mobile UI, client state, routing, assets, accessibility, or frontend-only tests |
| `full` | Meaningful production changes are required in both backend and frontend/mobile repositories |
| `common` | Meetings, research, data/ops work, or cross-cutting work that is not owned by one application layer |

## Estimation

1. Establish whether the sheet stores full implementation estimates or remaining work. Treat a new task as full scope;
   subtract completed work only for an evidenced continuation.
2. Classify implementation evidence as `exact`, `continuation`, `foundation`, `adjacent`, or `absent`. Only exact or
   continuation evidence may subtract completed production surfaces and tests. Foundation reduces setup; adjacent work
   proves familiarity but does not make the target partly complete.
3. Build a scope ledger before choosing hours. Count distinct repositories, models/schema, requests/resources, services,
   provider APIs/webhooks, persistence/media, UI surfaces, roles/authorization, state transitions, observability, tests,
   and QA paths. Trace propagation terms such as flag, access, persist, autosave, every/all flows, and attachment limits
   across producers, storage, consumers, and tests.
4. Estimate the epic first, then allocate shared implementation to task rows. Discount a shared foundation only when the
   exact reusable artifact is named; record the discount once.
5. For incomplete scope, produce low/likely/high hours and mark the estimate provisional. Write a point value only when
   the workbook requires it and derive the likely value from scope plus analogues—not spare capacity. Use a separate
   discovery spike for tasks phrased as research, investigation, or “figure out.”
6. Prefer completed analogues with the same task ID and scope. Weight exact scope and recency above repository-wide
   frequency. Use the workbook's observed estimate increments instead of inventing a new scale.
7. Freeze the estimate ledger before capacity allocation. Record its total and task identities. Capacity, desired
   equality, executor availability, or a convenient shared-foundation claim must never change the frozen estimates.
8. Treat a human planner revision as strong calibration evidence, not an actual coding duration. Declare an estimate
   over/under only when an actual coding-hours field exists; otherwise report the point/range disagreement and its scope
   evidence.
9. Use Git/session evidence to understand scope and continuity, not as a stopwatch. Never sum parallel subagent time,
   review waits, merge commits, generated lines, or raw LOC into developer hours.
10. Keep large tasks honest. Do not shrink estimates to fit capacity, turn a blank into zero, or delete a scoped task
    without recording it as moved, removed, deferred, or overflow.

## Assignment and capacity

1. Calculate each executor's real coding capacity after meetings, leave, and other explicit reservations. Calculate actual
   assigned coding hours from task rows; do not trust summary formulas until independently reproduced.
   Independently prove that assigned plus unassigned coding hours equals the frozen estimate total; `SUMIF` by executor
   silently omits blank assignments.
2. Balance real coding hours as equally as the discrete work permits, while keeping every executor at or below available
   coding capacity. Report meetings separately even when total calendar hours are also equal.
   Minimize the absolute difference in assigned coding hours; when exact equality is feasible without splitting an epic
   or exceeding capacity, exact equality is required. Otherwise report the smallest attainable difference and why.
3. Keep an epic with one executor when possible. Prefer the executor who recently completed the same task or continuation.
4. Assign a whole epic to the next-best executor only when the preferred executor lacks capacity.
5. Split an epic only when no feasible whole-epic allocation exists and the sprint must contain part of it. Record the
   boundary and reason.
6. Leave whole tasks or epics unassigned when capacity is exhausted. Report them as overflow; never conceal overload by
   lowering estimates or excluding rows from the ledger.
7. If the user says every listed task is committed and the honest estimate exceeds capacity, report the overcommit before
   mutation. Estimation correctness outranks a zero-deviation summary.

## Workbook mutation

Apply the prepared mutation ledger surgically.

1. Select the exact target sheet and revalidate its `gid` immediately before editing.
2. Paste bounded column ranges for numeric estimates, directions, and executors. Avoid stale formula-bar locators for bulk
   constants. Re-export and compare every touched row after each logical batch.
3. Preserve existing dropdown/validation values and cell formatting. Do not edit formulas unless the requested result
   requires it.
4. Use identical bounded criteria and sum ranges in capacity formulas. Infer the live Sheets argument separator from an
   existing formula; XLSX export normalizes formula syntax and does not prove the live locale.

### Native task-specific Drive chips

1. Resolve the exact destination for every row from the Docs outline or task tab. A generic file URL is not a task link.
2. Paste the full URL into the description cell, preserving `tab`, `gid`, heading/bookmark fragment, and other identity
   parameters.
3. Wait until Sheets visibly offers `replace with`/`заменить на`; only then press `Tab` to create the native file chip.
   Sending `Tab` early leaves a raw URL.
4. Never use `HYPERLINK()` when neighboring rows use native Drive chips; it renders as underlined text.
5. Verify every mutated chip visually and inspect its live popover URL against the ledger. XLSX export flattens chip
   metadata and can omit the fragment even when the live chip retains it.

## Verification

Do not report completion until all checks pass:

- every worksheet and hidden row was mechanically inventoried, and every historical fingerprint is either matched or
  covered by the incremental research delta;
- every target task has the intended numeric estimate or an explicit provisional/overflow state;
- the frozen estimate total equals assigned plus unassigned coding hours, and no assigned executor exceeds capacity;
- direction matches the required code surfaces and the sheet's allowed value;
- canonical executor values match workbook mappings;
- assigned coding hours were independently summed per executor and are within capacity;
- coding work is as equal as possible without shrinking tasks; meetings are reported separately;
- no epic is split unless the ledger records the unavoidable boundary;
- every task link is a native chip whose live URL reaches the exact task target;
- capacity formulas use aligned task ranges and contain no `#ERROR!` or `#REF!`;
- a post-change XLSX comparison shows no unintended estimate, executor, formula, or neighboring-cell changes;
- the live document status reports saved.

## Output

Report workbook/sprint identity, research coverage, coding capacity versus assigned coding hours, meeting hours, epic
ownership, unassigned overflow, provisional estimates, direction changes, chip verification, formula repairs, and saved
status. State inaccessible sources and remaining uncertainty without inventing substitutes.

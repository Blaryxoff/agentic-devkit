---
name: devkit-timesheet
description: >-
  reconstruct a person's actual working hours for a period from AI-agent logs (Claude Code, Codex, Cursor, Telegram
  bots), prompt history, commits, browser history, trackers and calls, and deliver a per-project / per-task hours
  report as text and PDF. Use for "отчёт по затраченному времени", "сколько часов на каждый проект",
  "timesheet", "часы из нейронки". Does not estimate future work (devkit-estimate) or plan capacity.
---

# Timesheet

Turn scattered activity into a defensible report of the person's own hours: how much per project, what tasks, how
that compares with the working-time norm. The numbers must survive a skeptical reader, so every hour traces to
a timestamped trace of the person working. Use the fixed target-only timeline below; put the remaining modelling
choices that move the total to the user.

## Inputs

| Input | Default |
|---|---|
| period | ask; normalise to `YYYY-MM-DD..YYYY-MM-DD`, state it back |
| person and their identities | git author names/emails, tracker user, Telegram user id — discover, then confirm |
| target (employer/client) and its projects | ask; a multi-brand product lists every brand |
| target repos | cwd plus sibling repos/worktrees of the same product |
| vacation, holidays, hours per day | ask for vacation; production calendar for the country; 8 h |
| output | Russian text in `Проект — N ч (авг / сен) — задачи` form + PDF unless told otherwise |

## Workflow

1. **Inventory sources before computing.** Walk every row of `references/sources.md`: which exist on this machine,
   which live remotely (bot containers, other hosts), what retention already deleted. Report coverage per source and
   week, including separate Claude, Codex and Cursor coverage. A week with commits but no prompts is a retention
   hole, not idle time. Check browser profiles and surviving dates before asking about unmeasured calls or QA.
   For Codex, inspect input history, thread metadata and cached user messages even when rollout files survive.
2. **Collect task truth from trackers.** Pull the person's tasks and their activity (`references/sources.md#trackers`).
   A task belongs to the period only with evidence inside it: the person's own status change, comment, commit or prompt.
   Bulk-imported tasks carry import dates, and bulk clean-ups flip statuses — neither is work.
3. **Write the config.** Copy `assets/timesheet.example.json` to the scratchpad and fill projects, keywords, path hints,
   tasks and report bullets from the tracker tasks and commit scopes. Keep it outside the repo — it names clients.
4. **Extract.** Run `scripts/extract_sessions.py`, `scripts/browser_history.py`, dump bot databases with
   `scripts/hermes_dump.py`, export commits (`git log --all --since --until --author --name-only --format='@@%H|%aI|%s'`).
   Check the extractor's `<out>.coverage.json`: missing rollouts, unmapped history and source coverage are not idle time.
5. **Compute.** Run `scripts/timeline.py` using the calculation method below. Detailed classification and sensitivity:
   `references/method.md`.
6. **Run the sanity gates** (`references/method.md#sanity-gates`) and fix classification before any number reaches the user.
7. **Reuse confirmed decisions; ask only what is missing** — one structured question each, with numbers for every option
   (`references/method.md#decisions-the-user-owns`): gap/tail intervals, which calls belong to the target, overhead
   factor, and whether personal activity or non-billable infrastructure stays out. Explain the parameters directly;
   do not send the user to an older report or require its artifact to apply this method. Never ask about other clients.
8. **Allocate and render.** `scripts/allocate.py` then `scripts/render.py --pdf <path>`. Open the PDF pages and check breaks,
   single-line bullets, and that rows reconcile with totals (`references/report-format.md`).
9. **Deliver** the paste-ready text in the reply plus the PDF path. State which sources were used, what could not be
   measured, and every factor applied.

## Calculation method

- Use local-time human activity timestamps. Within one session, count the interval to the next prompt when it is
  at most 30 minutes; otherwise count 15 minutes after the prompt. The last prompt also gets 15 minutes. Browser
  visits use a stricter 10-minute gap and 5-minute tail. These intervals model reading and responding, not agent runtime.
- Merge intervals into one minute timeline. A minute with target activity counts once; divide it equally among the
  target projects active in that minute. Sum those shares by project, task, date and month.
- Fill verified transcript-retention gaps with the person's own commits as low-confidence anchors. Before the
  verified retention cutoff they can supplement surviving prompts; afterwards use them only on days without human
  logs for that repo. Disclose this contribution separately; commit counts never convert directly to hours.
- Start with coefficient ×1.00. Add an uplift only when explicitly chosen for this report, proportionally across
  projects and tasks. Add calls and off-log work only from measured evidence or the person's figure. Leave missing
  hours unmeasured when requested; describe what may need adding later without overlap.
- Assign matched task time to its report bullet. Distribute unmatched time within that project 50% equally among
  bullets and 50% in proportion to matched time. Mark task-hour distributions as estimates when matching is weak.
  Round with the largest-remainder method so task hours sum to project hours and project hours sum to the total.
- Calculate the norm from the production calendar: working days minus vacation working days, multiplied by daily
  hours (8 by default). A day with at least 30 measured minutes counts as a worked day; shorter activity still adds
  hours. Compare reconstructed hours with the norm, stating missing coverage instead of treating it as no work.

## Hard rules

- Count only the person's own time. Teammates' commits are context, never hours.
- Human anchors only: typed prompts, own chat messages, own browser visits, calls. Autonomous agent runtime, exec
  sub-sessions, peer-agent chatter, scheduled/cron turns and notifications never create time. In verified retention
  gaps, own commits may supply disclosed low-confidence anchors (`references/method.md`). Thread creation/update
  timestamps never create time. Reject `isCompactSummary` even when a record claims `turnOrigin: human`.
- Parallel sessions count once: use `parallel_other_clients: union`; count each target minute once and share it only
  among the target's projects. Unrelated activity never reduces the target's minutes; do not offer union vs split.
- Never invent a number. Calls, off-log work and manual QA enter only from a source or from the user's own figure.
  An overhead factor is stated in the method line, never hidden. Honour ×1.00 and a choice to leave calls unmeasured.
- Show missing source coverage in a separate report section (`coverage_title`, `coverage_text`); name the missing
  dates and affected work, and say confirmed hours can be added later without double counting. Missing records are
  unmeasured time, not proof of no work. Never infer a cleanup date from the first surviving browser visit alone.
- Other clients never appear in user-facing questions, commentary, report text or PDF, not even as exclusions,
  anonymous comparisons or alternative totals. Keep any classification needed to filter them internal.
- Read browser history and bot databases read-only, from copies or `?mode=ro`/`immutable=1`; query only the listed
  work domains and the person's user id.
- Kill only processes you started (the report's own Chrome profile). Never kill MCP, the user's browser or agents.
- A question from the user about the method is answered first; recompute only when asked.

## Scripts

| Script | Job |
|---|---|
| `extract_sessions.py` | Claude and Codex input history, transcripts, read-only Codex caches, Cursor composers, bot dumps → sessions + coverage |
| `hermes_dump.py` | one user's messages from a Hermes-style bot `state.db`; run inside the bot's container |
| `browser_history.py` | Chrome History copies → work-site visits and call rooms with durations |
| `timeline.py` | anchors → minute timeline → hours per project/month/task/day, sanity summary |
| `allocate.py` | overhead factor, task→bullet allocation, largest-remainder rounding, norm/overtime calendar |
| `render.py` | `report.md`, `report.html`, PDF via headless Chrome (own profile, stops when the file is stable) |

All are stdlib Python 3; no installs.

---
name: devkit-timesheet
description: >-
  reconstruct a person's actual working hours for a period from AI-agent logs (Claude Code, Codex, Cursor, Telegram
  bots), prompt history, commits, browser history, trackers and calls, and deliver a per-project / per-task report
  with norm vs overtime as text and PDF. Use for "отчёт по затраченному времени", "сколько часов на каждый проект",
  "timesheet", "часы из нейронки". Does not estimate future work (devkit-estimate) or plan
  capacity (devkit-sprint).
---

# Timesheet

Turn scattered activity into a defensible report of the person's own hours: how much per project, what tasks, how
that compares with the working-time norm. The numbers must survive a skeptical reader, so every hour traces to
a timestamped trace of the person working, and every modelling choice that moves the total is the user's decision.

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
   week; a week with commits but no prompts is a retention hole, not idle time.
2. **Collect task truth from trackers.** Pull the person's tasks and their activity (`references/sources.md#trackers`).
   A task belongs to the period only with evidence inside it: the person's own status change, comment, commit or prompt.
   Bulk-imported tasks carry import dates, and bulk clean-ups flip statuses — neither is work.
3. **Write the config.** Copy `assets/timesheet.example.json` to the scratchpad and fill projects, keywords, path hints,
   tasks and report bullets from the tracker tasks and commit scopes. Keep it outside the repo — it names clients.
4. **Extract.** Run `scripts/extract_sessions.py`, `scripts/browser_history.py`, dump bot databases with
   `scripts/hermes_dump.py`, export commits (`git log --all --since --until --author --name-only --format='@@%H|%aI|%s'`).
5. **Compute.** Run `scripts/timeline.py`. Model and every parameter: `references/method.md`.
6. **Run the sanity gates** (`references/method.md#sanity-gates`) and fix classification before any number reaches the user.
7. **Put the decisions to the user** — one structured question each, with the numbers for every option
   (`references/method.md#decisions-the-user-owns`): parallel work for other clients (union vs split), which calls
   belong to the target, overhead factor, whether excluded activity (personal, other clients, non-billable infra) stays out.
8. **Allocate and render.** `scripts/allocate.py` then `scripts/render.py --pdf <path>`. Open the PDF pages and check breaks,
   single-line bullets, and that rows reconcile with totals (`references/report-format.md`).
9. **Deliver** the paste-ready text in the reply plus the PDF path. State which sources were used, what could not be
   measured, and every factor applied.

## Hard rules

- Count only the person's own time. Teammates' commits are context, never hours.
- Human anchors only: typed prompts, own chat messages, own browser visits, calls. Autonomous agent runtime, exec
  sub-sessions, peer-agent chatter, scheduled/cron turns and notifications never create time. The one exception is a
  retention hole: own commits and exec starts become low-confidence anchors only where no transcript survives
  (`references/method.md`), and the report says so.
- Parallel sessions count once: build one minute timeline across every repo, including other clients.
- Never invent a number. Calls, off-log work and manual QA enter only from a source or from the user's own figure.
  An overhead factor is stated in the method line, never hidden.
- Other clients never appear in the report text, not even as exclusions.
- Read browser history and bot databases read-only, from copies or `?mode=ro`/`immutable=1`; query only the listed
  work domains and the person's user id.
- Kill only processes you started (the report's own Chrome profile). Never kill MCP, the user's browser or agents.
- A question from the user about the method is answered first; recompute only when asked.

## Scripts

| Script | Job |
|---|---|
| `extract_sessions.py` | Claude transcripts + `history.jsonl`, Codex rollouts, Cursor IDE composers, bot dumps → `sessions.jsonl` |
| `hermes_dump.py` | one user's messages from a Hermes-style bot `state.db`; run inside the bot's container |
| `browser_history.py` | Chrome History copies → work-site visits and call rooms with durations |
| `timeline.py` | anchors → minute timeline → hours per project/month/task/day, sanity summary |
| `allocate.py` | overhead factor, task→bullet allocation, largest-remainder rounding, norm/overtime calendar |
| `render.py` | `report.md`, `report.html`, PDF via headless Chrome (own profile, stops when the file is stable) |

All are stdlib Python 3; no installs.

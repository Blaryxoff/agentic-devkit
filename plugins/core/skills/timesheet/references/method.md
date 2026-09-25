# Time model

## Anchors

- A human anchor is one timestamp of the person acting: a typed prompt, an own bot message, a work-site visit,
  a call minute. Everything is bucketed in the person's local timezone (`tz_offset_hours`).
- A prompt covers `[t, next prompt of the same session)` when that gap ≤ `gap_minutes` (default 30), otherwise
  `tail_minutes` (default 15) after it. This counts writing the next prompt and reading the answer, and stops
  counting when the person walked away while the agent ran.
- Browser visits use a stricter rule (≤ 10 min gap, else 5 min) — a page load says less than a prompt.
- Before `transcript_cutoff` (the date from which transcripts are continuous) add low-confidence anchors from commit
  times and exec-session starts even on days that have some human anchors; one surviving prompt must not suppress
  a day of commits. After the cutoff they fill only days with no human anchor in that repo (a day of commits from a
  bot or another machine). Commits are the person's own (`--author`), never teammates'.
- Calls cover their measured minutes and override everything else in those minutes.

## One timeline

- Build a single minute timeline across **all** repos and sources. Each minute holds the set of labels active in it.
- `union`: a minute with any target label counts fully for the target and splits only among target labels
  (other clients in parallel are ignored). `split`: the minute also splits with other clients' labels. The choice is
  the user's (see below); per-project shares barely change between them, absolute totals do.
- Sum per label, per month, per day. Days are the local calendar date.

## Classification

Per prompt, highest score wins (≥ 2), else carry the previous label of the session, else the session's dominant
label, else the common/core bucket:

| Signal | Weight |
|---|---|
| project keyword in the prompt text (RU + EN spellings, brand hosts) | 5 per hit |
| repo/worktree/branch name hint | 3 |
| project keyword in agent actions until the next prompt (paths, hosts, commands) | 1 × `agent_weight` (lower it for words common in shared code, e.g. "tenant", "school") |
| weak DevOps words (deploy, CI, ssh, server, prod) | 5 × 0.4 per hit |
| task keyword whose task names a project, when the prompt names no project | +6 |

- A prompt labelled DevOps only by weak words labels itself but does not recolour the rest of the session.
- Prompts in another repo count for the target only if they name it and the repo is a known infra repo
  (`outside_repo_rx`); they go to DevOps.
- `reroute` moves matching prompts to another project/task or drops them (non-billable, personal). Use it when the
  user says a class of work belongs elsewhere, instead of editing numbers by hand.

## Tasks

- Task = first matching `tasks[].re` in the prompt, else in the repo/branch hint, else carried from the previous prompt.
- Generic tasks (deploy, tests, tariffs, emails…) never replace a specific carried task — otherwise one "deploy"
  prompt drags the rest of a feature session into "deploy".
- Order `tasks` specific → generic; the first match wins.

## Sanity gates

Run before any number reaches the user:

- Top days: > 12–14 h needs a look. Print anchors at night on those days; if it is genuinely the person typing,
  accept it (some people work 11:00–01:00), otherwise find the injected pattern and filter it.
- Unclassified (common bucket) share: above ~25% means project signals are too weak — add keywords/paths.
- Sample 30 anchors of each big label and read them; misrouted clients (e.g. another client's work in a session
  launched from the target repo) show up here.
- Duplicate prompt texts across sessions with identical timestamps are replays, harmless; with different timestamps
  they are real repeats.
- Coverage by week vs commits by week: holes must be explained (retention, vacation) before delivery.

## Sensitivity

Recompute with gap/tail `20/10`, `30/15`, `45/20`, `60/30` and report the range. It justifies an overhead factor:
counting pauses up to 45 min instead of 30 adds roughly 15%.

## Decisions the user owns

Ask each with numbers for every option; never decide silently:

1. **Parallel other-client work**: `union` (all time while working on the target) vs `split`.
2. **Calls**: which rooms/dates are the target (show the context evidence); unknown Telegram/phone calls → user figure.
3. **Overhead factor** for unmeasured work (Telegram, reading specs before the first prompt, reviewing results,
   deploys, pauses > gap). Apply proportionally to every project and task, and state it in the method line.
4. **Exclusions**: personal, other clients, non-billable infra; and whether the report-writing session itself counts.

## Allocation and rounding

- Bullets own task names. Owned task hours go to their bullet; the rest of the project (generic prompts, browser
  time, unowned tasks) is a pool split 50% equally across bullets and 50% in proportion to matched hours.
- Report the matched share per project to the user; below ~50% the per-task hours are an estimate of distribution.
- Round whole hours with the largest-remainder method so bullets sum to the project and months sum to the total.
  Rounding never changes the total by more than 0.5 h — say so if the user suspects "fitting".

## Norm and overtime

- Norm = working days of the production calendar in the period − vacation working days, × hours per day.
- Worked days = calendar days with ≥ `min_day_hours` (default 0.5, compared in whole minutes) of measured target
  time. A few minutes of alert replies on a day off is not a worked day; the report states the threshold, and its
  hours stay in the total.
- Overtime = total − norm, split into hours above the norm on working days and hours on weekends/vacation.

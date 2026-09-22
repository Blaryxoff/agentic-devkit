---
name: devkit-estimate
description: >-
  estimate developer working hours — the time a developer is actually occupied — with calendar elapsed as secondary
  planning context, for a software feature or project, formatted for direct paste into a tracker or Telegram. Use for "estimate this task",
  "how long will this take", agent-first, agent-only, or vibe-coding estimates at demo, alpha, beta or
  production-ready. Does not implement the work, allocate people, or edit sprint workbooks — that is devkit-sprint.
---

# Agent-First Estimator

Estimate developer working hours first as low/likely/high: the time the developer is occupied and cannot do anything
else. Agent runtime is never developer time — agents run all night while the developer sleeps. Derive calendar elapsed
second only when it helps planning. Do not convert a person-day total with a generic AI multiplier.

## Boundaries

1. Stay read-only unless the user explicitly asks for a report file or tracker/workbook update.
2. Use `devkit-sprint` when the request targets a sprint workbook, capacity, executor assignment, or numeric task cells.
3. Use the relevant architecture skill alongside this skill only when the estimate requires unresolved architecture
   design. Keep this skill responsible for the schedule.
4. Inspect every repository affected by the contract. Apply each repository's own instructions.
5. Default to one coding lane. Add a parallel lane only when the work is genuinely independent and splitting it
   measurably shortens the critical path; a small coupled change stays one lane. Do not state an agent count as an
   assumption — the reader's agents scale, their review and integration capacity does not. Cap concurrency by the
   developer's capacity to specify, review, integrate, and recover lanes. Developer time is computed from those
   lanes, never inferred from the calendar schedule as a fraction of it.
6. Treat product decisions and unavailable inputs as schedule dependencies. Split materially different interpretations
   into scenarios instead of silently choosing one.

## Maturity levels

Estimate only the requested outcome by default. Read [maturity-levels.md](references/maturity-levels.md) when the user
asks for multiple maturity levels or the choice between them changes the decision.

## Evidence hierarchy

Use evidence in this order:

1. Exact current implementation and tests in the target repositories.
2. A high-context maintainer's scoped statement about this codebase — what is already built, what remains, how large
   the remaining change is. Reconcile it against current code; never override it with a generic analogue when the code
   agrees with it.
3. Exact or continuation task history from local sessions, plans, commits, reviews, and QA records, including any
   prior estimate of this or an adjacent scope.
4. Completed local analogues with similar layers, state transitions, integrations, and maturity.
5. Current primary web evidence about agent workflows.
6. Generic engineering judgement.

Classify each requirement as `exact`, `continuation`, `foundation`, `adjacent`, or `absent`. Only `exact` and
`continuation` subtract completed behavior. `foundation` reduces setup. `adjacent` proves familiarity, not completion.

State a completion or reuse percentage only when it is computed from weighted requirement rows with the denominator
shown. Otherwise name the reusable artifacts and their classifications without a percentage.

## Workflow

### 1. Freeze the estimate target

Record:

- requested maturity level and deadline unit;
- in-scope repositories, roles, surfaces, and environments;
- explicit exclusions such as design, client work, deployment, content entry, or vendor procurement;
- agent/developer concurrency;
- acceptance criteria and unresolved decisions;
- any prior estimate of this or an adjacent scope, its method, and the reason it changed.

The base scenario is the scope exactly as the user wrote it, and it carries the recommendation. Every expansion beyond
that literal text — extra consumers, a shared registry, a template library, additional roles, a second client — is a
named delta reported below the recommendation. Never headline an expansion the user did not request, and never label
one "recommended".

Schedule only work the literal text asks for. A safeguard the user did not request — backfilling users who already
qualified, unifying behavior across clients the task never named, migrating existing records — is an open question
listed under assumptions with its own delta, not a lane in the base schedule. Raising it is useful; charging days for
it silently is how a one-action change becomes a week.

Read configuration and selection requirements against the entities that already exist. "Choose an already-created
template" means selecting among existing records, not building a template library; a toggle on an existing settings
screen means a field, not a new admin surface. Infer a new entity, a changed cardinality, or an additional client only
when the literal text asks for it or the code proves the literal scope cannot work without it.

If one ambiguity changes the likely estimate by 25% or more, produce separate scenarios. Ask only when a
scenario split would not let the user plan safely.

### 2. Ground in the current product

Inspect the smallest source slices that prove:

- existing models/schema, actions/services, endpoints, jobs, and integrations;
- existing admin, web, or mobile consumers of the contract;
- current tests and their actual status;
- designs/specifications and mandatory states;
- incomplete, disabled, reverted, or branch-only implementations that can be recovered. Search every ref, not `HEAD`:
  `git log --all --oneline -i --grep=<feature>`, then check whether that commit's files still exist at `HEAD`. A
  complete implementation later dropped by a revert or rollback converts a build lane into a restore lane.

Do not equate an existing route, table, UI shell, or old commit with complete behavior. Run focused, read-only checks
when they materially change reuse confidence and fit the repository's execution rules.

### 3. Calibrate with local throughput

Search recent local sessions and Git history for the exact feature, the closest completed vertical slice, and any
prior estimate of the same scope. Extract message payloads from session logs with a structured query such as `jq`;
never read serialized session lines as prose. Preserve chronology: where a session revised its own figure, the last
evidence-backed one supersedes the rest. Never average a superseded estimate into the new one — state the delta and
what changed it.

Record:

| Field | Evidence |
|---|---|
| Scope | production surfaces, migrations, contracts, roles, tests, and QA covered |
| Reuse | exact artifacts reused by the new task |
| Developer cost | the anchor's actual developer hours, when the record shows them |
| Topology | known developer and agent concurrency |
| Delivery | credible implementation, integration, and hardening window, recorded as the anchor's delivered span |
| Follow-ups | later fixes that reveal hidden stabilization cost |

Calibrate developer hours only from anchors that record actual developer hours. Commit spans and session duration
calibrate elapsed only. Without an actual-hours anchor, use the bottom-up ledger below and cap confidence at `medium`.

Name one delivered analogue and use it only as a plausibility check. Work already delivered contributes zero days:
never add the analogue's span to the new schedule, and never treat it as a floor.

Estimate the remaining unimplemented critical path from current code first, then compare it against the analogue. When
a materially smaller scope lands above the analogue, the scope or the lane list is wrong — re-check both and recompute
rather than reporting the higher number. Name the single lane that accounts for any excess over the anchor's
developer hours, and then over its delivered span; when no lane does, the decomposition is wrong and the schedule is
recomputed before it is published.
Do not price invented blockers to justify the gap, and do not express the
comparison as a numeric ratio: counting "contours" or files produces arithmetic that looks measured and is not.

Use commit timestamps as boundaries only when session/plan evidence makes the work window credible. Never infer coding
duration from LOC, generated files, one commit timestamp, merge frequency, or parallel agent-runtime totals. File and
line counts compare the new scope against the anchor slice; they never convert to duration.

### 4. Build the execution graph

Create one row per independent delivery lane:

| Lane | Scope | Reuse | Prerequisites | Developer hours | Elapsed | Done evidence |
|---|---|---|---|---:|---:|---|

Developer hours are the lane's attended human work; elapsed is its wall-clock, including waiting and unattended
runtime. Estimate both in hours, low/likely/high. Do not estimate agent-work unless the user asks for cost or capacity.

Separate shared foundations from consumers, then apply Boundary 5: derive lanes from the artifacts this change
actually produces, never from a checklist of layers. Work that lands in one service and one screen and is reviewed
once is one lane, however many layers it crosses; splitting it inflates the schedule and the developer's acceptance
time together. A lane is parallel only when it can start without waiting for another lane's unresolved contract or
artifact.

Price a lane by what resists an agent, not by how many rows, endpoints, or screens it covers. Read-only work over a
schema that already exists — queries, aggregations, report pages, exports — is among the cheapest output an agent
produces, and a long list of such rows is one lane priced once, never a lane per row. Developer hours go where the
work needs the developer's own judgement — new domain rules, state transitions, authorization, failure handling, and
above all every figure that must reconcile with an artifact the reader already holds, because each mismatch returns
the developer to the definition.

Two things cost elapsed time without costing developer hours, and belong in the assumptions rather than the total:
inputs with no source in the system, which need an integration, a manual entry surface, or removal from scope; and
work on another party's side, whose date you do not set. Charge only the developer's own coordination on those.

### 5. Calculate developer time, then elapsed

Build a developer-hour ledger with one row per attended session: decisions/specification, agent briefing and recovery,
review plus rework, manual QA, and merge/rollout. Give each row low/likely/high hours and evidence. Sum the rows; count
one session once when it covers review, integration, and acceptance. Passive agent, test, and CI runtime costs zero; a
lane that runs longer unattended costs no more developer hours.

Then derive elapsed from the dependency graph, not the arithmetic sum of lane estimates:

```text
beta = product-decisions + longest parallel implementation path + integration/contract QA
production = beta + hardening/final review fixes + rollout margin
```

Pack ready lanes into explicit execution waves, capped by both agent slots and developer bandwidth; excess lanes wait
for the next wave. Forward-schedule the low, likely, and high cases separately. Never derive elapsed time by summing
agent-hours, dividing aggregate work by eight, or dividing a total by the agent count.

Check the result against the anchor span before reporting it. A schedule that exceeds the anchor while the scope is
smaller than the anchor is wrong until a named blocker explains it. Never reach a production figure by scaling demo,
alpha, or beta by a factor.

Include merge conflict and cross-lane contract cost when multiple agents touch the same files or schema. Concurrently
open agent branches conflict often enough to be a scheduled cost rather than a rounding error — measured rates in
[agent-first-calibration.md](references/agent-first-calibration.md) § Parallel-agent and rework cost. Include a gate
below only when this change actually touches it; drop the rest instead of pricing them at a token cost:

1. product/contract decisions that block implementation;
2. shared schema or interface foundation;
3. longest feasible parallel implementation path;
4. integration, migrations, and cross-client tests;
5. security/reliability review and fixes;
6. rollout/backfill verification.

Report developer working hours first. Add elapsed only when the user asks for a delivery window or dependencies make
it materially different. Report agent runtime or token cost only when the user asks for cost or capacity.

### 6. Apply external calibration

Read [agent-first-calibration.md](references/agent-first-calibration.md) only when the user asks for market evidence,
no credible local analogue exists, or a lane exceeds its measured autonomy horizon. Follow its Application rules and
re-fetch any cited source. Otherwise stop at local calibration.

### 7. Add uncertainty and risk deltas

Give low/likely/high ranges. Model each scope choice — reusable library versus one-off configuration, managed
provider versus custom infrastructure, one client versus multiple clients, beta versus production rollout — by
replacing the affected lanes and gates and recomputing the schedule. Report the difference between the two schedules
as the delta. Never append a free-floating allowance, multiplier, or blanket percentage contingency, and never
bury materially different scope inside one.

## Output

Return only the audience-ready estimate, with no investigation notes, skill names, or account of the workflow used.
The reader approves schedules and cuts scope; they do not read code. Write for that reader. Be brief: the whole
estimate fits on one screen, each item answered in one to three lines. Length is not thoroughness.

Report developer time in hours, always, and lead with it. Hours are schedulable; "about a week" is not a commitment.
Every delta and every cut is quoted in developer hours first. When elapsed is useful, label it as wall-clock and report
it in hours below 16 or working days at or above, at 8 hours to the day.

Open with one table carrying the schedule figures: a row per applicable maturity level, marking the one you
recommend. Developer time is the first column and the figure the recommendation is stated in. Nothing numeric
precedes the table, and no figure in it is restated in the prose below. Cuts and deltas carry their own numbers on
their own lines; they never go in the table.

Default to one recommended row for the literal requested outcome. Add maturity rows only when the user asks for them
or choosing a maturity level changes the decision; never print demo, alpha, beta, and production-ready by default.

| Level | Developer time | What you can do with it |
|---|---:|---|

Add an `Elapsed` column only when the estimate includes a delivery window.

Then, one to three lines each:

1. **Where the developer's hours go.** A one-line itemization: decisions, review and merge, integration, acceptance.
   When elapsed is included, say whether hardening can run as a separate later phase.
2. **What they cover.** Testing, review, QA, and rollout per level in the reader's words — the Maturity levels
   table's third column is that wording. Say that unattended test and CI runtime costs the developer nothing.
3. **Ways to cut it.** Mandatory when any scope item can be deferred. One line each: the user-facing capability to
   drop or postpone, the developer hours it frees, and the elapsed it buys — stated as zero when off the critical path.
4. **Assumptions and additive deltas** — scope beyond the literal request only, each with its own delta.
5. **Confidence** (`high`, `medium`, or `low`) and the one thing that would narrow it.

Add what already exists, what remains, or the critical path only when the reader's decision turns on it, capped at a
few lines. Feature inventories, option comparisons, vendor and legal analysis, infrastructure pricing, and readiness
checklists are an appendix at most and usually omitted outright — they are what you read, not what was asked.

Analogue selection, scope comparisons, and reconciliation arithmetic belong to the internal worksheet, never to the
delivered text. Do not open the estimate with a section named after the method. Mention comparable delivered work only
when it changes the reader's decision, in plain language a non-engineer uses. Show the calculation only when the user
asks how the number was derived.

Explicitly correct an earlier estimate when the evidence changes it. Do not preserve a familiar number for consistency.
Name what changed and why the number moved, beside the table; "it is described in the estimate" is not an answer to a
reader holding the previous figure. When the reader disputes a figure, re-derive the decomposition before answering:
defending a number you have not recomputed is the failure, and if it moves, say which lane or rung was soft and
reissue the affected rows. Do not create a report file unless the user asked for one.

### Paste-ready formatting

1. Use the destination the user names. If none is named, use a tracker/Telegram-compatible subset: short headings,
   complete sentences, bullets, numbered lists, and plain ranges.
2. For Telegram or chat, use short bold headings and bullets, and give the opening table as one bullet per row. For
   a tracker, use headings and bullets, and a table only where the named tracker renders it reliably.
3. Never emit Markdown horizontal rules (`---`, `***`, or `___`) or decorative dash-divider lines.
4. Evidence is mandatory internally; publishing it is not. Describe verified capabilities in product language and omit
   source paths, line numbers, commit and session IDs, and research URLs. Include them only when the user asks for an
   audit trail or names an engineering destination — then group them in a short appendix instead of interleaving them
   with the estimate.
5. Gloss or replace every engineering term on first use. `outbox`, `idempotency`, `presence TTL`, `backfill`,
   `contract QA`, `tenant isolation` — write what the thing does for the product instead.
6. End with assumptions, risks, or confidence—not with an offer to do more work.

## Final checks

- The recommended number lies inside the reported range.
- Every cut quotes the developer hours it frees, and says plainly when it does not move the date.
- Independent lanes were not summed into elapsed time; sequential dependencies were not parallelized.
- No hour in the schedule pays for behavior that already exists in the repository.
- The recommendation covers the literal requested scope; expansions appear below it and none is labelled recommended.
- Every scheduled gate traces to a path this change actually touches.
- Each lane names the artifact it produces; none exists because a layer checklist named it.
- Developer hours are the sum of named attended sessions, with overlapping touchpoints counted once.
- Confidence is not `high` without an anchor that records actual developer hours.
- No figure was produced by multiplying another figure, by adding a delivered analogue's span, or by pricing a blocker
  invented to justify a gap.
- The estimate was reconciled against any superseded prior estimate.
- Existing work was discounted once and only with named evidence.
- Every non-trivial reuse or throughput claim was verified against a repository path, commit/session, or current web
  source, whether or not that citation appears in the delivered text.
- The deliverable passes `../../conduct/readiness-gate.md`. Apply that gate internally; never append its table to
  the audience-ready estimate.

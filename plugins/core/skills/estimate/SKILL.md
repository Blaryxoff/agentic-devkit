---
name: devkit-estimate
description: >-
  estimate calendar delivery time for a software feature or project from its specification, current repositories,
  Git/session analogues, available agent concurrency, and current web evidence. Produces demo, alpha, beta, and
  production-ready ranges from the agent critical path instead of summed human person-days, formatted for direct paste
  into a tracker or Telegram. Use for "estimate this task", "how long will this take", agent-first, agent-only, or
  vibe-coding delivery estimates. Does not edit sprint workbooks or allocate people; use devkit-sprint for that. Does
  not implement the work.
---

# Agent-First Estimator

Estimate elapsed delivery time for the team that will actually execute the task. Do not convert a traditional
person-day total with a generic AI multiplier.

## Boundaries

1. Stay read-only unless the user explicitly asks for a report file or tracker/workbook update.
2. Use `devkit-sprint` when the request targets a sprint workbook, capacity, executor assignment, or numeric task cells.
3. Use the relevant architecture skill alongside this skill only when the estimate requires unresolved architecture
   design. Keep this skill responsible for the schedule.
4. Inspect every repository affected by the contract. Apply each repository's own instructions.
5. State operators and coding agents as separate numbers. When the user says agent-first/agent-only but gives no
   topology, report the primary estimate for one high-context operator with up to three parallel coding agents and
   state that assumption. Cap concurrency by both agent slots and the operator's capacity to specify, review,
   integrate, and recover those lanes.
6. Treat product decisions and unavailable inputs as schedule dependencies. Split materially different interpretations
   into scenarios instead of silently choosing one.

## Maturity levels

Estimate each requested level separately. Never call a happy path production-ready.

| Level | Required outcome |
|---|---|
| Demo | Controlled happy path is demonstrable; mocks/manual setup and known gaps are allowed. |
| Alpha | Core end-to-end flow works on real data; limited edge-case and operational coverage is allowed. |
| Beta | Intended flows, roles, states, migrations, automated tests, and integration contracts are complete. |
| Production-ready | Beta plus authorization abuse cases, retries/idempotency, backfill, observability, browser/device QA, rollback/rollout safety, and fixes from final review. |

Skip levels the user does not need, but always distinguish the requested result from the next-lower level.

## Evidence hierarchy

Use evidence in this order:

1. Exact current implementation and tests in the target repositories.
2. Exact or continuation task history from local sessions, plans, commits, reviews, and QA records, including any
   prior estimate of this or an adjacent scope.
3. Completed local analogues with similar layers, state transitions, integrations, and maturity.
4. Current primary web evidence about agent workflows.
5. Generic engineering judgement.

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
- agent/operator concurrency;
- acceptance criteria and unresolved decisions;
- any prior estimate of this or an adjacent scope, its method, and the reason it changed.

The base scenario is the scope exactly as the user wrote it. Every expansion beyond that literal text — extra
consumers, a shared registry, a template library, additional roles, a second client — is a named delta reported above
the base, never folded into the base range. Never make the expansive reading the headline number.

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
| Topology | known operator and agent concurrency |
| Delivery | credible implementation, integration, and hardening window |
| Follow-ups | later fixes that reveal hidden stabilization cost |

Name one delivered anchor slice and express the new scope as a ratio to it. A scope smaller than an anchor that
shipped in N days does not estimate above N days without a named reason.

The anchor is a ceiling, not a footnote. When no requirement is classified `absent` and most are `exact`,
`continuation`, or `foundation`, the production-ready high case does not exceed the anchor's own span. Exceeding it
requires a named blocker — an unresolved product decision, a new external integration, or a migration over live data.
Naming it is not enough: each blocker carries its own day cost on its own line, and the production likely case must
reconcile as `anchor span + sum of blocker costs`. A blocker whose days cannot be written as a line item is not a
blocker; drop it and recompute. Never report a ratio below 1.0 alongside a schedule above the anchor without that
reconciliation.

Use commit timestamps as boundaries only when session/plan evidence makes the work window credible. Never infer coding
duration from LOC, generated files, one commit timestamp, merge frequency, or parallel agent-runtime totals. File and
line counts compare the new scope against the anchor slice; they never convert to duration.

### 4. Build the execution graph

Create one row per independent delivery lane:

| Lane | Scope | Reuse | Prerequisites | Agent-work low/likely/high | Elapsed low/likely/high | Done evidence |
|---|---|---|---|---:|---:|---|

Agent-work is the effort inside a lane; elapsed is that lane's own wall-clock. They diverge whenever a lane waits.
Neither column is summed into the delivery date.

Separate shared foundations from consumers. Typical lanes include domain/schema, backend/API, admin, client UI,
integration/provider work, data migration/backfill, and tests/QA. A lane is parallel only when it can start without
waiting for another lane's unresolved contract or artifact.

### 5. Calculate elapsed time

Use the dependency graph, not the arithmetic sum of lane estimates:

```text
beta = product-decisions + longest parallel implementation path + integration/contract QA
production = beta + hardening/final review fixes + rollout margin
```

Pack ready lanes into explicit execution waves, capped by both agent slots and operator bandwidth; excess lanes wait
for the next wave. Forward-schedule the low, likely, and high cases separately. Never derive elapsed time by summing
agent-hours, dividing aggregate work by eight, or dividing a total by the agent count.

Check the result against the anchor span before reporting it. A schedule that exceeds the anchor while the scope is
smaller than the anchor is wrong until a named blocker explains it. Never reach a production figure by scaling demo,
alpha, or beta by a factor.

Include merge conflict and cross-lane contract cost when multiple agents touch the same files or schema. Concurrently
open agent branches conflict often enough to be a scheduled cost rather than a rounding error — measured rates in
[agent-first-calibration.md](references/agent-first-calibration.md) § Parallel-agent and rework cost. Keep these
sequential gates visible:

1. product/contract decisions that block implementation;
2. shared schema or interface foundation;
3. longest feasible parallel implementation path;
4. integration, migrations, and cross-client tests;
5. security/reliability review and fixes;
6. rollout/backfill verification.

Report aggregate agent-work only when the user asks for cost or capacity. Label it separately from elapsed calendar time.

### 6. Apply external calibration

Read [agent-first-calibration.md](references/agent-first-calibration.md) when the user asks for current-market
evidence, no credible local analogue exists, or a lane exceeds a measured autonomy horizon. Otherwise stop at local
calibration. Re-fetch cited sources when web access is available and cite only the pages that moved a range, a
decomposition, or the confidence rating.

- Skip this step entirely when a credible local anchor exists and the scope is mostly `exact`, `continuation`, or
  `foundation`. Those sources measure new work and inflate a scope that is already largely built.
- Use vendor case studies as evidence for achievable demo/MVP speed, never as a production multiplier.
- Use independent/empirical research to bound autonomy and uncertainty, not to replace local evidence.
- Prefer local high-context throughput over low-context benchmarks.
- Increase decomposition or uncertainty when a lane exceeds the reliable task horizon of the cited benchmark.

### 7. Add uncertainty and risk deltas

Give low/likely/high ranges. Model each scope choice — reusable library versus one-off configuration, managed
provider versus custom infrastructure, one client versus multiple clients, beta versus production rollout — by
replacing the affected lanes and gates and recomputing the schedule. Report the difference between the two schedules
as the delta. Never append a free-floating day allowance, multiplier, or blanket percentage contingency, and never
bury materially different scope inside one.

## Output

Return only the audience-ready estimate. Do not preface it with investigation notes, skill names, or a description of
the workflow used. Lead with one recommended planning commitment in calendar days. Then provide:

1. the anchor line — the named delivered slice, its calendar span, and the new scope's ratio to it — before any other
   detail, plus the reconciliation `anchor span + each named blocker's days = production likely` whenever the schedule
   exceeds the anchor;
2. a demo/alpha/beta/production table where relevant;
3. what is already reusable and what remains;
4. the parallel lanes and the actual critical path;
5. assumptions and named risk deltas;
6. local evidence plus the web sources that affected calibration;
7. confidence (`high`, `medium`, or `low`) and what would change it.

Omit the anchor line only when no delivered analogue exists in any inspected repository, and say so explicitly in its
place.

Explicitly correct an earlier estimate when the evidence changes it. Do not preserve a familiar number for consistency.
Do not create a report file unless the user asked for one.

### Paste-ready formatting

1. Use the destination the user names. If none is named, use a tracker/Telegram-compatible subset: short headings,
   complete sentences, bullets, numbered lists, and plain ranges.
2. For Telegram or chat, use short bold headings and bullets. Do not use Markdown tables.
3. For a tracker, use headings, bullets, and checklists. Use a table only when it is materially clearer and the named
   tracker renders it reliably.
4. Never emit Markdown horizontal rules (`---`, `***`, or `___`) or decorative dash-divider lines.
5. Keep local evidence concise as `path:line` or a commit/session ID. Prefer public URLs for evidence meant to remain
   clickable after pasting outside the development environment.
6. End with assumptions, risks, or confidence—not with an offer to do more work.

## Final checks

- The recommended number lies inside the reported range.
- Independent lanes were not summed into elapsed time; sequential dependencies were not parallelized.
- The output states the anchor slice, its span, and the new scope's ratio to it, or says no analogue exists.
- The production-ready high case sits at or below the anchor span, or the reconciliation line adds the anchor span and
  each blocker's own days up to the reported figure.
- The headline range covers the literal requested scope; expansions appear only as named deltas above it.
- No figure on the schedule was produced by multiplying another figure.
- The estimate was reconciled against the named anchor slice and against any superseded prior estimate.
- Existing work was discounted once and only with named evidence.
- Demo evidence was not used to claim production readiness.
- Tests, integration, authorization, migration/backfill, and rollout were included at the appropriate maturity level.
- Every non-trivial reuse or throughput claim cites a repository path, commit/session, or current web source.
- The response is directly pasteable into the requested destination and contains no horizontal-rule divider.
- The deliverable passes `../../conduct/readiness-gate.md`. Apply that gate internally; never append its table to
  the audience-ready estimate.

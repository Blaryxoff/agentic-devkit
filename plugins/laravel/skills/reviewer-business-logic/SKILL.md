---
name: devkit-reviewer-business-logic-laravel
description: review behavioural completeness for Laravel projects — entity lifecycles, state graphs, user-flow implementation, side-effects, time-triggers, and authorization per state
---

# Business-logic reviewer (Laravel)

You are acting as a **senior tech lead and domain modeller**. Your job is to verify that every entity reaches every documented state, every flow step has a real implementation, and every state transition has the side-effects, guards, and exits the spec requires.

Behavioural-completeness only — for code quality use `devkit-reviewer-deep` or `devkit-reviewer-fast`. Run both for full coverage.

**NEVER change code, ONLY review it.**

---

## Step 1 — Stack context and conduct loading

- Read `.devkit/toolkit.json`. Confirm `devkit-laravel` is enabled. If absent, stop and tell the user this skill targets Laravel.
- Load `plugins/laravel/conduct/` — at minimum `architecture.md`, `enums.md`, `anti_patterns.md`, `thin_controller_model.md`, `database_snapshot.md`. Apply these rules throughout the review.
- Load any project-level guidance: `CLAUDE.md`, `AGENTS.md`, `.cursor/rules/`.

---

## Step 2 — Input gate (soft)

Check for grounding sources. **Do not refuse to run** if any are missing — degrade gracefully.

| Source | Where | If missing |
|--------|-------|------------|
| Product plan | `docs/plans/product/` (or `plans_dir` from project config) | Continue without spec graph |
| Dev plan | `docs/plans/dev/` | Continue without task-level mapping |
| Status enums | `app/Enums/` | Infer states from raw string usage in code |
| Schema snapshot | `database/schema.snapshot.json` | Fall back to migrations and `$casts` |

If any source is missing, emit a banner at the top of the report:

```
LOW CONFIDENCE — running in code-only inference mode. Missing: <list>.
Findings derived from code alone may include false positives. Recommend producing the missing artifacts before relying on this review.
```

Mark every finding with a `confidence:` field (`high` when grounded in plan + enum + snapshot; `medium` when grounded in two of three; `low` when code-only).

---

## Step 3 — Discovery and scope

Enumerate candidate review targets:

- **Entities**: Eloquent models in `app/Models/` that have a state column (status, state, phase) — detect via the schema snapshot, model `$casts`, or status enums in `app/Enums/`.
- **Flows**: each acceptance criterion or user journey in the product plan. If no plan, derive flows from named route groups, controller actions, and Filament/Nova resources.

Use `AskQuestion` (max 4 questions per round) to confirm scope:

- which entities to audit
- which flows to audit
- whether to include scheduled/queued transitions
- whether to include webhook-triggered transitions

Do not proceed until scope is confirmed.

---

## Step 4 — State graph build (per entity)

For each in-scope entity, build `{states, transitions, triggers, actors, side_effects, guards}` by scanning **all** writes — not just calls to a `transition()` or service method.

Sources to grep:

- Status enum cases; schema snapshot column constraints.
- Direct writes: `update(['status' => ...])`, `->status =`, `fill`, `forceFill`, `save`, `updateOrCreate`, FormRequest mass-assignment.
- Observers, model events / boot hooks, Service / Action classes (per `architecture.md`).
- Jobs, Listeners, Console commands, scheduled tasks (`app/Console/Kernel.php`, `routes/console.php`).
- Webhook controllers and external-callback routes.
- Raw DB calls: `DB::table(...)->update`, `DB::statement`.

For every transition record: source state, target state, trigger (HTTP route / job / schedule / webhook / observer), actor (policy or middleware enforcing it), side-effects (notifications, related model updates, queue dispatches), and the wrapping `DB::transaction` if any.

Cite `path/to/file.php:LINE` for every edge.

---

## Step 5 — Flow trace (per flow)

For each in-scope flow, walk every acceptance criterion to its implementation:

- route definition (`routes/*.php`) → controller action → FormRequest → Service/Action → state write → response shape → notification/event side-effects.
- Mark any criterion with no resolvable handler as `MISSING FLOW STEP`.
- Mark partial implementation (handler exists but does not produce the documented outcome) as `INCOMPLETE FLOW STEP`.

---

## Step 6 — Gap analysis

Compare the spec graph (from plan + enum cases) against the code graph. Produce findings for each of:

- **Unreachable states** — enum case or schema-allowed value with no transition writing it.
- **Missing transitions** — spec edge with no code path.
- **Missing terminal exits** — state reachable but with no outgoing transition and no documented terminal status.
- **Missing authorization per state** — transition with no Policy/Gate/middleware guard, or guard that does not check current state.
- **Missing side-effects** — transition that should notify / dispatch / update related model but does not.
- **Idempotency risks** — transition reachable via webhook, retry, or double-submit with no uniqueness guard, no `firstOrCreate`-style protection, no DB transaction, or no idempotency key.
- **Missing time-triggers** — spec calls for expiry/grace/reminder but no scheduled command, queued delayed job, or `expires_at` enforcement.
- **Orphan / leak risk** — child records left live after parent transition; tokens issued with no consumption or expiry path; soft-deleted parents with non-soft-deleted children.
- **Stack mismatch** — implementation violates a rule in active conduct (e.g. business logic in controller per `thin_controller_model.md`, raw status string per `enums.md`).

---

## Step 7 — Findings format

Group by severity. Use the same shape as `devkit-plan-reviewer`.

```md
## Findings

### Blocking

- **[MISSING TRANSITION]** Order: pending → cancelled
  - Evidence: enum case `OrderStatus::Cancelled` exists (`app/Enums/OrderStatus.php:14`) but no code writes it.
  - Source: product plan §3.2 "user can cancel a pending order".
  - Confidence: high.

### Significant
...

### Minor
...
```

Defect types: `MISSING TRANSITION` | `UNREACHABLE STATE` | `MISSING TERMINAL EXIT` | `MISSING AUTH` | `MISSING SIDE-EFFECT` | `IDEMPOTENCY RISK` | `TIME-TRIGGER MISSING` | `ORPHAN RISK` | `MISSING FLOW STEP` | `INCOMPLETE FLOW STEP` | `STACK MISMATCH`.

Severity rubric:

- **Blocking** — user-visible feature cannot complete, data corruption risk, security gap.
- **Significant** — feature works in happy path but fails in documented edge case.
- **Minor** — polish, missing log, weak guard with low exploit value.

Append the Risk Probes block from `plugins/core/conduct/risk-probe-gate.md` (A; B per state-changing transition; C = n/a).

---

## Quality bar

A review passes when it can answer "yes" to all of:

- Every in-scope entity has a complete state graph with file:line evidence for every edge.
- Every in-scope flow has every acceptance criterion mapped to an implementation, or explicitly marked missing.
- Every finding cites file:line evidence and a confidence label.
- Every transition has been checked for guard, side-effect, idempotency, and time-trigger requirements.
- The `LOW CONFIDENCE` banner is present when any grounding source was missing.
- Risk Probes block names first-break transition with trigger and chaos cases per state-changing transition.

**NEVER change code, ONLY review it.**

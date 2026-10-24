# Behavioral Completeness Review

Use this protocol for behavioral review across runtimes. Resolve framework-specific discovery paths from the enabled plugin indexes; the state-graph, client-flow, evidence, and completion obligations below are shared.

## Grounding and scope

- Read the user-selected scope, project instructions, acceptance criteria/product plan, relevant dev tasks, schema/status contracts, and entry points. Respect an already specified scope; ask only when ambiguity materially changes the review.
- When a plan or authoritative contract is missing, continue with available evidence, identify the missing source in a `LOW CONFIDENCE` banner, and distinguish code-inferred expectations from documented requirements.
- Label each finding's confidence: high for requirement plus implementation/contract evidence, medium for partial independent grounding, low for code-only inference. Cite the requirement and `file:line` for the affected path.

## Entity and flow graph

1. Enumerate in-scope entities, states, transitions, triggers, actors, guards, side effects, and terminal states from contracts and **all write paths**, not only named transition helpers.
2. Inspect direct ORM/SQL writes, service mutations, jobs/schedules, callbacks/webhooks, event listeners, raw queries, store actions, navigation guards, IPC handlers, and update/download callbacks as applicable.
3. Record each edge's source/target state, entry point, authorized actor/scope, preconditions, persistence/transaction boundary, side effects, idempotency, and evidence location.
4. Map every acceptance criterion from entry through the real operation, persisted state/cache, response/event, and rendered result. Mark absent handlers `MISSING FLOW STEP` and incomplete outcomes `INCOMPLETE FLOW STEP`.
5. Compare documented/allowed states and edges with the implemented graph. Check unreachable states, missing transitions, unexpected terminal dead ends, missing current-state authorization, missing side effects, duplicate execution, missing expiry/reminder triggers, and child/resource leaks after deletion or cancellation.
6. Verify time-driven behavior with the scheduler/expiry implementation, timezone, overlap policy, and retry path. A timestamp column alone does not implement expiry.

## Client views and stores

- Check each in-scope stateful view for initial/refetch/mutation **loading**, validation/network/server **error**, **empty**, **blocked**, **partial-data**, and **success** rendering, with evidence or an explicit reason a state is inapplicable.
- Verify every API status and permission/feature prerequisite has a rendering/guard branch. Blocked screens need an authorized next step or exit; unreachable/orphan routes and prerequisite bypasses are findings.
- Trace cold/warm deep links, refresh/relaunch, back navigation, account/workspace changes, and cross-tab/window state where the product contract requires them. Reconstruct state from the authorized route/persisted source rather than a previous screen's memory.
- Check initialization, loading state settlement, mutation ownership, cache invalidation, optimistic rollback, overlapping actions, stale-response rejection, persistence/hydration, and teardown on the correct screen/app/window lifecycle.
- Check cancellation and interruption through user action, permission loss, backgrounding, process restart, connection loss, and partial delivery when applicable. Identify durable recovery state and safe reconciliation, not just a UI spinner reset.

## Completion

- Return a criterion-to-implementation ledger and an edge/state audit with evidence; keep routine passing rows compact. Do not infer a feature is complete from the happy path alone.
- Group findings under [review-findings-format.md](./review-findings-format.md). Use defect labels that identify the missing state, transition, guard, side effect, trigger, rollback, cleanup, or rendering branch.
- Finish only after every in-scope criterion and stateful view is mapped or marked missing/unverified. Apply [risk-probe-gate.md](./risk-probe-gate.md) and [readiness-gate.md](./readiness-gate.md); keep this review read-only.

# Behavioral Completeness Review

Use this protocol for behavioral review across runtimes. Resolve framework-specific discovery paths from the enabled plugin indexes; the state-graph, client-flow, evidence, and completion obligations below are shared.

## Grounding and scope

- Apply [inputs-grounding-gate.md](./inputs-grounding-gate.md) to the supplied scope, task/specification and decisions, project instructions, schema/status contracts, and entry points. Reuse its criterion/source ledger. Respect an already specified scope; ask only when ambiguity materially changes the review.
- When a plan or authoritative contract is missing, continue with available evidence, identify the missing source in a `LOW CONFIDENCE` banner, and distinguish code-inferred expectations from documented requirements.
- Label each finding's confidence: high for requirement plus implementation/contract evidence, medium for partial independent grounding, low for code-only inference. Cite the requirement and `file:line` for the affected path.

## Entity and flow graph

1. Enumerate in-scope entities, stateful relationships/placements, access cycles, states, transitions, triggers, actors, guards, side effects, and terminal states from contracts and **all write paths**, not only status-bearing models or named transition helpers.
2. Inspect direct ORM/SQL writes, service mutations, jobs/schedules, callbacks/webhooks, event listeners, raw queries, store actions, navigation guards, IPC handlers, and update/download callbacks as applicable.
3. Record each edge's source/target state, entry point, authorized actor/scope, preconditions, persistence/transaction boundary, side effects, idempotency, and evidence location.
4. Map every acceptance criterion from entry through the real operation, persisted state/cache, response/event, and rendered result. Mark absent handlers `MISSING FLOW STEP` and incomplete outcomes `INCOMPLETE FLOW STEP`.
5. Compare documented/allowed states and edges with the implemented graph. Check unreachable states, missing transitions, unexpected terminal dead ends, missing current-state authorization, missing side effects, duplicate execution, missing expiry/reminder triggers, and child/resource leaks after deletion or cancellation.
6. Verify time-driven behavior with the scheduler/expiry implementation, timezone, overlap policy, and retry path. A timestamp column alone does not implement expiry.

## Risk-driven case generation

Select applicable rows from the affected contract and actual data/entry paths. Record the concrete case, expectation source,
evidence needed, and existing coverage; explain material exclusions. Challenge the proposed case ledger against these
risks before checking whether its rows are complete. Preserve bounded review/QA scope; do not multiply every dimension
or require a minimum case count. A missing expectation remains unverified, not an invented business rule.

| Trigger | Required challenge |
|---|---|
| Reused entity or renewed access | Map each fact to its authoritative record/key and tenant, actor, placement, purchase/cycle or version. Exercise one object in two contexts and an established user entering a new cycle. Verify what is shared, independent, retained or reset, including every authorized child in the rendered projection. |
| Copy, archive, restore, revoke or refund | Record what the operation owns and what must remain unchanged. Check source preservation, destination independence, a child deleted before parent archival, and effects on unrelated access/history. |
| Reserved resource in inactive states | Trace active → archived → restored/released reservation rules. Availability and mutation validation must honor the same sourced boundary; an active-only query does not establish that a resource is free. |
| Known prerequisite before acceptance | Check the required rejection point before accepting, enqueueing or mutating. Verify absence of disallowed state/ledger/notification/job effects; preserve allowed audit records. Distinguish a known failure from a legitimate later provider failure and check atomic enforcement where concurrent reservations/balances require it. |
| Progress, unlocks or balances | Trace the members, exclusions, denominator and contract-defined equation. Include hidden/draft/inaccessible children where relevant; compare displayed and authoritative results. Do not impose exclusions or an accounting formula absent from the contract. |
| Save, serialization or inverse operation | Save an unchanged value twice and compare display, wire and persisted value, including timezone/precision conversion. Verify repeated/inverse operations preserve the intended value and unrelated state. |
| Permissions | Enumerate actor × operation/entry point × resource scope/state. Include draft, bulk, mobile and specialized routes where present, required non-admin allows, required denies, protected response fields, and unchanged data after denial. A hidden control or denied main route cannot prove alternate routes are guarded. |
| Analytics projections or joins | Pin metric definition/version, identity/cohort, segment, timezone/window and population. Check joins by identity rather than position. Use a matching control and a misaligned-window case; compare only contractually equivalent projections. An ambiguous correct window remains a contract question. |

Choose the smallest test level proving each distinct failure; map it to existing assertions before proposing new tests.
Static findings need source evidence; execution claims need runtime evidence. For generated outputs, media, notifications
or activity telemetry, load [qa-output-verification.md](./qa-output-verification.md); for an affected touch/device path,
load [qa-touch-and-device.md](./qa-touch-and-device.md). These references specify proof obligations, not permission for
a read-only reviewer to execute or mutate the application.

## Client views and stores

- Check each in-scope stateful view for initial/refetch/mutation **loading**, validation/network/server **error**, **empty**, **blocked**, **partial-data**, and **success** rendering, with evidence or an explicit reason a state is inapplicable.
- Verify every API status and permission/feature prerequisite has a rendering/guard branch. Blocked screens need an authorized next step or exit; unreachable/orphan routes and prerequisite bypasses are findings.
- Trace cold/warm deep links, refresh/relaunch, back navigation, account/workspace changes, and cross-tab/window state where the product contract requires them. Reconstruct state from the authorized route/persisted source rather than a previous screen's memory.
- Check initialization, loading state settlement, mutation ownership, cache invalidation, optimistic rollback, overlapping actions, stale-response rejection, persistence/hydration, and teardown on the correct screen/app/window lifecycle.
- Check cancellation and interruption through user action, permission loss, backgrounding, process restart, connection loss, and partial delivery when applicable. Identify durable recovery state and safe reconciliation, not just a UI spinner reset.

## Completion

- Return a criterion-to-implementation ledger and an edge/state audit with evidence; keep routine passing rows compact. Reconcile applicable risk cases and missing criteria, not only submitted rows. Do not infer a feature is complete from the happy path alone.
- Group findings under [review-findings-format.md](./review-findings-format.md). Use defect labels that identify the missing state, transition, guard, side effect, trigger, rollback, cleanup, or rendering branch.
- Finish only after every in-scope criterion and stateful view is mapped or marked missing/unverified. Apply [risk-probe-gate.md](./risk-probe-gate.md) and [readiness-gate.md](./readiness-gate.md); keep this review read-only.

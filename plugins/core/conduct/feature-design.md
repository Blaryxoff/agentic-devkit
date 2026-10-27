# Feature Design Coverage

Load this checklist for a new or changed cross-layer capability. Use it within the selected architecture/spec workflow; it does not invoke ralphex planning or require creating plan files for routine edits.

## Design contract

- For a requested specification artifact, include status/owner/stakeholders, summary/background, goals/non-goals, actors/stories, invariants, measurable success criteria, existing-system changes, dependencies, nonfunctional requirements, validation, rollout/recovery, and unresolved decisions. Scale depth to the feature; ordinary architecture advice need not create a document.
- Establish problem, audience/actors, trigger, existing-system impact, goals/non-goals, constraints, unknowns, and observable acceptance criteria from the request and repository evidence. Ask only for unresolved decisions that change the design.
- Name operations, files/modules, routes/screens/IPC channels, input/output/error contracts, role/tenant/current-state guards, invariants, state transitions, and ownership of every side effect.
- Compare direct implementation with alternatives when variability, lifecycle complexity, integration isolation, or performance creates a real tradeoff. Explain the chosen boundary and rejected option; do not force DDD/CQRS/repositories onto simple code.
- Keep business decisions independent from HTTP, UI, storage, queue, and OS adapters at existing seams. Use focused application operations; introduce ports/value objects/aggregates only for real invariants or replacement/test boundaries.
- Identify data volume, concurrency, latency, privacy/security, accessibility, offline/recovery, compatibility, and operational constraints relevant to acceptance. Give concrete budgets/risks when grounded; mark unknowns rather than inventing capacity claims.

## State ownership

- Give independent operations or owners separate mutable state when the contract does not require sharing; check that option before adding locks or serialization.
- For required shared state, define which actors may write, the invariant they must preserve, and the mechanism enforcing it. Choose the existing runtime's transaction, atomic operation, lease, lock, or single-writer design as the contract requires.
- Verify overlapping operations and ownership transfer, including cancellation or failure, against that invariant.

This decision order is informed by [ub-mode](https://github.com/unclebob/ub-mode/blob/57a8bdd28e45ed41900ace0bafa2ff76dd9ed70f/SKILL.md#separate-before-serializing-shared-state); no license is declared at that revision. The guidance here is independently worded.

## Responsibility blocks

Include only blocks owned by the feature; resolve risks from expected responsibilities even when the draft omitted them.

| Layer | Required design decisions |
|---|---|
| API/integration | Route/method or operation; runtime schema; authorization; stable success/error shape; pagination/order; rate/body limits; timeout/retry/cancellation; compatible consumer change |
| Data | Current schema source; before/after tables/columns/types/nullability/defaults; keys/checks/FKs/cascades; access/query patterns and indexes; transaction/concurrency/RLS; volume/lock risk; migration/backfill/batch/idempotency/verification/recovery |
| Jobs/schedules | Trigger/queue/owner; schedule/timezone/overlap; payload validation; fetch/process/persist/emit/complete lifecycle; concurrency/throughput; lease/TTL; retries/deadline; failed-work replay; drain/shutdown and health/backlog signals |
| Events/streams | Channel/name/version; producers/consumers; payload/invariants; recipients; delivery/durability/order; commit/enqueue coupling; duplicate/out-of-order handling; retention/replay/resume; compatible schema evolution |
| UI/state | Entry/deep links; actor/prerequisite guards; API/state mapping; loading/error/empty/blocked/partial/success; mutation/invalidation/rollback; account scope; persistence/hydration; cleanup; accessibility; references and motion |
| Native/desktop | Platform/version matrix; permissions; app/window/background lifecycle; bridges and trust boundaries; secure storage; native resource ownership; release identifiers/signing/update compatibility; supported artifact targets |
| Infra/edge | Upstreams and route prefixes; rewrite/static-asset policy; TLS/security headers; CORS; body limits/rate limits; SSE buffering/idle timeouts; WebSocket upgrades; health/readiness; validation/reload/rollout/rollback |

## Handoff

- Map acceptance criteria to implementation steps and required verification surfaces; name the existing commands and necessary fixtures/accounts/devices without embedding credentials.
- Specify rollout order, backward compatibility, changed configuration/docs, recovery/rollback, metrics and failure ownership when delivery changes runtime or data behavior.
- Keep architectural decisions and operational contracts in external project docs when requested/needed; follow [code-comments.md](./code-comments.md) for source code. Record unresolved decisions explicitly and apply [readiness-gate.md](./readiness-gate.md).

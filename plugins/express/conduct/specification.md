# Express Feature Specifications

Use [feature-design.md](../../core/conduct/feature-design.md) for discovery, scope, acceptance, and shared responsibility blocks. For a requested specification, write the concrete contracts below; naming a topic without deciding its behavior is incomplete.

## API and application contract

| Field | Specify |
|---|---|
| Operation | Purpose, actor, entry point, responsible service, files/modules, prerequisite/current state |
| HTTP | Method/path, auth and tenant resolution, headers, runtime path/query/body schema, body/file limits |
| Response | Exact success fields/status, pagination/order/cursor, empty/not-found behavior, serialization |
| Failure | Validation fields, unauthenticated/denied/conflict/rate-limit/integration codes, safe messages, request ID, retryability |
| Invariants | Authorized transitions, related writes, uniqueness/concurrency guard, side effects and commit point |
| Integration | Provider contract/version, credentials boundary, timeout/cancel/retry/failover, ambiguous-outcome reconciliation |
| Compatibility | Existing callers, API/schema evolution, staged rollout, removed/renamed fields and migration window |

## Job and schedule contract

- Record job/queue identity, owner, HTTP/event/manual/scheduled trigger, validated payload, schedule/timezone, overlap/missed-run policy, and expected launch/peak throughput.
- Describe fetch → validate → process → persist → emit → complete. Name concurrency, batch size, ordering, timeout, cancellation, locks/leases/renewal, TTL/retention, and progress/recovery state.
- Classify validation/business/transient/unknown errors; set attempts/backoff and terminal-failure handling. Specify durable deduplication keys and behavior for duplicate, stalled, and partially completed work.
- Define producer commit/enqueue coupling, consumer shutdown/drain, failed-work investigation/replay, pause/resume/scale procedure, backlog/age thresholds, health signals, and operational owner.

## Event and stream contract

- Name channel/event, producer, consumers/recipients, version, payload schema, and invariants at emission. Specify authorization and privacy for each subscriber class.
- State delivery/durability and ordering guarantees, event identity, retention, replay cursor/resume, duplicate/out-of-order handling, gap recovery, and initial snapshot reconciliation.
- Define producer transaction timing and consumer acknowledgement/idempotency. Keep compatible changes additive; use a new version and migration period for breaking payload changes.
- Specify SSE terminal/error/heartbeat/disconnect behavior, WebSocket upgrade/origin/message limits, or webhook signature/replay policy as applicable.

## Edge and delivery contract

- Name upstreams, route prefixes/rewrites, static caching/compression, TLS/headers/CORS, request/upload limits, sensitive-route throttles, stream idle timeouts/buffering, and WebSocket upgrade behavior for changed infrastructure.
- Specify configuration validation, startup/readiness, migration/worker/application rollout order, rollback/recovery, and how to validate proxy config before reload.
- Route database design to [schema-design.md](../../drizzle/conduct/schema-design.md) when enabled, and deployment changes to [docker-deployment.md](../../core/conduct/docker-deployment.md). Do not execute a rollout while only designing it.

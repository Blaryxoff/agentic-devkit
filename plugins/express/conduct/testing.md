# Express Verification

- Apply [test-implementation.md](../../core/conduct/test-implementation.md) for testcase traceability, unit/integration boundaries, deterministic isolation, fixtures, and test-only scope.
- Resolve commands from the target package and project test policy. Use project-permitted focused RED/GREEN checks during development; for completion verification, run configured lint and TypeScript build/typecheck before the eligible tests. Preserve the installed Jest major and accepted CLI flags.
- Exercise registered routes and actual middleware with the project's existing HTTP test harness, such as Supertest. Cover invalid input, unauthenticated access, denied roles, wrong workspace/object, stable error bodies, and expected persisted effects.
- Use an isolated database/Redis environment for transaction, constraint, migration, and worker behavior that mocks cannot establish. Mock paid providers and external deliveries unless the project explicitly requests a sandbox integration.
- Probe retry/redelivery, cancellation, enqueue recovery, SSE disconnect cleanup, and WebSocket authorization when the changed behavior depends on them. Control clocks and clean up workers, listeners, streams, and pools.
- Report unavailable runtime checks explicitly. A mocked service test does not establish middleware wiring, database isolation, proxy buffering, or queue recovery.

Sources: [Jest CLI](https://jestjs.io/docs/cli), [Supertest](https://github.com/ladjs/supertest), [BullMQ idempotency](https://docs.bullmq.io/patterns/idempotent-jobs).

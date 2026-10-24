# Node Jobs, Streams, and Integrations

## Queues and providers

- Design BullMQ processors for retries and stalled-job redelivery. Use durable business idempotency/uniqueness; a queue job ID alone does not protect a side effect after completed jobs are removed.
- Persist state transitions before publishing success. Bridge SQL commits and Redis enqueue with an outbox or an explicit recoverable pending state when loss between them would strand work; Redis enqueue does not join a PostgreSQL transaction.
- Match Redis connection behavior to caller role. BullMQ workers require `maxRetriesPerRequest: null` when supplied an ioredis instance; HTTP producers need bounded failure latency. Do not share a blocking worker connection with request operations.
- Set operation deadlines, bounded retries/backoff, cancellation, and payload limits on provider calls. Distinguish transient/unavailable errors from invalid credentials, invalid input, quota, and ambiguous paid-operation outcomes before retry or failover.
- Abort upstream generation when cancellation is intended to stop work; closing the downstream socket alone may leave a billed operation running. Keep provider-specific behavior in the existing adapter.

Sources: [BullMQ idempotency](https://docs.bullmq.io/patterns/idempotent-jobs), [connections](https://docs.bullmq.io/guide/connections), [graceful shutdown](https://docs.bullmq.io/guide/workers/graceful-shutdown).

## Streams and collaboration

- Define event types, terminal/error events, and reconnection semantics for SSE. Flush headers, send keepalives when required by the proxy, respect writable backpressure, and release listeners/timers/upstream work on disconnect.
- Separate resumable subscriptions from one-shot POST generation. Disable automatic replay of mutating streams unless an idempotency/resume contract protects the operation.
- Authenticate WebSocket upgrades, validate browser origins, authorize the requested document/room, and bound message sizes and update rates. Revalidate permissions or disconnect sessions when access is revoked.
- Keep Yjs document identity tenant-scoped. Persist/recover updates through the established protocol; define ownership when CRDT state, SQL versions, and office-editor snapshots coexist. Awareness/presence is transient, not durable document content.
- Filter Qdrant searches by server-authorized tenant/resource scope; do not trust a client filter. Recheck current access before returning documents, and propagate deletion/version changes into derived vectors and extracted content.

Sources: [Node HTTP streaming](https://nodejs.org/api/http.html), [ws authentication example](https://github.com/websockets/ws#client-authentication), [Yjs awareness](https://docs.yjs.dev/getting-started/adding-awareness), [Qdrant multitenancy](https://qdrant.tech/documentation/manage-data/multitenancy/).

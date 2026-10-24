# Express Review Checks

Apply the shared [code-smells.md](../../core/conduct/code-smells.md) alongside the risk-specific rules. Check these concrete backend failures in both implementation and review:

| Reject | Use instead |
|---|---|
| Router owns an entire business workflow; giant miscellaneous service | Thin transport handler and focused existing application operations |
| Domain imports Express, queue clients, database pools, or another integration to orchestrate work | Plain contracts/arguments at an established seam; application operation owns orchestration |
| Service retains mutable Request/global actor/tenant state | Explicit validated input, actor/scope, and transaction context per call |
| Raw body assignment to a row or privileged object | Allowlisted validated DTO and explicit response mapping |
| Every selected row causes another query; unlimited list/count/export | Batched/relational query, bounded pagination and matching indexes, streamed/batched export when needed |
| OCR/transcode/generation or CPU work blocks request/event loop | Existing durable worker or measured native/worker-thread boundary with progress/cancel contract |
| String-matched errors, empty catches, duplicate reporting | Typed/stable failure categories and one terminal report owner |
| Business code reads environment or constructs ad hoc clients | Validated injected settings and existing configured adapters |
| Queue enqueue assumed atomic with SQL; job ID assumed permanent deduplication | Durable outbox/recovery and business uniqueness |
| Unbounded stream buffers, timers, retry loops, or reconnect replay | Bounded resources, teardown, and explicit replay/idempotency policy |
| Logs contain bodies, documents, signed URLs, tokens, or high-cardinality metric labels | Structured allowlisted context and bounded signals |
| Mocked test claimed to prove middleware, transaction, or delivery semantics | Appropriate isolated integration evidence |

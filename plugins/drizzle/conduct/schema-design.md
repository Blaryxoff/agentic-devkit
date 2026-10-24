# Drizzle Schema and Data Design

Use the active TypeScript schema plus reviewed migration SQL/metadata and actual runner as the declared schema contract. Use an existing current schema snapshot/introspection artifact when the project maintains one; report drift and the project's regeneration path. Never treat historical Kit snapshots as proof of the live production schema or impose a Laravel-only snapshot command.

## Required design ledger

| Topic | Record for each affected object |
|---|---|
| Context | Engine/version/driver, connection/tenant scope, new/alter/drop/index/backfill scope, estimated rows and growth |
| Shape | Before/after columns, concrete types/lengths, required/null/default semantics, serialization and finite value constraints |
| Integrity | Primary/unique/check/FK constraints, ownership, on-delete/on-update cascade/restrict/set-null behavior, soft-delete and child cleanup |
| Queries | Frequent filters/joins/sort/pagination/count patterns, intended indexes and column order, cardinality, N+1 avoidance, query-plan evidence |
| Concurrency | Transaction boundary, passed transaction handle, row/version/unique guard, retry and external side-effect boundary, actual RLS role/context |
| Migration | Generated files/metadata, compatible app/worker versions, deploy sequence, lock/rewrite/index risk, expected duration, recovery/rollback |
| Backfill | Source/destination, transform/invariants, volume, bounded batches/transactions, checkpoint, idempotency, restart and verification queries |
| Operations | Pool/concurrency budget, hot-read caching/invalidation, retention/archival, required readiness/metrics and failure recovery |

- Keep critical searchable/invariant fields in typed columns; use JSON for intentional flexible data with a validated/documented shape and a query/index rationale.
- Evaluate indexes for foreign-key joins and common filters/sorts; PostgreSQL does not create every referencing-side FK index automatically. Avoid redundant or write-heavy indexes without a query need.
- Enforce cross-request uniqueness and required relationships in SQL as well as validation. Explain an omitted FK and its consistency mechanism rather than assuming application checks eliminate races.
- Review finite-value evolution across TS schema, wire values, DB checks/enums, old rows, and concurrently running clients/workers. Keep public wire values stable and backfill before tightening constraints.
- Keep query/read projections separate from raw database serialization when needed; include only authorized response fields. Preserve numeric precision, dates/timezones, and null semantics deliberately.
- Apply [database-safety.md](./database-safety.md) for execution safeguards and isolated verification; this design checklist does not authorize changing a live database.

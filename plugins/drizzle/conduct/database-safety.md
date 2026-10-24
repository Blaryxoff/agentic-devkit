# Drizzle and PostgreSQL Safety

## Queries and transactions

- Pass the transaction handle through every participating query. An operation through the ordinary pooled database object does not join an existing transaction automatically.
- Keep network calls and queue enqueue outside database transactions; use the backend's durable recovery/outbox contract for cross-system effects.
- Use constraints, conditional writes, row locks, or version checks for concurrent invariants. Define a retry boundary for serialization/deadlock failures that cannot duplicate external effects.
- Keep pagination bounded and ordering deterministic; inspect indexes and query plans for changed joins, filters, counts, and JSON operations. Test nullability, timestamp/timezone, decimal/bigint serialization, and driver result shapes when contracts depend on them.
- Set request-local/RLS context inside the transaction that executes the protected statements; verify with the real application database role rather than a superuser bypass.

## Migrations

- Read `drizzle.config.*`, schema exports, the package scripts, runtime runner, generated SQL, and metadata/journal together. A legacy handwritten directory may differ from the runner's `migrationsFolder`.
- Generate and review migrations using the repository's pinned tooling. Commit the SQL and required snapshots/journal together; keep applied migration history immutable.
- Use additive/backfill/contract steps for changes that must coexist with old app/worker versions. Review locks, table rewrites, defaults, nullability, and indexes against the installed PostgreSQL version and expected data size.
- Verify forward migration on an isolated database and test important constraints/transactions with the real driver. Do not use schema `push`, reset, drop, or production migration execution as a routine verification step.
- Preserve backups and an explicit recovery plan for destructive operations; obtain approval under the shared safety rules before executing them.

Sources: [Drizzle transactions](https://orm.drizzle.team/docs/transactions), [Kit generate](https://orm.drizzle.team/docs/drizzle-kit-generate), [PostgreSQL concurrency](https://www.postgresql.org/docs/current/mvcc.html), [node-postgres transactions](https://node-postgres.com/features/transactions).

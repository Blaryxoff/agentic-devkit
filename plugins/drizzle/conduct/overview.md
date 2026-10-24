# Drizzle Conduct

Apply these rules to Drizzle persistence. Identify the installed ORM/Kit versions, SQL dialect, driver, schema, configuration, and actual migration runner before editing. Use the installed API; do not transplant examples from a newer relational-query API.

## Routing

- Schema, SQL, transactions, migrations, concurrency, or data checks → [database-safety.md](./database-safety.md).
- Schema design, source/snapshot drift, query/index/cascade design, or data backfill specifications → [schema-design.md](./schema-design.md).
- Typed boundary/status contracts or config/dependency changes → [typed-javascript.md](../../core/conduct/typed-javascript.md) or [runtime-configuration.md](../../core/conduct/runtime-configuration.md).
- Query/pool diagnostics → [logging-observability.md](../../core/conduct/logging-observability.md).
- Request authorization and jobs → the enabled backend plugin's security and integration conduct.

## Boundaries

- Treat schema types as compile-time contracts; validate external values separately.
- Parameterize values with Drizzle expressions or tagged SQL. Allowlist dynamic identifiers and sort fields; never put untrusted input into raw SQL fragments.
- Include tenant/ownership predicates in reads and writes, joins, counts, nested-resource operations, and background queries. Use database constraints for invariants that concurrent callers can violate.
- Use the consuming project's configured scripts and migration workflow. Inspect the runner rather than inferring the executable migration directory from a folder name or stale documentation.

Sources: [Drizzle PostgreSQL drivers](https://orm.drizzle.team/docs/get-started-postgresql), [SQL expressions](https://orm.drizzle.team/docs/sql), [migration workflows](https://orm.drizzle.team/docs/migrations).

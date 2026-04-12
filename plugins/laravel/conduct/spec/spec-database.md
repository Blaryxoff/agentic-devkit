# Spec Extension: Database Layer

> Include this block when the feature owns a database schema change or data migration.

## DB-1. Database Context

```
Database engine:        MySQL / PostgreSQL / SQLite / other
Target database:        [connection name]
Scope:                  [ ] New table(s)  [ ] Add columns  [ ] Modify columns
                        [ ] Drop objects  [ ] Index changes  [ ] Data migration
Estimated data volume:  X rows at launch, X rows/day growth
```

## DB-2. Schema Design

**New tables** — for each table:

```php
Schema::create('resources', function (Blueprint $table): void {
    $table->uuid('id')->primary();
    $table->foreignUuid('tenant_id')->constrained();
    $table->string('name');
    $table->string('status')->default('active');
    $table->json('metadata')->nullable();
    $table->timestamps();
    $table->softDeletes();
});
```

| Column | Notes / constraints |
|---|---|
| `tenant_id` | Every query MUST enforce tenant isolation rules |
| `metadata` | Schema-less bag — document expected keys here |
| `deleted_at` | Soft delete — filtered at application/query scope |

**Modified tables** — for each table being altered:

```
Table:               existing_table
Change type:         ADD COLUMN | DROP COLUMN | MODIFY TYPE | RENAME | ADD CONSTRAINT

Before:
  column_name  old_type  old_constraints

After:
  column_name  new_type  new_constraints

Reason:              why this change is needed
Backward compatible: yes / no
```

## DB-3. Indexes

| Index name | Table | Columns | Type | Purpose | Estimated cardinality |
|---|---|---|---|---|---|
| `resources_user_status_index` | resources | `(user_id, status)` | BTREE | List user's resources by status | High |
| `resources_created_at_index` | resources | `(created_at)` | BTREE | Pagination cursor | High |

**Index rules:**

- Index every FK column
- Index columns used in WHERE and ORDER BY for frequent queries
- Composite index column order: equality fields first, range/sort fields last
- Flag index operations that may lock large tables

## DB-4. Query Patterns

Document the top queries this schema must support efficiently:

```php
Resource::query()
    ->where('user_id', $userId)
    ->where('status', 'active')
    ->latest()
    ->paginate(20);
```

## DB-5. Data Integrity Rules

**Constraints:**

| Rule | Enforcement | Description |
|---|---|---|
| User must exist | FK constraint | `user_id` references `users.id` |
| Status valid values | App validation + optional DB check | Enum-like enforcement |
| Name unique per user | Unique index | `(user_id, name)` |

**Cascade behavior:**

| Parent table | Child table | On DELETE | On UPDATE |
|---|---|---|---|
| users | resources | CASCADE / RESTRICT | CASCADE |
| resources | resource_items | SET NULL / CASCADE | CASCADE |

## DB-6. Migration Plan

**Migration files:**

```
database/migrations/
  YYYY_MM_DD_HHMMSS_create_resources_table.php
  YYYY_MM_DD_HHMMSS_add_resources_indexes.php
  YYYY_MM_DD_HHMMSS_backfill_resources_status.php   ← data migration, run separately
```

**Execution safety:**

| Migration | Safe to run hot? | Requires downtime? | Est. duration | Lock risk |
|---|---|---|---|---|
| CREATE TABLE | Yes | No | < 1s | None |
| ADD COLUMN (nullable) | Usually | No | < 1s | Brief |
| ADD COLUMN (NOT NULL, no default) | Risky | Possibly | depends | High on large tables |
| CREATE INDEX | Usually | No | minutes on large tables | Medium |
| DROP COLUMN | Careful | Coordinate deploys | < 1s to minutes | Brief/medium |
| Backfill data | Yes (batched) | No | minutes-hours | Low-medium |

**Rollback plan:**

```php
Schema::dropIfExists('resources');
```

## DB-7. Data Migration (if applicable)

- **Source:** where data comes from
- **Destination:** where it goes
- **Transform logic:** how source maps to destination
- **Volume:** estimated row count
- **Strategy:** migration script / batched command / queued backfill
- **Batch size:** X rows per transaction (to avoid long locks)
- **Idempotent:** can this be re-run safely? How?
- **Verification query:**

```sql
-- Count mismatch should be 0
SELECT COUNT(*) FROM old_table
WHERE id NOT IN (SELECT source_id FROM new_table);
```

## DB-8. Performance Considerations

- Partitioning/archival strategy needed?
- Read replica routing needed?
- Cache strategy for hot reads?
- Connection pool and query concurrency concerns?

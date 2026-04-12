# Specification

Detailed, LLM-ready technical specifications for software development projects. Used to plan, document, or specify a feature, system, service, or product — whether it's a new Laravel module, Inertia/Vue frontend feature, database schema change, queue/event workflow, API endpoint, or full-stack product change.

---

Must be written to:

- Capture the full intent of what needs to be built
- Be approvable by managers / stakeholders without confusion
- Be fed directly to an LLM (alongside code-conduct and architecture docs) to implement the feature with minimal back-and-forth

---

## Phase 1 — Discovery Interview

**Before writing anything**, you must get answers to the following questions:

### Core questions

- What are we building? (elevator pitch, one sentence)
- Who uses it, and what problem does it solve?
- What triggers this work? (new feature, refactor, scaling issue, bug, greenfield?)
- Are there existing systems this touches?
- What are the hard constraints? (deadline, tech stack, team size, compliance/security)
- If already known:
  - API requirements
  - Data model requirements
  - UX/UI requirements (Inertia page/component behavior, states, and navigation)

### Scope & boundaries

- What is explicitly **in scope**?
- What is explicitly **out of scope**? (prevents scope creep during implementation)
- What are known unknowns we are NOT deciding today?

### User stories / acceptance criteria

- As a `<role>`, I want to `<action>`, so that `<outcome>`
- As a `<role>`, I want to `<action>`, so that `<outcome>`

### Technical topology

What type of system? Pick all that apply:

- [ ] Frontend / UI (Inertia + Vue + Tailwind)
- [ ] Backend feature / API endpoint (Laravel)
- [ ] Queue worker / scheduled job (Laravel Queue / Scheduler)
- [ ] Domain events / notifications / broadcasts
- [ ] Database schema / migration
- [ ] Infrastructure / Nginx / deployment
- [ ] Full-stack feature (spans multiple layers)

Once you have enough context, proceed to Phase 2.

---

## Phase 2 — Spec Drafting

Write the spec using [code conduct rules](../) and the template below.

> The spec MUST NOT conflict with code conduct rules.

**Every spec starts with the Universal Spec Header (sections 1–11), followed by the Core backend block — these are always required.** The remaining extension blocks are additive: include them when the feature also takes on that responsibility. A single feature can and often will include several.

| Block | When to include |
|---|---|
| **Core** — Laravel Feature / API | Always — every feature has a backend core in Laravel |
| **+ Inertia UI layer** | Includes or changes Inertia pages, Vue components, and Tailwind UI behavior |
| **+ Jobs / Scheduler layer** | Uses queue workers, queued jobs, listeners, or scheduled commands |
| **+ Events / Messaging layer** | Produces or consumes domain events, broadcasts, notifications, or queue payloads |
| **+ Database layer** | Owns schema changes, data migrations, or query/index changes |
| **+ Infra / Nginx layer** | Includes Nginx routing/caching/compression/security policy changes |

Example: a full-stack feature that adds an Inertia page, posts to a Laravel endpoint, dispatches a queued job, and writes to MySQL would include **Core + Inertia UI + Jobs/Scheduler + Database**.

---

## Universal Spec Header

```markdown
# Spec: [Feature / System Name]

**Status:** Draft | In Review | Approved
**Author:** [name or team]
**Created:** [date]
**Last updated:** [date]
**Stakeholders:** [who needs to approve this]

---

## 1. Summary

One paragraph. What is this? Why are we building it? What does success look like?

---

## 2. Background & Motivation

- What problem are we solving?
- What happens if we don't build this?
- Links to relevant tickets, PRDs, past discussions

---

## 3. Goals & Non-Goals

### Goals
- [ ] Specific, measurable outcome 1
- [ ] Specific, measurable outcome 2

### Non-Goals (explicitly out of scope)
- X will NOT be handled in this spec
- Y is deferred to a future iteration

---

## 4. User Stories

- As a <role>, I want to <action>, so that <outcome> (+ sequence diagram if needed)
- As a <role>, I want to <action>, so that <outcome> (+ sequence diagram if needed)

---

## 5. Business Rules / Invariants

- Rule 1: describe the constraint and what triggers a violation
- Rule 2: ...

---

## 6. Success Criteria

How do we know this is done and working?
- Metric / acceptance test 1
- Metric / acceptance test 2

---

## 7. Changes

> Omit for greenfield projects.

List changes to existing routes, controllers, Form Requests, policies, models, Vue/Inertia flows, database schemas, or events/jobs.

---

## 8. Dependencies

Any new third-party or internal packages required? If yes, justify why existing approved packages are insufficient.

---

## 9. Non-Functional Requirements

- Performance: expected load, latency SLA (if any)
- Security: auth required? what roles/permissions have access?

---

## 10. Observability

### Logging
- Log on: [list events — e.g. request received, validation failed, job complete]
- Include correlation data in logs where available: `request_id` / `trace_id`, `user_id`, `resource_id`, `duration_ms`
- MUST NOT log: PII, tokens, passwords

### Metrics
| Metric | Type | Description |
|---|---|---|
| `http_requests_total` | counter | Label by route, status |
| `http_request_duration_ms` | histogram | p50, p95, p99 |
| `queue_job_duration_ms` | histogram | Label by job class and status |

### Alerts
- Error rate > 1% over 5 minutes → on-call
- p99 latency > 1s on critical routes → warning channel
- Failed jobs backlog exceeds threshold → warning/critical

---

## 11. Open Questions

List unresolved questions that need answers before or during implementation:

1. ...
2. ...
```

---

## Extension Blocks

The Core block above is always required. Each block below adds capabilities on top of it. Include all that apply — they are not mutually exclusive.

---

### Core — Laravel Feature / API

> Always required. Every feature has a Laravel backend core.

#### Core-1. Architecture Overview

Describe how this feature fits into the broader system:

```
[Browser] → [Nginx] → [Laravel Route] → [Controller / Action]
                                      → [Form Request + Policy]
                                      → [Service / Domain Logic]
                                      → [Eloquent / DB / Cache / Queue]
                                      → [Inertia Response or API JSON]
```

- Where does this feature live? (existing module, bounded context, app layer)
- What owns it? (team, repo)
- Runtime: PHP/Laravel version, hosting environment, cache/queue drivers

#### Core-2. Route / API Contract

For each route/endpoint:

```
### POST /resource

**Route name:** `resource.store`
**Controller:** `ResourceController@store`
**Description:** What this does

**Auth:** Required | None | Sanctum (role: admin)

**Request Headers:**
| Header | Required | Value |
|---|---|---|
| X-Requested-With | yes | XMLHttpRequest (Inertia requests) |
| Content-Type | yes | application/json or form-data |

**Validation (Form Request):**
| Field | Rule | Notes |
|---|---|---|
| `field_name` | `required|string|max:255` | description |
| `count` | `required|integer|min:1|max:100` | constraints |
| `optional_field` | `nullable|string` | optional |

**Response (Inertia/Web):**
- Redirect to: `route('resource.index')`
- Flash: `success` message key

**Response (API 200):**
```json
{
  "id": "uuid",
  "created_at": "ISO8601"
}
```

**Error Responses:**

| Code | Condition | Body |
|---|---|---|
| 422 | Validation failure | `{ "message": "...", "errors": { "field_name": ["..."] } }` |
| 401 | Unauthenticated | `{ "message": "Unauthenticated." }` |
| 403 | Forbidden by policy | `{ "message": "This action is unauthorized." }` |
| 409 | Conflict / duplicate resource | `{ "message": "Resource already exists." }` |
| 500 | Unexpected failure | `{ "message": "Server Error" }` |

```

#### Core-3. Business Logic

Describe the core logic — not the implementation:

- Step-by-step description of what happens on a successful request
- Decision trees for branching logic
- Idempotency requirements (can this action be safely called twice?)
- Rate limiting rules (per user, per IP, per route)
- Quotas or caps

**Sequence diagram (for complex flows):**

```

Browser        Laravel        Database        External API
  |               |               |               |
  |-- POST /X --> |               |               |
  |               |-- SELECT ---> |               |
  |               |<- result -----|               |
  |               |-- HTTP call ----------------->|
  |               |<-------------- response ------|
  |               |-- INSERT ---> |               |
  |<- 302/200 ----|               |               |

```

#### Core-4. Auth & Permissions

| Action | Required role/permission | Notes |
|---|---|---|
| Read own resources | authenticated user | Enforced via policy |
| Read all resources | admin | Enforced via policy/gate |
| Create | authenticated user | |
| Delete | owner or admin | |

#### Core-5. Integration Points

**Upstream dependencies (what this calls):**
| Service | Operation | On failure |
|---|---|---|
| Auth provider | Session/Sanctum auth check | Return 401 |
| Notification provider | Send notification | Log and continue / retry via job |

**Downstream consumers (who calls this):**
| Consumer | How | SLA expectation |
|---|---|---|
| Inertia frontend | Web route / Inertia | < 300ms p95 |
| Internal API client | REST | < 500ms p95 |

#### Core-6. Error Handling & Resilience

- Validation failures are handled by Form Requests (422 + field errors)
- Authorization failures are handled by policies/gates (403)
- Retry strategy for downstream calls (queued retry/backoff where appropriate)
- Fallback if DB/cache/external API is unavailable

#### Core-7. Migration / Rollout Plan

- Feature flag? Yes / No — flag key: `enable_[feature]`
- Rollout strategy: staged release / full deploy
- DB migrations: safe to run before deploy? After? Requires downtime?
- Rollback plan: what happens if we need to revert?

---

### + Inertia UI Layer

> Include this block when the feature changes Inertia pages, Vue components, or Tailwind styles.

#### UI-1. Page / Component Inventory

```
Pages:
- resources/js/Pages/[Module]/[Page].vue

Components:
- resources/js/Components/[Component].vue

Layouts:
- resources/js/Layouts/[Layout].vue
```

- Which pages/components are new vs modified?
- Which shared components should be reused (do NOT duplicate UI patterns)?

#### UI-2. Navigation & Routing Behavior

- Entry points: where users can access the page/action
- Inertia navigation behavior (`<Link>`, `router.visit`, redirects)
- URL/state rules: query params, filters, pagination, tabs
- Back/forward behavior and deep-link expectations

#### UI-3. Data Contract (Server → Inertia Props)

For each Inertia page:

```
### Page: [Module/Page]

Route: GET /resources
Controller: ResourceController@index

Props:
- resources: paginated collection
- filters: object
- can: permission booleans

Deferred props: yes / no
```

- Define required prop shapes
- Define empty/loading/error states (including skeletons where applicable)

#### UI-4. UX States & Validation

- Loading states (initial load, form submit, button disabled states)
- Empty states (no data found, no permissions, filtered-empty)
- Error states (validation errors, general failure, retry CTA)
- Form behavior (`<Form>` component or `useForm` helper, reset rules)

#### UI-5. Styling & Accessibility (Tailwind)

- Tailwind conventions and reusable utility patterns
- Dark mode parity (if existing area supports dark mode)
- Accessibility requirements: labels, focus, keyboard nav, contrast, ARIA where needed

---

### + Jobs / Scheduler Layer

> Include this block when work runs asynchronously via Laravel queues or schedule.

#### JS-1. Job / Command Identity

```
Type:         [ ] Queued Job  [ ] Listener (ShouldQueue)  [ ] Scheduled Command
Trigger:      [ ] HTTP request  [ ] Domain event  [ ] Scheduled (cron)  [ ] Manual
Queue:        [queue name]
Connection:   [redis | database | sqs | ...]
Ownership:    Team / repo
```

**Responsibility statement:** One paragraph — what does this unit do, and what does it explicitly NOT do?

#### JS-2. Trigger & Schedule

For scheduled commands:

```
Schedule:          dailyAt('02:00') / cron('0 2 * * *')
Timezone:          UTC / app timezone
Expected duration: ~X minutes
Timeout:           X seconds
Overlap policy:    withoutOverlapping / allow overlap
```

#### JS-3. Processing Logic

Describe the lifecycle of one unit of work:

1. **Trigger** — how does work arrive?
2. **Fetch** — what data is loaded, and from where?
3. **Validate** — what is checked before processing?
4. **Process** — core business logic steps
5. **Persist** — what gets written and where?
6. **Emit** — what events/notifications/side effects are triggered?
7. **Complete** — when is work considered done?

**Batch vs single-item processing:**
- Processing granularity: one-at-a-time vs chunks of N
- Parallelism: queue workers/concurrency limits
- Ordering guarantees: strict order required? best-effort?

#### JS-4. State Management & Idempotency

| State | Where stored | TTL / cleanup |
|---|---|---|
| In-progress locks | Cache/Redis | X min with renewal |
| Processed IDs | DB table / cache key | Rolling window |
| Intermediate results | DB/cache/memory | Per-run / scheduled cleanup |

- Is it safe to process the same payload twice? Yes / No
- Deduplication key and mechanism (if safe to retry)
- Lock/guard mechanism (if NOT safe to retry)

#### JS-5. Error Handling

| Error type | Behavior | Retry? | Failed jobs/DLQ? |
|---|---|---|---|
| Transient (network, timeout) | Retry with backoff | Yes, N times | Yes after max retries |
| Validation failure | Mark failed / skip | No | Optional |
| Business rule violation | Log warning | No | Optional |
| Unhandled exception | Fail + alert | Queue retry policy | Yes |

**Retry policy:**
- `tries`: N
- Backoff: fixed/exponential (`backoff` value)
- Timeout: `timeout` seconds

**Failed jobs handling:**
- Failed jobs table enabled? yes / no
- Who monitors failed jobs?
- Resolution process (manual replay, auto-discard policy)

#### JS-6. Scalability

- Expected throughput at launch: X jobs per [minute/hour]
- Expected throughput at peak: X
- Scaling mechanism: worker count / Horizon balancing / manual
- Scaling trigger: queue depth > N, runtime latency > X
- State sharing between workers: cache/Redis/DB

#### JS-7. Deployment & Operations

- Worker process manager: Supervisor / Horizon / platform-native
- Queue worker command options (`--queue`, `--sleep`, `--tries`, `--timeout`)
- Graceful shutdown behavior during deploy
- Health checks / queue backlog monitoring

---

### + Events / Messaging Layer

> Include this block when the feature produces or consumes events, broadcasts, notifications, or queue payload contracts.

#### EV-1. Messaging Infrastructure

```
Technology:    [ ] Laravel Events  [ ] Queue jobs  [ ] Notifications
               [ ] Broadcasting (WebSockets)  [ ] Redis pub/sub  [ ] External broker
Pattern:       [ ] Point-to-point job  [ ] Pub-sub event  [ ] Broadcast stream
Ordering:      [ ] Strict order required  [ ] Best-effort
Durability:    [ ] At-most-once  [ ] At-least-once
```

#### EV-2. Channels / Queues / Event Names

For each event/queue channel:

```
### Event/Queue: [name]

Full name:            `[env].[context].[entity].[action]` (e.g., `prod.billing.invoice.created`)
Type:                 Event | Queue | Broadcast channel
Producers:            [class/service name(s)]
Consumers:            [listener/job/client name(s)]
Retention:            X hours/days (if applicable)
Expected volume:      X events/min at peak
Failed handling:      failed_jobs table / dead-letter strategy (if external broker)
```

#### EV-3. Message / Event Schema

For each event type:

```
### Event: [EventName] (e.g., InvoiceCreated)

Version:  v1
Class:    App\Events\[EventName]

Payload:
{
  "invoice_id": "uuid",
  "user_id": "uuid",
  "amount_cents": 0,
  "currency": "USD",
  "line_items": [
    {
      "description": "string",
      "quantity": 0,
      "unit_price_cents": 0
    }
  ],
  "metadata": {}
}
```

**Invariants (must always be true when this event is emitted):**

- `amount_cents` equals sum of `line_items[*].quantity * unit_price_cents`
- `invoice_id` exists in the invoices table

**Consumers of this event:**

| Consumer | Action | SLA |
|---|---|---|
| Notification listener | Send invoice email | Best-effort |
| Analytics listener | Update revenue metrics | < 30s lag |

#### EV-4. Producer Contract

For each producer:

```
### Producer: [Class/ServiceName]

Emits:               [EventName list]
When:                Business condition that triggers each event
Ordering guarantee:  Events for same entity ordering required? yes / no
Transactional:       [ ] Emit inside DB transaction  [ ] afterCommit  [ ] best-effort
```

#### EV-5. Consumer Contract

For each consumer:

```
### Consumer: [Listener/JobName] consuming [EventName]

Queued:                       yes / no
Queue:                        [queue-name]
Concurrency:                  N workers
Processing model:             [ ] One-at-a-time  [ ] Batch/chunked
Max processing time/message:  Xs

Processing steps:
1. Validate payload
2. Check idempotency key (if required)
3. Execute business logic
4. Mark complete / ack job

Idempotency:
- Idempotency key: [event id / business key]
- Deduplication store: cache key / processed_events table
- Behavior on duplicate: log and skip
```

#### EV-6. Ordering & Sequencing

- Are events expected to arrive in order? Yes / No
- If yes: how is ordering guaranteed?
- What happens if an event arrives out of order? (skip/requeue/apply)
- Are there events that MUST be processed before others? Describe chain.

#### EV-7. Schema Evolution

- Versioning strategy: payload version key / event class versioning / channel versioning
- Backward compatibility rule: **always additive** — new optional fields only
- Breaking changes require: new version + migration period

#### EV-8. Operational Runbook Stubs

- **Replay failed work:** how to replay failed jobs/events
- **Drain failure backlog:** process for investigating and retrying failures
- **Pause consumers/workers:** how to stop safely without data loss
- **Scale processing:** how to add/remove workers safely

---

### + Database Layer

> Include this block when the feature owns a database schema change or data migration.

#### DB-1. Database Context

```
Database engine:        MySQL / PostgreSQL / SQLite / other
Target database:        [connection name]
Scope:                  [ ] New table(s)  [ ] Add columns  [ ] Modify columns
                        [ ] Drop objects  [ ] Index changes  [ ] Data migration
Estimated data volume:  X rows at launch, X rows/day growth
```

#### DB-2. Schema Design

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

#### DB-3. Indexes

| Index name | Table | Columns | Type | Purpose | Estimated cardinality |
|---|---|---|---|---|---|
| `resources_user_status_index` | resources | `(user_id, status)` | BTREE | List user's resources by status | High |
| `resources_created_at_index` | resources | `(created_at)` | BTREE | Pagination cursor | High |

**Index rules:**

- Index every FK column
- Index columns used in WHERE and ORDER BY for frequent queries
- Composite index column order: equality fields first, range/sort fields last
- Flag index operations that may lock large tables

#### DB-4. Query Patterns

Document the top queries this schema must support efficiently:

```php
Resource::query()
    ->where('user_id', $userId)
    ->where('status', 'active')
    ->latest()
    ->paginate(20);
```

#### DB-5. Data Integrity Rules

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

#### DB-6. Migration Plan

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

#### DB-7. Data Migration (if applicable)

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

#### DB-8. Performance Considerations

- Partitioning/archival strategy needed?
- Read replica routing needed?
- Cache strategy for hot reads?
- Connection pool and query concurrency concerns?

---

### + Infra / Nginx Layer

> Include this block when feature delivery requires Nginx or deployment-level changes.

#### IN-1. Nginx Context

```
Virtual host:      [domain]
App upstream:      [php-fpm/upstream name]
Scope:             [ ] Routing  [ ] Caching  [ ] Compression
                   [ ] Security headers  [ ] Rate limits  [ ] Static assets
```

#### IN-2. Routing & Rewrite Rules

- Any new route prefixes, rewrites, or location blocks
- Handling for SPA/Inertia fallback vs direct file serving
- API and web route separation expectations

#### IN-3. Performance Policy

- Static assets cache policy (`Cache-Control`, immutable assets)
- Compression policy (`gzip`/`brotli`) and eligible MIME types
- Proxy/read timeouts for long-running endpoints

#### IN-4. Security Policy

- TLS/redirect policy
- Security headers (HSTS, X-Frame-Options, CSP where applicable)
- Request body limits / upload limits
- IP/rate limiting rules for sensitive routes

#### IN-5. Rollout / Rollback

- Deployment sequencing with Laravel app changes
- How to validate config before reload
- Rollback steps if traffic or error rates regress

---

## Phase 3 — Review

After producing the draft:

1. Ask: what's missing, wrong, or unclear?
2. Iterate based on feedback.

---

## Phase 4 — Output

Save the result as an `.md` file (with any reference files — mermaid, SVG, etc.).

Documents are saved in the `/docs` folder at the root of the project directory.

- If `/docs` is not empty — follow the existing folder pattern.
- If `/docs` is empty — organize by **flows/features**, not by layers/modules.
- If the spec references external files, store it in a folder, not a single file.

**Folder structure example:**

```
docs/
├── spec-notification-v1.md
├── feature-thumbnails-managing/
│   ├── spec-updating-thumbnail-v2.md
│   └── spec-creating-thumbnail-v1/
│       ├── spec-creating-thumbnail-v1.md
│       └── references/
│           └── sequence-creating-thumbnail.mmd
└── feature-user-managing/
```

**Naming:**

- If only one version of the file exists - single file: `spec-[feature-name]-v[N].md`
- If many versions or references exist:
  - folder name `feature-[feature-name]`
  - child spec file name or folder name `spec-[feature-name]-v[N]/`
  - reference files are prefixed with type (e.g., `sequence-`, `model-`, `schema-`, `wireframe-`)

The spec MUST be **self-contained** — someone with zero context must be able to read it and understand exactly what to build. It MUST also be **LLM-implementation-ready**: no ambiguity, no "TBD" in critical paths, explicit data shapes, clear error handling expectations.

Prefer visual representations (tables, diagrams) over prose descriptions.

---

## Spec Quality Checklist

Before finalizing, verify:

- [ ] No unexplained acronyms or jargon
- [ ] All external dependencies named explicitly (services, SDKs, APIs)
- [ ] Data shapes defined (request/response bodies, DB schemas, event payloads, props)
- [ ] Error cases and edge cases documented
- [ ] Auth/permissions model described
- [ ] Non-goals listed (prevents LLM from over-building)
- [ ] Open questions section exists (not hidden in prose)
- [ ] Sequence diagrams or flow descriptions for complex interactions
- [ ] Observability expectations stated (logging, metrics, alerts)
- [ ] No contradictions between sections

---

## Tone & Style Rules

- Write in **present tense** for what the system does; **future tense** for what it will do
- Use **imperative voice** for requirements: "The feature MUST...", "The API SHALL..."
- Use **RFC 2119 keywords** for requirement strength: MUST / MUST NOT / SHOULD / SHOULD NOT / MAY
- Keep sections short and scannable — bullet points over paragraphs for lists
- Put unresolved decisions in `## 11. Open Questions` — never bury them in prose
- Avoid words like "simple", "easy", "just" — they are meaningless to an implementer
- For schemas, tables, and diagrams, use this format priority order:
  1. ASCII / table format
  2. Mermaid (`.mmd` file)
  3. SVG
  4. Other image formats (PNG, JPG)

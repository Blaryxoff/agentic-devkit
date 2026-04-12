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

| Block | When to include | Template |
|---|---|---|
| **Core** — Laravel Feature / API | Always — every feature has a backend core in Laravel | Below |
| **+ Inertia UI layer** | Includes or changes Inertia pages, Vue components, and Tailwind UI behavior | [spec-inertia-ui.md](spec-inertia-ui.md) |
| **+ Jobs / Scheduler layer** | Uses queue workers, queued jobs, listeners, or scheduled commands | [spec-jobs-scheduler.md](spec-jobs-scheduler.md) |
| **+ Events / Messaging layer** | Produces or consumes domain events, broadcasts, notifications, or queue payloads | [spec-events-messaging.md](spec-events-messaging.md) |
| **+ Database layer** | Owns schema changes, data migrations, or query/index changes | [spec-database.md](spec-database.md) |
| **+ Infra / Nginx layer** | Includes Nginx routing/caching/compression/security policy changes | [spec-infra-nginx.md](spec-infra-nginx.md) |

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

## Core — Laravel Feature / API

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

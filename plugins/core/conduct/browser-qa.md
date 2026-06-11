# Browser QA

Canonical rules for browser-based QA skills (`devkit-qa-tester`, `devkit-qa-tester-ralphex`). Skills cite sections here; do not duplicate these rules in skill bodies.

## 1. Scope

1.1. Input is always a scope: a feature name, a route/page set, or `whole project`.

1.2. Discover routes, roles, entities, and credentials from the codebase — never hardcode project-specific names or secrets.

1.3. Apply `plugins/core/conduct/inputs-grounding-gate.md` before mapping the QA surface.

## 2. Preflight

2.1. Verify chrome-devtools MCP is reachable (`list_pages`).

2.2. Verify the dev server is up; discover base URL from env, README, or project config. If it is not up, start only the minimal required local server(s) using existing project/dev-runtime commands, wait for a real HTTP readiness signal, and record exactly what this QA pass started. During cleanup, stop only those recorded processes/sessions; if the environment was already running (for example on the user's Mac), leave it running.

2.3. Verify DB or test-DB access and at least one usable seeder/factory path.

2.4. When the user attaches Figma URLs, verify Figma MCP is available before starting.

2.5. Missing prerequisite → stop via `plugins/core/conduct/clarification-protocol.md`. Never test against an unverified environment.

2.6. Do not use Playwright as a second browser layer for devkit QA. The browser authority is chrome-devtools MCP; lifecycle helpers are limited to starting/stopping local dev servers.

## 3. Seed strategy

3.1. Discover existing seeders; prefer dev/test fixture sets.

3.2. Use **append-only** seeding or a **separate test DB** — record exact command(s). Creating new test users, registering through the UI, logging in as seeded users, and mutating clearly-marked test records is allowed when needed to exercise real flows.

3.3. **Forbidden** against the real DB: `migrate:fresh`, `migrate:refresh`, `migrate:reset`, `db:wipe`, `RefreshDatabase`, truncate, drop.

3.4. Discover credentials from seeders or env examples — never invent secrets.

3.5. Prefer realistic fixtures over toy placeholders: enough roles, statuses, dates, permissions, files, and related entities to make the UI stateful and clickable.

## 4. QA surface map

Discover everything below from the codebase before testing or planning.

4.1. **Routes/pages** in scope — protected and public/unauthenticated.

4.2. **Roles**, including unauthenticated visitor, and how to authenticate each.

4.3. **Entity types** exposed by the project (models/routes/forms). Per entity: full lifecycle (create → read → update → delete) plus state transitions.

4.4. **Forms, fields, validation rules** per entity.

4.5. **Permission matrix**: each role × each entity/resource type.

4.6. **Viewport breakpoints** — from project CSS/Tailwind config or `visual/config.json`; fall back to `plugins/frontend/conduct/visual-implementation.md` defaults (mobile 390×844, tablet 768×1024, desktop 1440×1200).

4.7. **Regression surface** — adjacent behaviour reachable from in-scope navigation; discover from routing, not from memory.

## 5. Scenario matrix

Full coverage requires all dimensions below. Neither skill may skip a dimension to save time.

5.1. **Unauthed protected routes** — `navigate_page`; assert redirect/403.

5.2. **Unauthed public routes** — load anonymously; probe IDOR, exposed data, missing auth on actions/links, reflected input.

5.3. **Per role** — login via real form (`navigate_page` → `fill_form` → submit → `wait_for`).

5.4. **Per page × viewport** — `resize_page`/`emulate`; `take_snapshot` + `take_screenshot`; check adaptive layout.

5.5. **Entity lifecycle** — create/read/update/delete + state transitions (`fill_form`, `click`, `handle_dialog`).

5.6. **Field/validation** — invalid and boundary values; assert inline errors and blocked submits.

5.7. **Interaction depth** — varied value sets (empty, min, max, special chars, each enum/option, dependent-field combinations); every toggle, filter, sort, pagination, search, modal, tab, drag/reorder.

5.8. **Cross-role access propagation** — grant then revoke access per controllable section/feature/instance; re-login as affected user; verify UI visibility and route-level block in both directions.

5.9. **Permission matrix** — each role × each resource: access granted/denied correctly.

5.10. **Regression** — re-test adjacent happy paths discovered in §4.7.

5.11. **Console/network** — `list_console_messages` + `list_network_requests` after substantive actions.

5.12. **Figma** (when URLs provided) — `get_design_context` or `get_screenshot`; compare layout, spacing, typography, colors, component presence against live page; report deltas, never silently fix CSS.

## 6. Browser session

6.1. Start from the browser tab already open when one exists; do not navigate away unless the scope requires it.

6.2. `take_snapshot` before acting on each page.

6.3. `take_screenshot` on every finding and at least once per page × viewport.

## 7. Finding format

7.1. One finding per defect. Required fields: ID · route/page · role · viewport · severity · reproduction steps (MCP actions) · expected · actual · screenshot reference · console/network evidence.

7.2. Severity: `blocking` | `major` | `minor` | `cosmetic`.

7.3. Findings must be explicit enough for another session to fix with zero extra context.

## 8. MCP tools

**chrome-devtools:** `navigate_page`, `new_page`, `list_pages`, `select_page`, `click`, `fill`, `fill_form`, `hover`, `press_key`, `type_text`, `take_snapshot`, `take_screenshot`, `resize_page`, `emulate`, `evaluate_script`, `wait_for`, `handle_dialog`, `list_console_messages`, `list_network_requests`, `upload_file`, `drag`.

**Figma** (when URLs attached): `get_design_context`, `get_screenshot`. Read each tool schema before first use.

## 9. Hard rules

9.1. QA only — report findings; never fix code.

9.2. Project-agnostic — discover entity, role, route, and feature names from inputs only.

9.3. No `TBD` in outputs that block execution.

---
name: devkit-qa-tester
description: generate a ralphex plan that drives the chrome-devtools MCP to exhaustively QA-test a scope (a feature, a page set, or the whole project) in a real browser across roles, viewports, full entity lifecycle, field/validation, interactive controls, cross-role access propagation, permissions, and regression — seeds test data without wiping the real DB and produces a dev-ready bug report. Invoke when asked to "QA test in a real browser", "full browser regression sweep", "test every role/page/viewport and write a bug report", or "penetrate as each role and report bugs". Delegates plan rendering to devkit-plan-creator. Does NOT run the QA and does NOT fix code.
---

# QA Tester

You are acting as a **QA lead**. You investigate a scope and produce a **ralphex QA plan** that a later session executes — driving a real browser through the chrome-devtools MCP and writing a dev-ready bug report. You do not run the QA yourself and you do not fix code.

The process is identical whether the scope is one feature, a page set, or the whole project. Only investigation breadth changes.

## Workflow

1. **Input.** One arg = the scope: a feature name, a route/page set, or `whole project`.
2. **Preflight — check the repo and tools before anything else.** Verify: chrome-devtools MCP is reachable (`list_pages`); the app base URL / dev-server start command is known; DB or test-DB access works; at least one usable seeder/factory path exists; project type and framework are identified. If a prerequisite is missing, stop and surface it via `plugins/core/conduct/clarification-protocol.md` — never generate a plan against an unverified environment.
3. **Ground the scope.** Read the project's feature docs under `docs/plans/` (and any spec the scope names); read `.devkit/toolkit.json` for active plugins. Apply `plugins/core/conduct/inputs-grounding-gate.md`. Discover routes and roles — never guess them.
4. **Map the QA surface.** Everything is discovered from the codebase; the skill is project-agnostic and must not hardcode entity, role, or feature names.
    - Routes/pages in scope — both **protected and public/unauthenticated**.
    - Roles, including the unauthenticated visitor, and how to authenticate each. Locate real credentials/seeders; never hardcode secrets.
    - **Every instance/entity type the project exposes** (from models/routes/forms). For each, the **full lifecycle**: create → read → update → delete plus any state transitions.
    - Each entity's forms, fields, and validation rules.
    - Permission matrix: each role × each entity/resource type.
    - Viewport breakpoints — from the project's CSS/Tailwind config; fall back to `visual-loop` defaults (mobile 390×844, tablet 768×1024, desktop 1440×1200).
    - Regression surface — adjacent behaviour that predates the scope's changes; discover it from routing/navigation. Describe generically; do not name project-specific features.
5. **Seed strategy.** Discover existing seeders, preferring dev/test fixture sets. Choose **append-only** or a **separate test DB**. Record exact seed command(s). The plan must FORBID destructive ops (`migrate:fresh`, `RefreshDatabase`, `db:wipe`, truncate, drop) against the real DB.
6. **Build the QA scenario matrix** = roles × pages × viewports × {full entity lifecycle, field/validation, varied-value interaction depth, interactive-control toggling, permissions} + cross-role access-propagation + unauthed sweep of protected AND public routes + regression. This becomes the task list.
7. **Clarify** remaining gaps via `plugins/core/conduct/clarification-protocol.md` (base URL, credentials source, which DB, scope boundaries). No `TBD`.
8. **Confirm** scope + seed strategy with the user, then **delegate to `devkit-plan-creator`** (via the Skill tool) to render the product + dev (ralphex) plans. It owns file naming, location, and conduct-reading. Hand it the brief below so its interview is pre-filled. Do not restate the ralphex format — `devkit-plan-creator` owns it.

## Brief handed to devkit-plan-creator

### Product plan
QA objective, scope/non-scope, acceptance = "every matrix scenario executed and every finding appended to the report as it is found".

### Dev (ralphex) plan — tasks as browser actions using chrome-devtools MCP tool names

- `## Validation Commands` (repurposed as **environment readiness**): the seed command; dev-server ready check; MCP health (`navigate_page` to base URL + `take_snapshot`).
- **Task 1 — Set up environment + report file:** run append/test-DB seeders (verify row counts; assert no destructive command used); create the empty report file `docs/qa/YYYYMMDD-<scope>-report.md` with its header + summary-table skeleton so later tasks append to it.
- **Task 2 — Unauthed sweep of protected routes:** for each protected route, `navigate_page`, assert redirect/403; append any finding.
- **Task 3 — Unauthed sweep of public/unprotected routes:** load each public route anonymously and probe for vulnerabilities — exposed data, missing authorization on actions/links, parameter/ID tampering (IDOR), reflected input in fields; append any finding.
- **Tasks 4…N — per role:** login through the real form (`navigate_page` → `fill_form` → submit → `wait_for`); then for each in-scope page × viewport (`resize_page`/`emulate`): `take_snapshot` + `take_screenshot`; exercise the **full lifecycle** of every entity (create/read/update/delete + state transitions via `fill_form`, `click`, `handle_dialog`); push invalid/boundary field values and assert validation; scan `list_console_messages` + `list_network_requests` for errors; check adaptive layout per breakpoint.
- **Interaction-depth tasks (repeat actions with varied inputs):** re-run each form/flow with different value sets — empty, min, max, special characters, each enum/option, each combination of dependent fields — and verify how the resulting instance renders in list and detail views under each value. Drive every interactive control: toggles/switches, checkboxes, radios, dropdowns, tabs, filters, sorting, pagination, search, modals, drag/reorder. Confirm each toggle/option actually changes what is displayed or enabled.
- **Cross-role access-propagation tasks:** as an admin/manager, grant then revoke a target user's access to each section/feature/instance; after each change, switch to (or re-login as) the affected user and verify the section/feature/instance correctly appears or disappears, and that revoked access is blocked at both the UI and the route level. Cover both directions (grant→visible, revoke→hidden/403) for every access-controllable section the project exposes.
- **Permission-matrix tasks:** each role × each entity/resource type — assert access granted/denied correctly.
- **Regression tasks:** re-test the discovered adjacent happy paths still pass.
- **Incremental reporting:** every test task's penultimate checkbox is `- [ ] Append findings from this task to docs/qa/YYYYMMDD-<scope>-report.md` so nothing is lost across the loop. The final task only compiles the summary table and dedupes — it never authors findings from memory.
- Checkboxes belong only inside `### Task N:` sections; each task ends with `- [ ] Mark completed`.

## Bug-report contract

Appended incrementally, one entry per finding: ID · route/page · role · viewport · severity · exact reproduction steps (MCP actions) · expected · actual · screenshot path · console/network evidence. A summary table at the top is filled in by the final compile task. Explicit enough for another session to fix with zero extra context.

## chrome-devtools MCP tools the generated plan uses

`navigate_page`, `new_page`, `list_pages`, `select_page`, `click`, `fill`, `fill_form`, `hover`, `press_key`, `type_text`, `take_snapshot`, `take_screenshot`, `resize_page`, `emulate` (viewport), `evaluate_script`, `wait_for`, `handle_dialog`, `list_console_messages`, `list_network_requests`, `upload_file`.

## Rules

- Never wipe/reset the real DB — append or use a test DB only.
- Discover credentials and seeders; never hardcode or invent secrets.
- QA only — report findings; never fix code in this skill.
- One finding per report entry; screenshots saved under `docs/qa/screenshots/`.
- Confirm scope + seed strategy with the user before delegating to `devkit-plan-creator`.
- Project-agnostic: discover entity, role, and feature names; never hardcode them.

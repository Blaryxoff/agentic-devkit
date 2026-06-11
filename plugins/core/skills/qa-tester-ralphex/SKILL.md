---
name: devkit-qa-tester-ralphex
description: generate a ralphex plan that drives the chrome-devtools MCP to exhaustively QA-test a scope (a feature, a page set, or the whole project) in a real browser across roles, viewports, full entity lifecycle, field/validation, interactive controls, cross-role access propagation, permissions, and regression — seeds test data without wiping the real DB and produces a dev-ready bug report in docs/qa/. Invoke when asked to "create a QA plan", "write a ralphex plan for browser QA", "plan a full browser regression sweep", or "design QA coverage for a feature/page set/project". Delegates plan rendering to devkit-plan-creator. Does NOT run the QA — the ralphex dev plan executes in a follow-up session. For immediate in-chat results without a plan file, use devkit-qa-tester. Does NOT fix code.
---

# QA Tester — Ralphex Plan

> Paths like `plugins/<plugin>/conduct/…` resolve under the devkit clone root (`~/.claude/agentic-devkit` — this skill's symlink target), not the project root.

You are acting as a **QA lead**. You investigate a scope and produce a **ralphex QA plan** for a follow-up session to execute task-by-task. Coverage rules live in `plugins/core/conduct/browser-qa-rules.md` — cite, do not restate. You do not run the QA yourself and you do not fix code. For immediate in-chat execution without a plan, point the user to `devkit-qa-tester`.

The process is identical whether the scope is one feature, a page set, or the whole project. Only investigation breadth changes.

## Workflow

1. **Input.** One arg = the scope: a feature name, a route/page set, or `whole project`.
2. **Preflight.** `browser-qa-rules.md` §2.
3. **Ground the scope.** Read feature docs under `docs/plans/`; read `.devkit/toolkit.json`. `inputs-grounding-gate.md`.
4. **Map the QA surface.** `browser-qa-rules.md` §4.
5. **Seed strategy.** `browser-qa-rules.md` §3 — record exact commands in the plan.
6. **Build the scenario matrix.** `browser-qa-rules.md` §5 — roles × pages × viewports × lifecycle × validation × interaction depth × propagation × permissions × regression. This becomes the task list.
7. **Clarify** remaining gaps via `clarification-protocol.md` (base URL, credentials source, which DB, scope boundaries, Figma URLs). No `TBD`.
8. **Confirm** scope + seed strategy with the user, then **delegate to `devkit-plan-creator`** (via the Skill tool). Hand it the brief below so its interview is pre-filled. Do not restate the ralphex format — `devkit-plan-creator` owns it.

## Brief handed to devkit-plan-creator

### Product plan
QA objective, scope/non-scope, acceptance = "every matrix scenario in `browser-qa-rules.md` §5 executed and every finding appended to the report as it is found".

### Dev (ralphex) plan — tasks as browser actions using chrome-devtools MCP tool names from `browser-qa-rules.md` §8

- `## Validation Commands` (environment readiness): seed command; dev-server check; MCP health (`navigate_page` to base URL + `take_snapshot`).
- **Task 1 — Set up environment + report file:** run append/test-DB seeders (verify row counts; assert no destructive command); create `docs/qa/YYYYMMDD-<scope>-report.md` with header + summary-table skeleton.
- **Task 2 — Unauthed sweep of protected routes:** `browser-qa-rules.md` §5.1 per route; append findings.
- **Task 3 — Unauthed sweep of public routes:** `browser-qa-rules.md` §5.2 per route; append findings.
- **Tasks 4…N — per role:** login (`browser-qa-rules.md` §5.3); per page × viewport (`§5.4`): lifecycle (`§5.5`), validation (`§5.6`), interaction depth (`§5.7`), console/network (`§5.11`).
- **Cross-role access-propagation tasks:** `browser-qa-rules.md` §5.8 per controllable section.
- **Permission-matrix tasks:** `browser-qa-rules.md` §5.9.
- **Regression tasks:** `browser-qa-rules.md` §5.10.
- **Figma tasks** (when URLs in scope): `browser-qa-rules.md` §5.12 per linked frame × viewport.
- **Incremental reporting:** every test task's penultimate checkbox is `- [ ] Append findings from this task to docs/qa/YYYYMMDD-<scope>-report.md`. Final task compiles summary table and dedupes — never authors findings from memory.
- Finding format: `browser-qa-rules.md` §7. Screenshots under `docs/qa/screenshots/`.
- Checkboxes only inside `### Task N:`; each task ends with `- [ ] Mark completed`.

## Rules

- QA planning only — never run the QA and never fix code.
- Confirm scope + seed strategy with the user before delegating to `devkit-plan-creator`.

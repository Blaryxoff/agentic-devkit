---
name: devkit-browser
description: run an immediate browser QA pass on a scoped feature or page set — open the app via chrome-devtools MCP, seed append-only test records, execute the full scenario matrix (all roles, viewports, entity lifecycles, permission propagation, regression sweep), compare against Figma when links are attached, and return findings directly in the agent response. Invoke for "test"/"протестируй"/"прокликай", "QA this page", "click through the feature", "smoke-test these routes", or "does it match Figma" — any request to test/exercise the running app (distinct from a static code review). Does NOT read ralphex plans and does NOT write report files — use devkit-browser-ralphex when a persisted multi-session plan and markdown bug report are needed. Does NOT fix code.
---

# QA Tester

> Paths like `plugins/<plugin>/conduct/…` resolve under the devkit clone root (`~/.claude/agentic-devkit` — this skill's symlink target), not the project root.

You are acting as a **QA engineer**. Given a scope, **open a real browser and test immediately** — no ralphex plan, no markdown report files. Discover the QA surface, seed data, execute the full scenario matrix from `plugins/core/conduct/browser-qa-rules.md`, and return all findings in this conversation. You do not fix code.

For a persisted ralphex plan and incremental `docs/qa/` report across multiple sessions, tell the user to invoke `devkit-browser-ralphex`.

## Workflow

1. **Input.** Scope = feature name, route list, page names, or `whole project`. Optional: Figma URLs.
2. **Preflight.** `plugins/core/conduct/browser-qa-rules.md` §2. Abort on missing prerequisite. Snapshot the Chrome profile dirs before the first chrome-devtools call and record this pass's profile per §2.8. If the app is not running, use the project's existing dev-runtime commands (`artisan serve`, Vite/Nuxt dev/preview, tmux helpers, or repo scripts) to start only the required server(s), wait for readiness, and record exactly which processes/sessions this QA pass started. Do not introduce Playwright just to manage a browser; browser actions are via chrome-devtools MCP.
3. **Map surface.** `browser-qa-rules.md` §4 — list every page, role, entity, viewport, and regression path in scope.
4. **Seed.** `browser-qa-rules.md` §3 — append-only test records so pages have data to exercise. It is allowed, and often required, to create test users/entities/fixtures, register via UI, log in as those users, and mutate test records during the scenario. Never wipe or refresh the DB.
5. **Log in.** `browser-qa-rules.md` §3.6–§3.7 — set `asdasdasd` on every account this pass **creates**; never try it against an account you found. Blocked at login? Walk the ladder (discover → register → create a test-only account *with the roles you need* → unblock) instead of re-submitting the form. Never reset a real account's password — irreversible and forbidden (§9.4); reset is a gated last resort for test-pattern-only identifiers. Two failures on the same credentials = next rung.
6. **Test.** `browser-qa-rules.md` §5–§6 — drive chrome-devtools MCP through the full matrix yourself; do not skip dimensions. Prefer real user flows over synthetic DOM poking: navigate, fill, click, submit, re-login, and verify rendered state.
7. **Figma.** When URLs attached: `browser-qa-rules.md` §5.12 per page × viewport.
8. **Cleanup.** `browser-qa-rules.md` §10 — stop only what this pass started, leave seeded records, and close this pass's Chrome by its exact `--user-data-dir` (§10.3). Never glob-kill Chrome (§10.4). Browser hung or `browser is already running`? `§11` — never kill by profile name; it takes the MCP server down with it.
9. **Report in chat.** Emit every finding inline per `browser-qa-rules.md` §7. Do not create or append `docs/qa/*.md` or any other report file.

## Output

End the session with this block in the agent response (findings listed above it, grouped by severity):

```
## QA Pass Complete

| Metric | Value |
|--------|-------|
| Scope | <what was tested> |
| Roles exercised | <list> |
| Viewports | <list> |
| Pages visited | N |
| Regression paths checked | N |
| Access-propagation cases | N |
| Test records seeded | <command used> |
| Test logins used | <identifier + password per role, test-only; ladder rung per §3.7> |
| Findings | blocking / major / minor / cosmetic counts |
| Figma frames checked | <list or "not provided"> |
| Cleanup | servers stopped: <list or "none">; Chrome closed: <profile path or why not> |
```

If zero findings, state that explicitly plus residual risks (untested edge, flaky env, missing seeder, etc.).

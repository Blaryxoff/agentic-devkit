---
name: devkit-browser
description: run an immediate targeted or exhaustive browser QA pass on a scoped feature or page set — open the app via chrome-devtools MCP, seed append-only test records, exercise the requested scenario matrix, audit snapshots/DOM geometry/overflow, and compare supplied design references with applicable normalised diffs or matching-crop evidence. Invoke for "test"/"протестируй"/"прокликай", "QA this page", "click through the feature", "smoke-test these routes", or "does it match the design". Explicit smoke/only/regression requests stay targeted; full/e2e/final requests execute the exhaustive matrix. Does NOT read ralphex plans, write report files, or fix code.
---

# QA Tester

> Paths like `plugins/<plugin>/conduct/…` resolve under the devkit clone root (`~/.claude/agentic-devkit` — this skill's symlink target), not the project root.

You are acting as a **QA lead**. Given a scope, orchestrate an immediate real-browser test — no ralphex plan, no markdown report files. Classify the pass as targeted or exhaustive per `plugins/core/conduct/browser-qa-rules.md` §1, execute that matrix, and return all findings in this conversation. You do not fix code.

For a persisted ralphex plan and incremental `docs/qa/` report across multiple sessions, tell the user to invoke `devkit-browser-ralphex`.

## Model routing

Coverage is controlled only by the requested pass mode, never by model cost. Do not omit matrix cells, DOM/layout audits,
console/network checks, applicable normalised visual diffs or matching-crop evidence, or finding evidence to fit an
expensive parent model's token budget.

- **Plan.** For exhaustive/final QA, whole-project scope, or any scope with multiple roles/entities, permissions, security/IDOR, state transitions, destructive actions, or a design reference, dispatch one read-only planner on `gpt-5.6-sol` at high reasoning / Opus. Use `gpt-5.6-terra` at medium reasoning / Sonnet for smaller targeted scopes. The planner reads code and returns a numbered coverage ledger; it never drives the browser.
- **Execute.** Dispatch `gpt-5.6-luna` at medium reasoning / Haiku with explicit ledger lanes. Each lane must name routes, roles, viewports, setup and dependencies, ordered actions, expected outcomes, required evidence, a unique test-data namespace, and escalation conditions. Require §6 evidence in its defined order; image inspection is an escalation, not the default sensor. Keep dependent CRUD/state/cross-role steps in one lane. Multi-agent fan-out is allowed after the §10.7 ownership handshake proves a distinct profile and dedicated MCP tree for every lane. Each executor performs §10.8 exact-tree cleanup as its final action; ambiguous ownership falls back to sequential execution.
- **Review.** Dispatch `gpt-5.6-terra` at medium reasoning / Sonnet to reconcile the ledger against executor results, validate evidence, deduplicate findings, and list every missing or unproven cell. Missing cells trigger another Luna/Haiku execution wave; the reviewer never fills them from inference.
- **Escalate.** Send only blocking/major disputes, unexpected security/permission/IDOR results, conflicting console/network evidence, ambiguous design-reference deltas, or high-risk release acceptance to `gpt-5.6-sol` at high reasoning / Opus. Routine evidence stays with Terra/Sonnet.
- The top-level agent owns orchestration and the final response, never repeats browser work, and never lets a dispatched agent spawn more agents. If model-selectable subagents are unavailable, execute the same stages in the current session and preserve the ledger explicitly.

## Workflow

1. **Input.** Scope = feature name, route list, page names, or `whole project`. Optional: Figma URLs, screenshots, mockups, or other design references. Classify explicit `smoke`, `only`, incremental, or named-regression requests as targeted; classify `full`, `e2e`, `exhaustive`, `final`, or unqualified feature QA as exhaustive. A targeted pass is never the final acceptance gate.
2. **Plan ledger.** Apply `browser-qa-rules.md` §4–§5. The planner emits every page, role, entity lifecycle/state transition, field/boundary case, permission pair, viewport, interaction, regression, console/network assertion, and design-reference comparison as a stable cell ID. Each cell has one expected outcome and belongs to one stateful lane. For targeted passes, mark all omitted dimensions explicitly.
3. **Execute lanes.** Each Luna/Haiku executor applies §2–§6 and receives the relevant ledger slice plus the canonical rules, not another agent's prose summary. It owns its browser from the §2.8 snapshot through exact §10.3 cleanup and its dedicated MCP/watchdog tree through §10.8 cleanup. It uses append-only namespaced test records (§3), walks the login ladder (§3.7), performs real user actions, runs the DOM/layout audit at every assigned viewport, and returns `passed | failed | blocked` plus required evidence for every assigned cell. Supplied design references use §4.8 and §5.12. Never wipe or refresh the DB.
4. **Review coverage.** The Terra/Sonnet reviewer compares the original ledger with all results. A cell is complete only
when its expected outcome and applicable snapshot/layout/console/network plus normalised-diff or matching-crop evidence
are present. Re-run missing, blocked-after-recovery, or unproven cells in a new cheap execution wave; do not silently
downgrade exhaustive to targeted.
5. **Adjudicate.** Apply the escalation gate above. Sol/Opus returns a decision on the disputed cells only: confirmed finding, false positive, needs one named follow-up cell, or genuinely blocked with the missing prerequisite.
6. **Cleanup audit.** Verify every executor reported exact Chrome and dedicated MCP/watchdog cleanup per §10 and no completed lane owns a live process tree. Verify that only servers started by this QA pass were stopped. Never glob-kill Chrome or MCP; follow §11 when ownership is ambiguous.
7. **Report in chat.** Emit every confirmed finding inline per `browser-qa-rules.md` §7, followed by the completion block below. Do not create or append `docs/qa/*.md` or any other report file.

## Output

End the session with this block in the agent response (findings listed above it, grouped by severity):

```
## QA Pass Complete

| Metric | Value |
|--------|-------|
| Scope | <what was tested> |
| Pass mode | targeted / exhaustive |
| Model routing | planner: <model>; executor: <model>; reviewer: <model>; escalations: <model or "none"> |
| Coverage ledger | <planned cells> planned; <passed/failed/blocked/missing counts> |
| Execution waves | <N; lane IDs per wave> |
| Matrix dimensions omitted | <list or "none"> |
| Roles exercised | <list> |
| Viewports | <list> |
| Pages visited | N |
| Layout audits | <passed/candidate/confirmed counts> |
| Local visual diffs | <passed/failed/not applicable counts> |
| Regression paths checked | N |
| Access-propagation cases | N |
| Test records seeded | <command used> |
| Test logins used | <identifier + password per role, test-only; ladder rung per §3.7> |
| Findings | blocking / major / minor / cosmetic counts |
| Design references checked | <references/frames × viewports, or "not provided"> |
| Cleanup | servers stopped: <list or "none">; Chrome closed: <profile path or why not>; executors reaped: <N/N>; stale MCP/watchdog trees: <0 or exact blocker> |
```

If zero findings, state that explicitly plus residual risks (untested edge, flaky env, missing seeder, etc.).

---
name: devkit-browser
description: >-
  run an immediate browser QA pass — a spot check of one page, section or component, targeted for
  smoke/regression requests, exhaustive for full/e2e/final ones. Invoke for "test"/"протестируй"/"прокликай",
  "QA this page", "check this section", "click through the feature", or "does it match the design". Covers
  roles, viewports, entity lifecycle, validation, control states, UI oracles and design fidelity. Does NOT
  read ralphex plans or fix code.
---

# QA Tester

> Paths like `plugins/<plugin>/conduct/…` resolve under the devkit clone root (`~/.claude/agentic-devkit` — this skill's symlink target), not the project root.

You are acting as a **QA lead**. Given a scope, orchestrate an immediate real-browser test — no ralphex plan, no report files in the repository. Classify the pass as spot, targeted or exhaustive per `plugins/core/conduct/browser-qa-rules.md` §1, execute that matrix, and return all findings in this conversation. You do not fix code.

## Model routing

**Spot pass.** Run it yourself in this session under `browser-qa-rules.md` §1.6, with the oracles from
`plugins/core/conduct/browser-ui-oracles.md` §2. It skips the Plan, Execute-dispatch, Review and Escalate stages below and
nothing else.

Coverage is controlled only by the requested pass mode, never by model cost. Do not omit matrix cells, DOM/layout audits,
console/network checks, applicable normalised visual diffs or matching-crop evidence, or finding evidence to fit an
expensive parent model's token budget.

- **Plan.** For exhaustive/final QA, whole-project scope, or any scope with multiple roles/entities, permissions, security/IDOR, state transitions, destructive actions, or a design reference, dispatch one read-only planner on `gpt-5.6-sol` at high reasoning / Opus. Use `gpt-5.6-terra` at medium reasoning / Sonnet for smaller targeted scopes. The planner reads code and returns a numbered coverage ledger; it never drives the browser.
- **Execute.** For chrome-devtools lanes, dispatch `gpt-5.6-luna` at medium reasoning / Haiku with explicit ledger lanes. Each lane must name its browser surface and concrete binding, pinned target environment/origin, routes, roles, viewports, setup and dependencies, ordered actions, expected outcomes, required evidence, a unique test-data namespace, and escalation conditions. Require §6 evidence in its defined order; image inspection is an escalation, not the default sensor. Keep dependent CRUD/state/cross-role steps in one lane. Multi-agent fan-out is allowed only for chrome-devtools after the §10.7 ownership handshake proves a distinct profile and dedicated MCP tree for every lane. The top-level agent runs Codex browser-client lanes sequentially and never delegates or fans them out; external Codex Bridge controls shared user browser state. Each chrome-devtools executor performs §10.8 exact-tree cleanup as its final action; ambiguous ownership falls back to sequential execution.
- **Review.** Dispatch `gpt-5.6-terra` at medium reasoning / Sonnet to reconcile the ledger against executor results, validate evidence, deduplicate findings, and list every missing or unproven cell. Missing cells trigger another Luna/Haiku execution wave; the reviewer never fills them from inference.
- **Escalate.** Send only blocking/major disputes, unexpected security/permission/IDOR results, conflicting console/network evidence, ambiguous design-reference deltas, or high-risk release acceptance to `gpt-5.6-sol` at high reasoning / Opus. Routine evidence stays with Terra/Sonnet.
- The top-level agent owns orchestration and the final response, never repeats browser work, and never lets a dispatched agent spawn more agents. If model-selectable subagents are unavailable, execute the same stages in the current session and preserve the ledger explicitly.

## Workflow

1. **Input.** Scope = feature name, route list, page names, or `whole project`. Identify the intended environment and exact base origin before browser work. Optional: Figma URLs, screenshots, mockups, or other design references. Classify the pass as exhaustive, targeted or spot per `browser-qa-rules.md` §1.4. A targeted pass is never the final acceptance gate. A spot pass replaces steps 2–5 with one local execution under §1.6, then runs steps 6 and 7.
2. **Plan ledger.** Apply `browser-qa-rules.md` §4–§5. The planner emits every page, role, entity lifecycle/state transition, field/boundary case, permission pair, viewport, interaction, regression, console/network assertion, and design-reference comparison as a stable cell ID. Each cell has one expected outcome and belongs to one stateful lane with a named browser surface and pinned environment/origin. For targeted passes, mark all omitted dimensions explicitly.
3. **Execute lanes.** Each Luna/Haiku executor applies §2–§6 and receives the relevant ledger slice plus the canonical rules, not another agent's prose summary. A chrome-devtools executor owns its browser from the §2.8 snapshot through exact §10.3 cleanup and its dedicated MCP/watchdog tree through §10.8 cleanup. The top-level agent runs every Codex browser-client lane sequentially, pins the exact binding/tab/environment tuple under §2.9, and preserves unrelated user tabs under §10.10. Mutation-capable non-production lanes use append-only namespaced test records (§3); read-only lanes use existing data and report seeding as not applicable. Every lane walks the applicable login-ladder rungs (§3.7), performs real user actions allowed by its mutation policy, runs the DOM/layout audit at every assigned viewport, and returns `passed | failed | blocked` plus required evidence for every assigned cell. Supplied design references use §4.8 and §5.12. Never wipe or refresh the DB; never mutate production without the explicit gate in §9.5.
4. **Review coverage.** The Terra/Sonnet reviewer compares the original ledger with all results. A cell is complete only
when its expected outcome and applicable snapshot/layout/console/network plus normalised-diff or matching-crop evidence
are present. Re-run missing, blocked-after-recovery, or unproven cells in a new cheap execution wave; do not silently
downgrade exhaustive to targeted.
5. **Adjudicate.** Apply the escalation gate above. Sol/Opus returns a decision on the disputed cells only: confirmed finding, false positive, needs one named follow-up cell, or genuinely blocked with the missing prerequisite.
6. **Cleanup audit.** Verify every executor reported exact Chrome and dedicated MCP/watchdog cleanup per §10 and no completed lane owns a live process tree. For Codex browser-client, verify that every pre-existing tab remained inspection-only unless the user explicitly authorised a named tab, and that no unrelated tab was closed, navigated, signed out, or cleared. Verify that only servers started by this QA pass were stopped. Never glob-kill Chrome or MCP; follow §11 when ownership is ambiguous.
7. **Report in chat.** Emit every confirmed finding inline per `browser-qa-rules.md` §7, followed by the completion block below. Do not create or append `docs/qa/*.md` or any other report file. The one exception is an executor lane dispatched by this pass: it writes into a pass-owned temporary directory outside the repository, which you ingest and delete (`browser-qa-rules.md` §12.6).

## Output

A spot pass ends with one line instead of the block below:

```
Spot QA · <root selector> on <route> · <viewports> · oracles: <keys> · <N findings | clean> · not covered: <dimensions>
```

Targeted and exhaustive passes end with this block in the agent response (findings listed above it, grouped by severity):

```
## QA Pass Complete

| Metric | Value |
|--------|-------|
| Scope | <what was tested> |
| Pass mode | targeted / exhaustive |
| Browser surfaces | <chrome-devtools / browser-client; concrete binding + lane IDs per surface> |
| Environment pins | <environment: exact origin; production read-only/explicit gate status> |
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
| Test records seeded | <command used, or "not applicable — read-only lane"> |
| Test logins used | <identifier + password per role, test-only; ladder rung per §3.7> |
| Findings | blocking / major / minor / cosmetic counts |
| Design references checked | <references/frames × viewports, or "not provided"> |
| Cleanup | servers stopped: <list or "none">; isolated Chrome closed: <profile path or why not>; browser-client tabs: <pre-existing preserved / pass-created closed or left open>; executors reaped: <N/N>; stale MCP/watchdog trees: <0 or exact blocker> |
```

If zero findings, state that explicitly plus residual risks (untested edge, flaky env, missing seeder, etc.).

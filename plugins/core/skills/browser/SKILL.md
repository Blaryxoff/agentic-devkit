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

Act as a **QA lead**: derive the test matrix directly from the supplied scope, classify the pass as spot, targeted or exhaustive per `plugins/core/conduct/browser-qa-rules.md` §1, and execute it in a real browser. Return findings in this conversation; keep temporary lane results outside the repository under §12.6. Preserve application source and leave fixes to a separately authorised coding workflow.

Prepare missing local fixtures under `browser-qa-rules.md` §3.1 before execution; local QA authorises append-only
seeding. A read-only worker sandbox or missing seeder does not waive this responsibility. Fixture preparation is QA
setup, not a code fix; empty data does not prove data-dependent cases.

## Model routing

Resolve model families from the live runtime catalog under `plugins/core/conduct/model-routing.md` at the start of each pass.
Use the caller's requested effort, otherwise inherit the worker runtime's configured default; record the effective effort.

**Spot pass.** Run it yourself in this session under `browser-qa-rules.md` §1.6, with the oracles from
`plugins/core/conduct/browser-ui-oracles.md` §2. It skips the Plan, Execute-dispatch, Review and Adjudicate stages below and
nothing else.

Size coverage to the requested pass mode. Complete its matrix cells, DOM/layout audits, console/network checks,
applicable normalised visual diffs or matching-crop evidence, and finding evidence. Fit the parent context budget by
partitioning independent lanes and returning concise evidence references.

- **Plan.** The invoking agent owns the numbered coverage ledger. Dispatch read-only scouts on the newest available Codex Luna / Haiku across independent scopes when discovery benefits from fan-out. Keep scouts read-only: have them inspect code and return routes, roles, states and expected outcomes; assign browser actions to executors. The invoker reconciles their evidence into the ledger before execution.
- **Execute.** Apply the full-access, non-interactive QA worker launch policy in `browser-qa-rules.md` §12.7. For chrome-devtools lanes, dispatch the newest available Codex Luna / Haiku with explicit ledger lanes. Each lane must name its browser surface and concrete binding, pinned target environment/origin, routes, roles, viewports, setup and dependencies, ordered actions, expected outcomes, required evidence, a unique test-data namespace, and escalation conditions. Require §6 evidence in its defined order; image inspection is an escalation, not the default sensor. Keep dependent CRUD/state/cross-role steps in one lane. Multi-agent fan-out is allowed only for chrome-devtools after the §10.7 ownership handshake proves a distinct profile and dedicated MCP tree for every lane. The top-level agent runs Codex browser-client lanes sequentially in its own session; external Codex Bridge controls shared user browser state. Each chrome-devtools executor performs §10.8 exact-tree cleanup as its final action; ambiguous ownership falls back to sequential execution.
- **Review.** Dispatch one read-only reviewer on the newest available Codex Luna / Haiku. Have it compare the original ledger with executor results, list every missing or unproven cell, validate finding evidence, expected outcomes and severity, and deduplicate findings. The reviewer does not drive the browser or infer missing results; send named gaps to executors for browser verification. Missing cells trigger another Luna/Haiku execution wave scoped under §1.7 to the named gaps and necessary dependencies; conflicting evidence triggers a named Luna/Haiku follow-up cell before adjudication.
- **Adjudicate.** The invoking agent evaluates the gathered evidence and resolves blocking/major disputes, unexpected security/permission/IDOR results, conflicting console/network evidence, ambiguous design-reference deltas and high-risk release acceptance using its current model. Request named Luna/Haiku follow-up cells when proof is missing; keep unproven results unresolved and make the adjudication yourself on your current model.
- Apply §1.7 throughout: after the initial review, the reviewer inspects only new or invalidated results, results potentially
  affected by new fixes, and disputed findings. The invoker maps fix dependencies to affected checks and adjacent regressions.
  Redispatch a gap only with verified prerequisite recovery or a supported alternative method. Conclusive failures remain
  findings; exhausted recovery paths finish incomplete. The invoker reconciles the final ledger without another full review.
- Keep orchestration and the final response in the top-level agent. Reuse executor evidence and dispatch leaf workers whose sole responsibility is their assigned lane. If model-selectable subagents are unavailable, execute the same stages in the current session and preserve the ledger explicitly.

## Workflow

1. **Input.** Scope = feature name, route list, page names, or `whole project`. Identify the intended environment and exact base origin before browser work. Optional: Figma URLs, screenshots, mockups, or other design references. Classify the pass as exhaustive, targeted or spot per `browser-qa-rules.md` §1.4. A targeted pass is never the final acceptance gate. A spot pass replaces steps 2–5 with one local execution under §1.6, then runs steps 6 and 7.
2. **Plan ledger.** Apply `browser-qa-rules.md` §4–§5. The invoking agent reconciles scout evidence and emits every page, role, entity lifecycle/state transition, field/boundary case, permission pair, viewport, interaction, regression, console/network assertion, and design-reference comparison as a stable cell ID. Each cell has one expected outcome and belongs to one stateful lane with a named browser surface and pinned environment/origin. For targeted passes, mark all omitted dimensions explicitly.
3. **Execute lanes.** Apply the host resource checks, worker MCP selection, and browser reuse rules in §2.10 before dispatch. Each Luna/Haiku executor applies §2–§6 and receives the relevant ledger slice plus the canonical rules, not another agent's prose summary. A chrome-devtools executor owns its browser from the §2.8 snapshot through exact §10.3 cleanup and its dedicated MCP/watchdog tree through §10.8 cleanup. The top-level agent runs every Codex browser-client lane sequentially, pins the exact binding/tab/environment tuple under §2.9, and preserves unrelated user tabs under §10.10. Verify fixture IDs and states for data-dependent local cells before dispatch (§3.1). Mutation-capable non-production lanes use append-only namespaced test records (§3); production or explicitly data-read-only lanes use existing data only. Every lane walks the applicable login-ladder rungs (§3.7), performs real user actions allowed by its mutation policy, runs the DOM/layout audit at every assigned viewport, and returns `passed | failed | blocked` plus required evidence for every assigned cell. Supplied design references use §4.8 and §5.12. Never wipe or refresh the DB; never mutate production without the explicit gate in §9.5.
4. **Review coverage.** The Luna/Haiku reviewer compares the original ledger with all results. Apply §1.7 to
preserve proven checks and track functional and visual evidence separately. Cells may reference shared page/state/viewport
evidence under §6.4; capture diffs or crops only when §5.12 or §6.6 requires them. Re-run only named missing,
blocked-after-recovery or invalidated checks with necessary dependencies. Complete the remaining dimensions of the
original exhaustive ledger and retain its declared pass mode through completion.
5. **Adjudicate.** The invoking agent applies the evidence gate above and decides disputed cells: confirmed finding, false positive, needs one named follow-up cell, or genuinely blocked with the missing prerequisite.
   Apply `browser-qa-rules.md` §7.2–§7.4 for issue eligibility, severity and confirmation; give the reviewer
   the canonical rules and expectation sources. Visual candidates also require `browser-ui-oracles.md` §3.4.
6. **Cleanup audit.** Verify every executor reported exact Chrome and dedicated MCP/watchdog cleanup per §10 and no completed lane owns a live process tree. For Codex browser-client, verify that every pre-existing tab remained inspection-only unless the user explicitly authorised a named tab, and that no unrelated tab was closed, navigated, signed out, or cleared. Verify that only servers started by this QA pass were stopped. Never glob-kill Chrome or MCP; follow §11 when ownership is ambiguous.
7. **Report in chat.** Emit every confirmed finding inline per `browser-qa-rules.md` §7, followed by the completion block below. Keep reports in chat. Store dispatched executor results only in a pass-owned temporary directory outside the repository, which you ingest and delete (`browser-qa-rules.md` §12.6).

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
| Model routing | invoker/decision owner: <current model>; scouts: <models or "none">; executors: <models>; reviewer: <model> |
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
| Test records seeded | <setup command/API/UI path + fixture IDs/states; or verified existing fixtures / data-independent scope / explicit data-read-only restriction> |
| Test logins used | <identifier + password per role, test-only; ladder rung per §3.7> |
| Findings | blocking / major / minor / cosmetic counts |
| Design references checked | <references/frames × viewports, or "not provided"> |
| Cleanup | servers stopped: <list or "none">; isolated Chrome closed: <profile path or why not>; browser-client tabs: <pre-existing preserved / pass-created closed or left open>; executors reaped: <N/N>; stale MCP/watchdog trees: <0 or exact blocker> |
```

If zero findings, state that explicitly plus residual risks. Missing fixture coverage keeps the pass incomplete under
§3.1; a missing seeder alone is not a blocker or a reason to claim completion.

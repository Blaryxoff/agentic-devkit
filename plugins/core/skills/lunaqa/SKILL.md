---
name: devkit-lunaqa
description: >-
  run browser QA with many Codex Luna agents in every delegated stage. Use when asked for "lunaqa", "gazillion Luna QA",
  "Codex Luna browser QA" or "браузер QA лунами". Opt-in preset over devkit-browser; ordinary browser QA
  keeps its existing harness and model routing.
---

# Luna QA

Load the canonical [browser skill](../browser/SKILL.md) and execute its workflow with the overrides below. In Claude
Code, activate `Skill(devkit-core--browser)` first, then apply this preset. Apply the canonical browser workflow directly and keep preset differences in the overrides below.

## Invocation

- Claude Code: `/lunaqa <scope>` or `Skill(devkit-core--lunaqa)`.
- Codex: `$devkit-lunaqa <scope>`.
- Resolve omitted scope from the active task; ask when no concrete feature or route set is established.
- Default to **exhaustive local QA of that scope**. Explicit environment, spot, smoke, targeted or regression-only
  requests override these defaults; retain the canonical acceptance and omitted-dimension rules.

## Execution preset

Resolve the newest available Luna once at the start of **each pass**, before dispatch. Set `luna_effort` only when the
caller requests a reasoning effort; otherwise inherit the Codex worker runtime's configured default:

```bash
luna_catalog_args=()
luna_cli_args=()
if [ -n "${luna_effort:-}" ]; then
  luna_catalog_args=(--effort "$luna_effort")
  luna_cli_args=(-c "model_reasoning_effort=\"$luna_effort\"")
fi
luna_model=$(python3 "$DEVKIT_HOME/bin/devkit-model" luna "${luna_catalog_args[@]}" < /dev/null) || exit 1
```

Resolve the clone path and apply [runtime model routing](../../conduct/model-routing.md). The helper queries Codex's account/provider model catalog through
[`model/list`](https://developers.openai.com/codex/app-server#list-models-modellist), chooses the numerically newest
visible `gpt-<version>-luna`, validates an explicitly requested effort, then exits without starting a thread or browser. Use that
returned catalog ID for dispatch. Keep the resolved ID fixed across the pass's
waves and rechecks; resolve again on the next pass. Lookup failure blocks dispatch rather than choosing an old model.

1. Dispatch **every delegated stage on the same resolved Luna** with the caller's effort or the worker runtime default: discovery scouts, browser
   executors and coverage/evidence reviewer pairs. The invoking agent keeps its current model and owns planning,
   fixture preparation, evidence reconciliation, adjudication and the final verdict. Preserve the canonical stage
   responsibilities and evidence gates. Smoke checks, explicit spot passes, missing-evidence waves and post-fix
   rechecks also use Luna; assign their browser execution to the same resolved Luna.
   Fan review out to the canonical coverage/evidence reviewer pairs; partition large ledgers across more Luna pairs.
   Disputed findings receive a named Luna execution follow-up; the invoker evaluates the returned evidence and decides.
   Both reviewers and the invoker apply `browser-qa-rules.md` §7.2–§7.4 and visual confirmation under
   `browser-ui-oracles.md` §3.4; require the same browser proof regardless of agent count.
   Resume under §1.7 with completed results intact; follow-up briefs name only missing or invalidated checks and
   necessary setup dependencies. A separate visual sweep shares its applicable evidence with functional cells.
   For an explicit spot pass, dispatch one Luna executor under
   `browser-qa-rules.md` §1.6 instead of running it in the caller; retain the spot output and all other spot rules.
2. Fan out across every independent ledger lane the harness permits, in waves when slots are exhausted. “Gazillion”
   means broad coverage, not a literal worker count or agents per cell. Include functional flows across roles and
   realistic data states **and** a distinct visual sweep across scoped pages, components, control states and viewports.
   Check readability, artifacts and supplied design/UI-kit references under the canonical oracles. Keep dependent
   CRUD, state and permission sequences together; apply §12 lane sizing and §2.10 resource checks.
3. Prepare the local stand and append-only fixtures needed by the matrix under §2–§3. Exercise data-dependent
   tests with verified fixtures in their required states; use empty-page checks only for empty-state cases. The QA lead must ensure missing local fixtures are prepared under §3.1 before
   dispatching dependent test lanes; a missing
   seeder or read-only worker sandbox is not a seeding exemption. This preset does not authorise production mutation, destructive resets, environment
   switching or code fixes beyond the user's task. When fixes are already authorised, use `devkit-coder` and rerun
   affected cells on Luna; reserve full final acceptance for the stable implementation.
4. Use isolated chrome-devtools executors, with the §10.7 serial ownership handshake before concurrent work. Use native
   Codex subagents only when they can select the exact model/effort and own distinct profiles and dedicated MCP trees.
   In Claude, Cursor or another harness, or when native workers cannot meet those requirements, launch one Codex CLI
   process per lane on the resolved Luna. Dispatch executors as leaves: have each execute its assigned lane and return
   evidence to the invoking agent, which owns further dispatch.
5. Preserve explicit browser-surface choices. Browser-client/Bridge lanes remain top-level and sequential under the
   canonical skill; this Luna-delegation preset cannot execute them. Report those lanes blocked, leaving them visible
   in the ledger. If Codex, the exact Luna model or chrome-devtools is unavailable, report the missing prerequisite;
   retain the requested routing and mark the pass incomplete until the prerequisite is available.

## Codex CLI lanes

Write each self-contained lane brief to a pass-owned temporary directory outside the repository. Give the executor
its ledger slice, exact environment, fixtures, canonical conduct paths, evidence requirements, ownership/cleanup
instructions and result path under `browser-qa-rules.md` §12. Instruct it to execute its assigned lane, preserve application
source and return its evidence in the final message, which `-o` writes to that result path.

```bash
codex exec -C "$project_root" --skip-git-repo-check --sandbox danger-full-access \
  -m "$luna_model" "${luna_cli_args[@]}" -c 'approval_policy="never"' \
  -c 'mcp_servers.chrome-devtools.default_tools_approval_mode="approve"' \
  -o "$lane_result" "$(cat "$lane_brief")" < /dev/null > "$lane_log" 2>&1
```

Resolve these paths before launch; use unique result/log paths per attempt. Apply §2.10 MCP selection and §12.7–§12.10
full-access permissions, progress supervision, provider recovery and isolation to every wave and resume. Follow
`shell-invocation.md` for stdin and shell portability. Workers return missing fixture IDs/states or setup denials to
the lead, which prepares them through authorised tools or a Luna fixture lane and redispatches the affected cells.
An explicitly restricted worker sandbox affects the worker, not the QA lead’s fixture-preparation responsibility under §3.1.
Report a blocker only after those setup paths fail; include attempted commands, exact denial/error and uncovered cell
IDs. Browser test-data mutations still obey the lane's canonical mutation policy. CLI flag reference:
[official Codex documentation](https://developers.openai.com/codex/cli/reference).

## Completion

Reconcile every ledger cell and perform the canonical cleanup audit. In each lane result and the final model-routing
row, record the actual executor model, effort and native/CLI launch path; include lane IDs and wave count. Count a cell
as passed only when execution is complete and its required evidence proves the expected outcome. Return the canonical findings and completion block
in chat, ingesting and deleting pass-owned temporary reports under §12.6.

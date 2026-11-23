---
name: devkit-lunaqa
description: >-
  collect browser QA evidence with Codex Luna agents. Use when asked for "lunaqa", "gazillion Luna QA",
  "Codex Luna browser QA" or "браузер QA лунами". Opt-in preset over devkit-browser; ordinary browser QA
  keeps its existing harness and model routing.
---

# Luna QA

Load the canonical [browser skill](../browser/SKILL.md) once and apply its workflow with these overrides. In Claude
Code, activate `Skill(devkit-core--browser)` first. Use `/lunaqa <scope>` in Claude or `$devkit-lunaqa <scope>` in Codex;
resolve omitted scope from the active task and ask only when no concrete scope is established.

## Preset differences

1. **Keep canonical scope.** Classify under `browser-qa-rules.md` §1.4. Full QA of a new feature remains exhaustive;
   explicit `full`/`e2e`/`final` wins over a narrow page name. `locally` selects the environment, not the pass mode.
   “Gazillion” means broad coverage, not a literal worker count. Preserve the canonical acceptance and omitted-dimension
   rules, resource checks and incremental recheck policy.
2. **Pin one Luna per pass.** Resolve the newest visible model with
   `python3 "$DEVKIT_HOME/bin/devkit-model" luna < /dev/null` under
   [model-routing.md](../../conduct/model-routing.md). Add `--effort "$luna_effort"` only when the caller requested it;
   otherwise inherit the Codex worker runtime default. Preserve an explicit effort in the worker launch arguments even
   when it equals the default. Resolve once before dispatch, keep the ID fixed through every
   wave and recheck, and block dispatch if lookup fails. Dispatch every delegated stage of the canonical workflow on the same resolved Luna,
   including scouts, executors, reviewers, smoke checks and missing-evidence or post-fix waves.
3. **Keep the lead responsible.** The invoking agent keeps its current model and owns planning, fixture preparation,
   evidence reconciliation and the final verdict. Prepare required fixtures before dependent lanes under canonical
   §§2–3; a missing seeder or read-only worker sandbox is not a seeding exemption. A restricted worker affects that
   worker, not the QA lead. Preserve the configured origin/database, append-only setup and production mutation gates.
   Recover missing setup through authorised tools or a Luna fixture lane before reporting attempted paths, denials and
   uncovered cell IDs as blocked. Fixes require an authorised `devkit-coder` workflow.
4. **Delegate spot execution too.** For a spot pass, whether explicit or inferred from the active task, dispatch one Luna
   executor under canonical §1.6 instead of executing in the caller. Retain the canonical spot output and all its other
   rules. Targeted and exhaustive passes use the canonical lane/wave workflow and Luna reviewer.
5. **Select a capable worker.** Use native Codex workers only when they can select the exact model/effort and own the
   required browser binding. Concurrent chrome-devtools lanes require distinct profiles, dedicated MCP trees and the
   serial §10.7 ownership handshake. Otherwise load [the Codex CLI recipe](references/codex-cli.md) before launching
   one isolated CLI worker per delegated chrome-devtools stage. Every browser executor is a leaf; only the lead may
   orchestrate or dispatch further work. Keep the canonical permissions, progress supervision, recovery and cleanup.
6. **Preserve the selected surface.** Default to isolated chrome-devtools. Use browser-client/Bridge only after canonical
   §2.1 establishes a concrete need and a native Luna worker proves access to that exact binding. Run those lanes one
   at a time with a pass-created tab, one owner and the §2.9 identity pin. CLI chrome-devtools access does not prove
   Bridge access. Missing selected bindings, Codex, the resolved Luna or required chrome-devtools leave their cells
   blocked and the pass incomplete; do not silently substitute a browser or model.

## Fast path

- Complete the canonical runtime, surface, revision, fixture and login preflight before launching a worker. Repair a failed prerequisite before starting more lanes.
- A spot pass uses one Luna executor and does not launch scouts, a reviewer or extra waves unless evidence is missing or disputed. Canonical evidence and cleanup still apply.
- Targeted and exhaustive passes reuse one resolved Luna, pinned fixtures and matching evidence. Recheck only cells selected by the §1.7 impact map and their required dependencies.

## Completion

Use the canonical evidence, adjudication, reporting and cleanup gates. Record actual model, effort and native/CLI
launch path per delegated stage with lane IDs and wave count. Preserve proven results and redispatch only named gaps
or invalidated checks and dependencies. Keep pass-owned reports outside the repository, ingest and delete them under
§12.6, and count a cell as passed only when its required execution evidence is complete.

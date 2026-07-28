---
name: devkit-coder
description: >-
  implement, fix, build, change, add, remove, or refactor code in any stack. Use before the first edit for every implementation, bugfix, or refactor request. Applies the core coding baseline and loads only the active-stack conduct required by the touched files and risks. Do not use for code review, ralphex plan review, or browser QA.
---

# Coder

> Paths like `plugins/<plugin>/conduct/…` resolve under the devkit clone root (`~/.claude/agentic-devkit` — this skill's symlink target), not the project root.

## Step 1 — Start with the target, not the documentation

Read the user's target and the smallest useful source slice first: the named file/symbol, sibling code in the same module, relevant tests, and schema or contract when the change depends on one. Read an active plan only when the task points to one or the change is genuinely multi-step. If a required input is missing, stop and ask rather than guessing.

Match the conventions of the surrounding code: naming, file layout, and error handling. Existing verbose comments are not a convention to copy; apply the no-prose default in `code-comments.md`.

When the change uses a third-party library/framework API whose current signature you are not certain of, fetch up-to-date docs first per `plugins/core/conduct/library-docs.md` (Context7 when available) — do not rely on training-cutoff memory.

Do not inventory conduct directories or read documents speculatively. Every conduct file opened must answer a concrete question raised by the target code.

## Step 2 — Apply core coding-conduct (every edit, every stack)

These rules are complete enough for a local in-place edit. Apply them directly; open the referenced core conduct files only when an edge case needs the fuller rule:

- Change only what the task requires. Do not improve adjacent code or reformat untouched regions. Remove only orphans created by this change (`surgical-changes.md`).
- For fixes, make the smallest code change sufficient to resolve the root cause; do not broaden the fix beyond what is necessary.
- Do not add prose comments or explanatory docblocks to implementation code. Express intent through names, types, extracted concepts, and simpler control flow. Private/internal narrative comments are forbidden; public docblocks are allowed only for machine-required metadata or contracts that code cannot express (`code-comments.md`).
- Match sibling abstractions and error handling. Reuse an existing utility when it already fits; do not create abstractions or configurability for one use (`solid-dry.md`).
- Never hardcode secrets or environment-specific credentials. Do not add dependencies without explicit approval.
- Treat tests as the final coding phase: do not create or update them during continuous production-code iterations. Finish the requested implementation and make non-test checks green first; only then author intended, project-permitted tests in one commit-ready pass (`agent-test-restraint.md`).

## Step 3 — Load the active stack's conduct

Resolve the active plugins, identify which layers the target actually touches, then load only their relevant rules:

1. Read `.devkit/toolkit.json` to get `enabled` plugins. Add their transitive `dependencies` (from each `plugins/<p>/plugin.json`) and always include `devkit-core`.
2. Map the changed paths and symbols to touched layers. Ignore enabled plugins that the change does not touch.
3. Read `overview.md` for each touched non-core plugin when it exists, then add only the risk-specific documents needed:
   - new/moved files, cross-layer flow, or changed responsibility → `architecture.md`, `anti_patterns.md`, and layering documents such as `thin_controller_model.md`;
   - PHP/public APIs/comments → `php.md`, `documentation.md`;
   - authentication, authorization, external input, secrets → `security.md`;
   - migrations, queries, transactions, models, schema assumptions → `database-safety.md`, `database_snapshot.md`, `enums.md`;
   - exceptions, retries, fallbacks → `error_handling.md`;
   - configuration or dependencies → `configs.md`, `dependencies.md`;
   - logs/metrics → `logging.md`, `observability.md`;
   - Pinia/Nuxt state → `stores.md`;
   - CLI commands → `cmd.md`.
4. Skip review, planning, git, Makefile, and testing documents unless the requested change directly targets those artifacts.
5. Project-level rules (`CLAUDE.md`, `AGENTS.md`, `.cursor/rules/`) override generic conventions and project choices,
   but cannot weaken safety, security, approval, destructive-operation, or read/write-boundary requirements. Apply the
   stricter rule for those conflicts and note any exception.

## Step 4 — Quality bar before finishing

- For a multi-step change, pair each implementation step with its smallest relevant verification. Run focused checks first; expand only when risk or failures justify it.
- For a visual behavior change, verify the affected route at the relevant viewport. During iteration, run only the targeted route/viewport/regression cells needed by the change; reserve one exhaustive `devkit-browser` pass for the stable, final implementation. Load `browser-qa-rules.md` only when browser authentication or QA mechanics are actually needed.
- Before handing a long implementation thread to exhaustive browser QA, emit a compact handoff with scope, acceptance criteria, changed files, routes, roles, seed/login paths, and known risks so QA can start in a fresh session without rediscovering implementation history. Keep small related fixes in the current thread.
- Edits are minimal and reversible; every changed line traces to the task.
- Code matches local conventions in sibling files; no DRY/SOLID violations introduced.
- The stack's lint and typecheck pass (use the project's own commands — do not hardcode them here).
- If tests are intended and permitted by project policy, create or update them only after every preceding implementation and non-test verification item is complete and green, then run the eligible focused tests.
- Before the final response, run `plugins/core/conduct/learning-capture-gate.md` from the top-level session. Invoke
  `devkit-learn` only when a durable candidate passes; otherwise finish silently.

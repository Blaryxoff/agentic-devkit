---
name: devkit-coder
description: >-
  implement, fix, build, change, add, remove, or refactor code in any stack. Use before the first edit for every
  implementation, bugfix, or refactor request. Do not use for code review, ralphex plan review, or browser QA.
---

# Coder

> Paths like `plugins/<plugin>/conduct/…` resolve under the devkit clone root (`~/.claude/agentic-devkit` — this skill's symlink target), not the project root.

## Step 1 — Start with the target, not the documentation

Read the user's target and the smallest useful source slice first: the named file/symbol, sibling code in the same module, relevant tests, and schema or contract when the change depends on one. Read an active plan only when the task points to one or the change is genuinely multi-step. If a required input is missing, stop and ask rather than guessing.

Match the conventions of the surrounding code: naming, file layout, and error handling. Existing verbose comments are not a convention to copy; apply the no-prose default in `code-comments.md`.

When the change uses a third-party library/framework API whose current signature you are not certain of, fetch up-to-date docs first per `plugins/core/conduct/library-docs.md` (Context7 when available) and ground implementation in that documentation.

Open only conduct documents that answer a concrete question raised by the target code.

## Step 2 — Apply core coding-conduct (every edit, every stack)

These rules are complete enough for a local in-place edit. Apply them directly; open the referenced core conduct files only when an edge case needs the fuller rule:

- Before writing new code, climb the existence ladder in `solid-dry.md` and stop at the first rung that resolves the need: does it need to exist → is it already in the codebase → standard library → platform/framework native → installed dependency → one expression. Validation, error handling, security, and accessibility are never dropped or thinned to make a change smaller.
- Keep changes limited to the task's requirements and leave unrelated code and formatting intact. Remove only orphans created by this change (`surgical-changes.md`).
- For fixes, make the smallest code change sufficient to resolve the root cause, scoped to the necessary path.
- After two fixes based on the same assumption fail the same check, apply `verification-loop.md` → **Reassess repeated failures** before another production edit.
- Do not add prose comments or explanatory docblocks to implementation code. Express intent through names, types, extracted concepts, and simpler control flow. Never convert what you learned while making the change — the mechanism you traced, why the fix works, the edge case you hit — into a comment; state it in the chat response instead, where it costs the reader nothing to skip. Private/internal narrative comments are forbidden; public docblocks are allowed only for machine-required metadata or contracts that code cannot express (`code-comments.md`).
- Match sibling abstractions and error handling. Reuse an existing utility when it fits; add an abstraction when the task exposes multiple real uses or requires a clear extension seam (`solid-dry.md`).
- Never hardcode secrets or environment-specific credentials. Do not add dependencies without explicit approval.
- Follow project test permissions and `agent-test-restraint.md`: use test-first for reproducible bugs and clear behavioral contracts, observe an assertion-level failure before implementing behavior, then pass and refactor. Establish green behavior tests before refactoring; record exceptions when test-first is impractical or project rules prevent it.

## Step 3 — Load the active stack's conduct

Resolve the active plugins, identify which layers the target actually touches, then load only their relevant rules:

1. Read `.devkit/toolkit.json` to get `enabled` plugins. Add their transitive `dependencies` (from each `plugins/<p>/plugin.json`) and always include `devkit-core`.
2. Map the changed paths and symbols to touched layers. Ignore enabled plugins that the change does not touch.
3. Read `overview.md` for each touched non-core plugin when it exists, then add only the risk-specific documents needed:
   - new/moved files, cross-layer flow, or changed responsibility → `architecture.md`, `anti_patterns.md`, and layering documents such as `thin_controller_model.md`;
   - PHP/public APIs/comments → `php.md`, `documentation.md`;
   - JavaScript/TypeScript boundary types, finite states, or async errors → `plugins/core/conduct/typed-javascript.md`;
   - concurrent operations or shared mutable state → `plugins/core/conduct/feature-design.md` → **State ownership**;
   - authentication, authorization, external input, secrets → `security.md`;
   - migrations, queries, transactions, models, schema assumptions → `database-safety.md`, `database_snapshot.md`, `enums.md`;
   - exceptions, retries, fallbacks → `error_handling.md`;
   - configuration or dependencies → `configs.md`, `dependencies.md`;
   - JavaScript runtime config, package dependencies, or bootstrap → `plugins/core/conduct/runtime-configuration.md`;
   - logs/metrics → `logging.md`, `observability.md`;
   - JavaScript logs, traces, metrics, or runtime diagnosis → `plugins/core/conduct/logging-observability.md`;
   - Pinia/Nuxt state → `stores.md`;
   - CLI commands → `cmd.md`.
4. Skip review, planning, git, Makefile, and testing documents unless the requested change directly targets those artifacts.
5. Project-level rules (`CLAUDE.md`, `AGENTS.md`, `.cursor/rules/`) override generic conventions and project choices,
   but cannot weaken safety, security, approval, destructive-operation, or read/write-boundary requirements. Apply the
   stricter rule for those conflicts and note any exception.

## Step 4 — Quality bar before finishing

- For a multi-step change, pair each implementation step with its smallest relevant verification. Run focused checks first; expand only when risk or failures justify it.
- For a visual behavior change, verify the affected route at the relevant viewport. During iteration, run only the targeted route/viewport/regression cells needed by the change; reserve one exhaustive `devkit-browser` pass for the stable, final implementation. Load `browser-qa-rules.md` only when browser authentication or QA mechanics are actually needed.
- Before compaction or moving unfinished work to a fresh session, save the handoff and consequential decision rationale required by [`context-management.md` §Session boundaries](../../conduct/context-management.md#session-boundaries).
- Before handing a long implementation thread to exhaustive browser QA, extend that handoff with routes, roles, and seed/login paths so QA can start in a fresh session without rediscovering implementation history. Keep small related fixes in the current thread.
- Edits are minimal and reversible; every changed line traces to the task.
- Code matches local conventions in sibling files; no DRY/SOLID violations introduced.
- The stack's lint and typecheck pass (use the project's own commands rather than hardcoded commands).
- Report the focused test-first failure and passing result when applicable, or the specific exception and alternative verification. Run the eligible completion checks under project policy; an expected RED during development is not a completed feature.
- Before the final response, clean up every worktree or temporary clone this task created per `plugins/core/conduct/parallel-sessions.md`. This does not require merging the branch or invoking `wrapup`; report any checkout whose contents cannot be safely preserved and removed.
- Before the final response, run `plugins/core/conduct/learning-capture-gate.md` from the top-level session. Invoke
  `devkit-learn` only when a durable candidate passes. Offer a fix or backlog deferral in one line when the finding is
  actionable repository work instead; otherwise finish silently.

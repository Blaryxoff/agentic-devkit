---
name: devkit-coder
description: triggers when writing, editing, or refactoring code (any stack) — loads the core coding-conduct AND the active plugins' stack conduct before the first line, so edits follow team standards (comments, surgical scope, architecture, anti-patterns) from the start. Use for any implementation/bugfix/refactor turn. Do NOT use for reviewing code (devkit-reviewer-deep/-business-logic), reviewing plans (devkit-plan-reviewer), or browser QA (devkit-browser) — those are separate, post-hoc skills.
---

# Coder

> Paths like `plugins/<plugin>/conduct/…` resolve under the devkit clone root (`~/.claude/agentic-devkit` — this skill's symlink target), not the project root.

## Step 1 — Ground before writing

Read inputs before editing per `plugins/core/conduct/inputs-grounding-gate.md`: the active plan (if the task is non-trivial), sibling code in the same module, and the relevant schema. If a required input is missing, stop and ask — do not guess.

Match the conventions of the surrounding code: naming, file layout, error handling, comment style.

When the change uses a third-party library/framework API whose current signature you are not certain of, fetch up-to-date docs first per `plugins/core/conduct/library-docs.md` (Context7 when available) — do not rely on training-cutoff memory.

## Step 2 — Apply core coding-conduct (every edit, every stack)

These govern *how* you change code regardless of language. Read and obey them:

- `plugins/core/conduct/surgical-changes.md` — change only what the task requires. Do not "improve" adjacent code, reformat, or touch comments on lines you did not otherwise have to edit. Remove only orphans **your** change created.
- `plugins/core/conduct/code-comments.md` — comment the *why*, not the *what*. One line where intent is non-obvious. No change-narration (`// now we…`, `// вместо X возвращаем Y`), no multi-line essays restating the diff, no PR-description prose in code.
- `plugins/core/conduct/communication-style.md` — no meta-commentary in comments.
- `plugins/core/conduct/code-smells.md` and `solid-dry.md` — no duplication, no responsibility leaks, reuse existing utilities before adding abstractions.

## Step 3 — Load the active stack's conduct

Determine the stack, then read its rules so the edit is stack-correct:

1. Read `.devkit/toolkit.json` to get `enabled` plugins. Add their transitive `dependencies` (from each `plugins/<p>/plugin.json`) and always include `devkit-core`.
2. For each **non-core** enabled plugin, read from its `conduct/` directory:
   - **always:** `anti_patterns.md` — the stack backbone that applies to any edit.
   - **when the change adds/moves files, introduces a module, or alters cross-layer structure:** `architecture.md`. Skip it for an in-place edit to existing code — Step 1's sibling-code grounding already supplies the local pattern.
   - **on-demand by what the change touches:** e.g. `stores.md` (Pinia), `php.md` / `documentation.md` (PHP, comments/PHPDoc), `security.md` (auth/input/secrets), `error_handling.md`, `database-safety.md`, `configs.md`, `logging.md`, `enums.md`, `thin_controller_model.md`, `cmd.md`.
   - **skip:** `README.md`, `CLAUDE.md`, `fast_code_review_checklist.md`, `git.md`, `makefile.md`, `observability.md`, and the `spec/` and `testing/` directories — those belong to plan/review/QA/ops phases, not the implementation edit.
3. A conduct rule that conflicts with a project-level rule (`CLAUDE.md`, `AGENTS.md`, `.cursor/rules/`) loses — prefer the project rule and note the exception.

New conduct files added later are read by default (only the named skips are excluded), so adding a `.md` to a plugin's `conduct/` extends this skill with no edit here.

## Step 4 — Quality bar before finishing

- For a multi-step change, pair each implementation step with a verification step in the todo list (lint/typecheck for logic, a rendered screenshot for UI). Do not start the next step until the current one passes the `readiness-gate.md` gate.
- Edits are minimal and reversible; every changed line traces to the task.
- Code matches local conventions in sibling files; no DRY/SOLID violations introduced.
- No secrets, tokens, or environment-specific values hardcoded.
- The stack's lint and typecheck pass (use the project's own commands — do not hardcode them here).
- Do not introduce dependencies unless explicitly approved.

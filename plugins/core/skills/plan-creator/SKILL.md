---
name: devkit-plan-creator
description: create detailed ralphex-compatible markdown plans for product and development planning in the current project stack before implementation
---

# Plan Creator

You are acting as a **senior tech lead and solution architect**. Your job is to help the user create clear,
implementation-ready plans in ralphex format.

**Before writing anything**, conduct a structured interview.

## File naming

All plan files **must** be named using the format `YYYYMMDD-kebab-case-title.md` where the date is today's date.

- Correct: `20260326-homework-create-fixes.md`
- Wrong: `20260326_homework_create_fixes.md`, `homework-create-fixes.md`

Never omit the date prefix.

## Plan directory

Place plans in `docs/plans/` by default. This is configurable via `plans_dir` in the project config.

Within the plans directory:

- Product plans go in `product/` subdirectory.
- Dev plans go in `dev/` subdirectory.

## Mandatory outputs

1. **Product plan** in `{plans_dir}/product/YYYYMMDD-kebab-case-title.md`:
    - Problem statement
    - User value
    - Scope / non-scope
    - Acceptance criteria (prose — no checkboxes here)
    - UX notes (including Figma source when relevant)

2. **Dev plan** in `{plans_dir}/dev/YYYYMMDD-kebab-case-title.md` — **must follow the ralphex plan file format** (see
   below):
    - Technical approach
    - Affected files/modules
    - API/data layer impacts (migrations, contracts, runtime config)
    - State/service layer strategy and data flow contracts
    - Risk list and rollout notes
    - Step-by-step implementation as `### Task N:` sections with checkboxes

---

## Ralphex plan file format (dev plan)

The dev plan must be a valid ralphex plan so the agent can track progress automatically.

### Plan title

The first line must be `# Plan: <Title>`.

### Sections before tasks — no checkboxes

The following sections use prose, bullets, or code blocks. **Never place `- [ ]` checkboxes in these sections** — they
cause extra agent loop iterations.

1. **`## Overview`** — what is being implemented and why. Prose only.
2. **`## Context`** (when applicable) — codebase state, assumptions, constraints, links. Prose only.
3. **`## Validation Commands`** — concrete shell commands the executor should run for test/lint/build. Required.

### Task sections — the only place for checkboxes

4. Use `### Task N: <title>` headers for implementation work.
    - `### Iteration N: <title>` is also allowed when explicitly needed.
    - N can be an integer or non-integer (e.g. `2.5`, `2a`).
    - Do **not** use phase-only structure as the main execution format.
    - Tasks must be ordered dependency-first.

5. Under each task include:
    - `**Files:**` list with `Create / Modify / Read / Delete` targets
    - Task-local checkbox list with `- [ ]` items describing concrete implementation steps
    - Last checkbox in every task must be `- [ ] Mark completed`

### Checkbox rules

6. Checkboxes (`- [ ]` and `- [x]`) belong **only** in `### Task N:` or `### Iteration N:` sections.
    - Do **not** put checkboxes in Overview, Context, Validation Commands, Success criteria, Verification notes, or
      Risks.
7. All task checkboxes must be `- [ ]` (unchecked) for a new plan.
    - Use `- [x]` only when explicitly documenting already completed work.

### Sections after tasks — no checkboxes

8. **Verification notes / QA checklist** — plain prose or bullets, no checkboxes.
9. **Risks / open questions** — present explicitly, no checkboxes. A plan with unresolved open questions is not ready
   for handoff.

### Granularity and naming

10. One task = one coherent deliverable (endpoint, migration set, UI block, etc.). Split if a task spans unrelated
    concerns.
11. Keep naming consistent with existing accepted plans in the repo. Prefer explicit route/model/component names over
    generic descriptions.

### Required dev plan skeleton

```markdown
# Plan: <Title>

## Overview

<Prose description — no checkboxes here.>

## Context

<Background, constraints, links — no checkboxes here.>

## Validation Commands

- `<lint command>`
- `<typecheck/test command>`

### Task 1: <Title>

**Files:** Create/Modify `path/to/file`

- [ ] <Concrete step>
- [ ] <Concrete step>
- [ ] Mark completed

### Task 2: <Title>

**Files:** Modify `path/to/file`

- [ ] <Concrete step>
- [ ] Mark completed

## Verification notes

<Prose checklist — no markdown checkboxes.>

## Risks / open questions

<Prose — no checkboxes.>
```

---

## Stack-specific rules from active plugins

Read `.devkit/toolkit.json` to identify enabled plugins. For each active plugin that has a `conduct/` directory, read all
conduct docs in that directory **except** the files in the skip list below.

### Conduct files to skip

`logging.md`, `observability.md`, `git.md`, `cmd.md`, `makefile.md`, `documentation.md`, `php.md`,
`fast_code_review_checklist.md`, `README.md`, `CLAUDE.md`.

Every other `.md` file in a plugin's `conduct/` directory is plan-relevant and must be read.

### How to apply

- Task steps must follow the architecture patterns defined in active plugins' conduct docs.
- Red-flag patterns listed in conduct docs must be avoided in generated task steps.
- If a conduct doc defines a correct task step shape (e.g. Action extraction pattern), use that shape.
- If a conduct doc rule conflicts with a project-level rule file (`.cursor/rules/`, `CLAUDE.md`, `AGENTS.md`), prefer
  the project-level rule and note the exception.

---

## Rules

- Never start coding while in this skill.
- Ground in real inputs before drafting — see `plugins/core/conduct/inputs-grounding-gate.md`.
- Resolve ambiguities via `plugins/core/conduct/clarification-protocol.md` (no `TBD`, no invented answers).
- Pass `plugins/core/conduct/readiness-gate.md` before declaring the plan ready.
- Confirm with the user before writing the plan file.
- Keep plans concrete enough that another engineer can implement without guessing.
- Ensure stack implications (types, conventions, BEM/Tailwind/etc.) are covered for all affected layers.
- Optimize for first-pass acceptance by ralphex: task-based format, explicit files, checkbox traceability.


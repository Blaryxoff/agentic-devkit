---
name: rubx-spec-creator
description: create detailed markdown specs for product and development planning in the current project stack before implementation
---

# Spec Writer

You are acting as a **senior tech lead and solution architect**. Your job is to help the user create clear, implementation-ready specifications.

**Before writing anything**, conduct a structured interview.

## File naming

All plan files **must** be named using the format `YYYYMMDD-kebab-case-title.md` where the date is today's date.

- Correct: `20260326-homework-create-fixes.md`
- Wrong: `20260326_homework_create_fixes.md`, `homework-create-fixes.md`

Never omit the date prefix.

## Mandatory outputs

1. **Product plan** in `docs/plans/product/YYYYMMDD-kebab-case-title.md`:
   - Problem statement
   - User value
   - Scope / non-scope
   - Acceptance criteria (prose — no checkboxes here)
   - UX notes (including Figma source when relevant)

2. **Development plan** in `docs/plans/dev/YYYYMMDD-kebab-case-title.md` — **must follow the ralphex plan file format** (see below):
   - Technical approach
   - Affected files/modules
   - API/data layer impacts (migrations, contracts, runtime config)
   - State/service layer strategy and data flow contracts
   - Risk list and rollout notes
   - Step-by-step implementation as `### Task N:` sections with checkboxes

## Ralphex plan file format (dev plan only)

The dev plan must be a valid ralphex plan so the agent can track progress automatically.

1. Include a `## Validation Commands` section before tasks.
   - Add concrete test/lint/build commands the executor should run.
2. Use `### Task N: <title>` sections for implementation work.
   - `### Iteration N: <title>` is also allowed when explicitly needed.
   - N can be an integer or non-integer (e.g. `2.5`, `2a`).
   - Do **not** use phase-only structure as the main execution format.
   - Tasks must be ordered dependency-first.
3. Under each task include:
   - `**Files:**` list with `Create/Modify/Read/Delete` targets
   - Task-local checkbox list with `- [ ]` items describing concrete implementation steps
   - Last checkbox in every task must be `- [ ] Mark completed`
4. Place checkboxes **only** in task sections:
   - Do not place `- [ ]` checkboxes in Overview, Context, Acceptance criteria, Risks, or standalone QA sections — they cause extra ralphex loop iterations
5. Checkbox state rules:
   - All task checkboxes must be unchecked (`- [ ]`) for a new plan
   - Use `- [x]` only when explicitly documenting already completed work
6. Granularity rules:
   - One task = one coherent deliverable (endpoint, migration set, UI block, etc.)
   - Split if a task spans unrelated concerns
7. Language consistency:
   - Keep naming consistent with existing accepted plans in the repo
   - Prefer explicit route/model/component names over generic descriptions

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

## Rules

- Never start coding while in this skill.
- Resolve ambiguities by asking targeted questions.
- Keep plans concrete enough that another engineer can implement without guessing.
- Ensure stack implications (types, conventions, BEM/Tailwind/etc.) are covered for all affected layers.
- Optimize for first-pass acceptance by Ralphex: task-based format, explicit files, checkbox traceability.

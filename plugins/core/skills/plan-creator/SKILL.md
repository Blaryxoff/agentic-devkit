---
name: devkit-plan-creator
description: >-
  write a product plan and a ralphex-format dev plan to `{plans_dir}/product/` and `{plans_dir}/dev/` (default `docs/plans/`). Invoke ONLY when the user explicitly writes "ralphex" ("ralphex plan", "создай ralphex план"), or when devkit-browser-ralphex delegates plan rendering here. Do NOT invoke for Claude Code's built-in plan mode (`/plan`, EnterPlanMode/ExitPlanMode), nor for generic "plan a feature" / "propose a solution" / "design an approach" / "спланируй" requests — answer those directly, without this skill.
---

# Plan Creator

> Paths like `plugins/<plugin>/conduct/…` resolve under the devkit clone root (`~/.claude/agentic-devkit` — this skill's symlink target), not the project root.

You are acting as a **senior tech lead and solution architect**. Your job is to help the user create clear,
implementation-ready plans in ralphex format.

**Before writing anything**, conduct a structured interview.

## Plan language

Write every plan file — product plan and dev plan — in **Russian**, regardless of the language the user writes in. This is the one artifact exempt from mirroring the user's language.

Keep verbatim in the original: file paths, identifiers, commands, code blocks, error strings, and section keys of the ralphex format (`## Overview`, `## Context`, `## Validation Commands`, …).

Conduct the interview and answer the user in the user's language; write the files in Russian.

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

Resolve the eligible plugin set before selecting conduct: read `.devkit/toolkit.json` from each active project root,
expand only the enabled plugins' transitive `dependencies` from their `plugin.json` manifests, and include default-enabled
plugins such as `devkit-core`. Then follow `plugins/core/conduct/conduct-loading.md` and infer the affected subset,
layers, contracts, and risks from the requested behaviour, repository evidence, and expected responsibilities—not only
from concerns already written into the draft.

- Read `overview.md` for every plugin used by the affected implementation surface.
- For the dev plan, read architecture rules for each changed implementation layer; add anti-pattern rules when the plan
  introduces files, responsibilities, or cross-layer flow.
- Read only the relevant specification documents for contracts or behaviour covered by the plan.
- Load database, security, configuration, dependency, state, testing, deployment, or other specialist rules when the
  requested behaviour or affected artifacts imply that concern, even if the user or draft omitted it.
- Do not load logging, git, CLI, Makefile, documentation, or language-style rules unless the plan directly changes them.

### How to apply

- Task steps must follow the architecture patterns defined in active plugins' conduct docs.
- Red-flag patterns listed in conduct docs must be avoided in generated task steps.
- If a conduct doc defines a correct task step shape (e.g. Action extraction pattern), use that shape.
- If conduct conflicts with a project-level rule file (`.cursor/rules/`, `CLAUDE.md`, `AGENTS.md`), apply the precedence
  and safety boundary in `conduct-loading.md` and note the exception.

---

## Rules

- Never start coding while in this skill.
- Ground in real inputs before drafting — see `plugins/core/conduct/inputs-grounding-gate.md`.
- Resolve ambiguities via `plugins/core/conduct/clarification-protocol.md` (no `TBD`, no invented answers).
- Pass `plugins/core/conduct/readiness-gate.md` before declaring the plan ready.
- Use `plugins/core/conduct/risk-probe-gate.md` as a thinking tool only. Mentally run the probes (first-break, chaos,
  user-assumption); when a probe surfaces a risk worth eliminating, fold the mitigation into normal plan content
  (acceptance criteria, edge cases, task steps, or the Risks section). **Do not write a Risk Probes block into the
  plan.**
- Confirm with the user before writing the plan file.
- Keep plans concrete enough that another engineer can implement without guessing.
- Ensure stack implications (types, conventions, BEM/Tailwind/etc.) are covered for all affected layers.
- Optimize for first-pass acceptance by ralphex: task-based format, explicit files, checkbox traceability.

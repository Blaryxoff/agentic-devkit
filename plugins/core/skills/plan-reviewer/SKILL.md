---
name: devkit-plan-reviewer
description: review product or dev plans for completeness, correctness, and quality — compares against codebase and project rules, clarifies ambiguities interactively, and proposes ready-to-write plan updates
---

# Plan Reviewer

You are acting as a **senior product engineer and tech lead**. Your job is to review a plan document, identify every meaningful deficiency, and produce a concrete set of proposed updates ready to be written to the file.

**NEVER guess or invent behaviour. NEVER start writing plan updates until real ambiguities are resolved.**

The reviewed plan must be **ready for handoff after review**. Be strict about correctness and completeness, but keep the review **proportional** to the plan's scope and the repository's actual conventions.

---

## Step 1 — Identify plan type and context

Determine whether the document is a **product plan** or a **dev plan** from its path and contents:

- `docs/plans/product/` → product plan
- `docs/plans/dev/` → dev plan

If type cannot be determined, ask the user.

Then identify the review context:

- Is this plan part of a real project repository with code, rules, or sibling plans?
- Is it a standalone draft with no project context?
- Is it paired with another plan for the same feature?

If both a product plan and a dev plan exist for the same feature, review them together for cross-plan alignment (see §5).

If the repository uses dated plan naming (for example from a plan-writing skill), verify the file name follows that convention.

---

## Step 2 — Read and compare against codebase

Before forming findings, read the relevant codebase areas, sibling plans, and repository rules referenced by the plan.

- For every behaviour described: check whether the current code already implements it, partially implements it, or contradicts it.
- For every reference to another plan file or source section: verify the file exists at the cited path and the cited section is present.
- For every design reference (for example a Figma node): require a descriptive label alongside the identifier. Bare IDs without context are a defect.
- Flag any plan item that appears to already be implemented on the current branch — it may not need work at all.
- If the project has a schema snapshot file (for example `database/schema.snapshot.json`), cross-check dev-plan schema assumptions against it and flag mismatches.

If direct access to a cited design source is not available, mark that reference as **user-verification required** rather than assuming it is invalid.

---

## Step 3 — Infer local convention profile before judging

Before applying wording or structure checks, infer the repository's local convention profile from:

- The plan's language and terminology
- Existing accepted plans in the same repository
- Explicit user instructions
- Project-level docs and rules

Apply strict checks against the **local** convention profile. Do not flag language choice itself as a defect unless it conflicts with an explicit repository rule.

Use a **proportionality rule**:

- Small or simple plans do **not** need heavyweight structure if the document is already clear.
- Long, multi-stage, or iterative plans **do** need stronger structure and traceability.
- A repository's established convention overrides a generic checklist item.

If a local convention differs from this skill but is clearly intentional and effective, record it as an **exception**, not a defect.

---

### Product plan checks

A product plan describes **user-visible behaviour and business intent**. It is the source of truth for what should happen, not how code should be written.

**Avoid or flag when unnecessary:**

- Deep implementation detail that is not needed to explain user-visible behaviour
- SQL, migration steps, framework internals, or code snippets
- File paths, class names, method names, route names, or internal enum/storage details that do not materially clarify the feature
- Invented behaviour that is not traceable to a source

Do **not** auto-flag a technical anchor if it is brief, clearly justified, and improves precision for stakeholders.

**Required baseline content — aligned with `spec-creator`:**

1. **Problem statement / summary** — what is being changed.
2. **User value / motivation** — why the change matters.
3. **Scope / non-scope** — what is included and explicitly excluded.
4. **Acceptance criteria** — explicit pass/fail expectations. Prose, bullets, or Given/When/Then are all acceptable. Do **not** require markdown checkboxes.
5. **UX notes** — user-flow notes, design references, or UI constraints when relevant.

**Required when applicable:**

- **Status header** — when the repository uses plan maturity states or review workflow states.
- **Table of contents** — for long plans (roughly 150+ lines) unless the structure is already easy to scan.
- **Terminology / glossary** — when the same concept could be named in multiple ways.
- **Source references** — parent TZ, predecessor plan, ticket, or design source when the plan derives from earlier work.
- **Conflict resolution rule** — when multiple sources can disagree (for example spec vs design vs accepted legacy behaviour).
- **Edge cases** — for non-trivial flows, especially empty, blocked, repeat, partial-data, and failure cases.
- **Loading / error states** — when the feature includes data loading, submission, asynchronous work, or recoverable failure.
- **Exact copy** — modal titles, button labels, empty-state text, and similar copy only when the plan changes visible text or copy precision matters for acceptance.
- **Iterative plan extras** — summary table, previous-iteration notes, priority labels, or definition of done when the document is an iterative fix plan.

If the plan uses priorities, check that they are internally consistent and not inflated.

---

### Dev plan checks

A dev plan translates a product plan into an **executable implementation sequence**.

**Required baseline content — aligned with `spec-creator`:**

1. **Source reference** — link to the product plan when one exists.
2. **`## Overview` section** — what is being implemented and why.
3. **`## Context` section** — current codebase state, assumptions, constraints, and any relevant stack/runtime/schema notes.
4. **`## Validation Commands` section** — concrete shell commands to run after implementation. No vague "run the tests."
5. **Technical approach** — covered across Overview, Context, or task descriptions:
   - affected files/modules
   - API/data-layer impacts
   - state/service/data-flow strategy where relevant
   - rollout notes and risks where relevant
6. **Task structure** — ordered dependency-first, using `### Task N: <title>` or `### Iteration N: <title>`.
7. **Per-task file list** — `**Files:**` with `Create / Modify / Read / Delete` targets.
8. **Task-local checkbox steps** — checkboxes appear only inside task sections.
9. **Task completion marker** — each task ends with `- [ ] Mark completed` or equivalent.
10. **Verification notes / QA checklist** — plain prose or bullets, no markdown checkboxes.
11. **Risks / open questions** — present explicitly. A plan with unresolved open questions is not ready for implementation handoff.

**Required when applicable:**

- **Out-of-scope / deferred block** — when implementation boundaries are easy to misread.
- **Codebase map** — when the plan touches many files or multiple layers.
- **Dependency graph / ordering note** — when task ordering is not obvious, especially for plans with 5+ tasks or cross-cutting dependencies.
- **Batching notes** — when multiple tasks touch the same files and should be implemented together.
- **Conflict resolution notes** — when product spec, design, legacy behaviour, or external constraints conflict.

**Forbidden in dev plans:**

- Invented behaviour not traceable to the product plan or an approved clarification
- Business/product decisions silently introduced during implementation planning
- Checkboxes outside `### Task` or `### Iteration` sections

---

## Step 3.5 — Cross-check against current project stack and rules

If the skill is running inside a real project repository, inspect the repository context before enforcing stack-specific expectations:

- Read project-level guidance such as `CLAUDE.md`, `AGENTS.md`, `.cursor/rules/`, conduct docs, or equivalent.
- Infer the current stack and architecture style from those files and from the codebase itself.
- Verify that the plan's terminology, file references, implementation approach, and validation commands correspond to the actual stack in the repository.
- Verify that the plan does not violate explicit project rules.

Examples of stack-alignment issues:

- The plan proposes files, commands, or patterns from a different framework than the one used in the repo.
- The plan assumes a data layer, routing style, or component model that does not exist in the project.
- The plan ignores an explicit repository rule about architecture, testing, migrations, validation, or deployment.

If project context is **not** available, skip stack-specific enforcement and review only for internal consistency and general plan quality.

Flag stack-specific contradictions as `STACK MISMATCH` and cite the supporting repo evidence.

---

## Step 3.6 — Enforce active plugin conduct rules

If the project uses the devkit toolkit, read `.devkit/toolkit.json` to identify enabled plugins. Locate the toolkit directory (look for `plugins/*/plugin.json` relative to the toolkit submodule root).

For each active plugin that has a `conduct/` directory:

1. Read all conduct docs in `plugins/<plugin>/conduct/`.
2. Verify the plan does not violate any architecture rule, anti-pattern, or convention defined in those docs.
3. For dev plans: verify that task steps follow the patterns prescribed in conduct docs and avoid the red-flag anti-patterns. Flag violations as `STACK MISMATCH` with evidence citing the specific conduct doc and rule.

If the project does not use the devkit toolkit (no `.devkit/toolkit.json`), skip this step.

---

## Step 4 — Check cross-cutting rules (both plan types)

1. **Terminology consistency** — the same concept should not be named two different ways unless the distinction is intentional and explained.
2. **Reference validity** — every cited file, section, plan, or design reference must be resolvable or clearly marked as user-verification required.
3. **No invented behaviour** — every non-trivial behaviour should be traceable to a cited source, current code, or an explicit clarification.
4. **Priority consistency** — if priorities are used, similar defects should have similar priority.
5. **Evidence-backed findings** — every finding must cite:
   - where the problem appears in the plan
   - what evidence supports the finding (codebase, repo rule, missing section, conflicting source, etc.)
6. **Exception handling** — if a repository has a clear, accepted convention that differs from this skill, prefer the repository convention and note the exception instead of forcing a rewrite.

---

## Step 5 — Cross-plan alignment (when both plans exist)

When reviewing a feature that has both a product plan and a dev plan:

- Verify the dev plan does not contradict the product plan.
- Verify every material acceptance criterion in the product plan has at least one corresponding task, verification item, or explicit rationale for why no task is needed.
- Verify the dev plan does not introduce material scope that is absent from the product plan.
- Verify any conflict-resolution rule stated in one plan is respected in the other.

If the plans diverge, identify which document should be corrected and why.

---

## Step 6 — Check autonomous-agent compatibility (dev plans when required)

If the repository, toolkit, or paired plan-writing skill requires an autonomous-agent plan format (for example the `spec-creator` Ralphex task format), verify that the dev plan follows it.

Check:

1. **Plan location** — file is in the expected plans directory if the repository defines one.
2. **Overview section** — `## Overview` exists and contains no checkboxes.
3. **Validation Commands section** — `## Validation Commands` exists and contains concrete commands, not checkboxes.
4. **Task headers** — tasks use `### Task N: <title>` or `### Iteration N: <title>`.
5. **Checkbox placement** — markdown checkboxes appear only inside task sections.
6. **Verification / risks sections** — use plain text bullets or prose, not task checkboxes.
7. **Task completion marker** — each task ends with `- [ ] Mark completed` or equivalent.

If autonomous-agent compatibility is required and the plan fails these checks, produce a `RALPHEX COMPAT` finding for each violation with the specific fix needed.

If that format is **not** required by the repository, treat these items as recommendations rather than blockers.

---

## Step 7 — Clarify ambiguities interactively

After completing all checks above, collect every ambiguity, missing behaviour, and unverifiable claim into a list.

**Do NOT write plan updates yet.**

For each ambiguity, decide:

- If it is a clear defect with an obvious correction (for example a broken section reference), add it to the proposed updates directly.
- If it requires a product, UX, or architectural decision, ask the user.

Use the environment's structured question tool (for example `AskQuestion`) to ask up to 4 questions at a time. Do not batch more than 4. Ask follow-up rounds if needed. Keep questions concrete and include context:

- what the plan currently says
- what is unclear
- why it blocks readiness
- what options are available, if options are known

**Never invent an answer. Never write `TBD` into the plan as a resolution.**

---

## Step 8 — Produce proposed updates

After all ambiguities are resolved, produce a structured list of proposed updates:

```md
## Proposed Updates

### [DEFECT TYPE] Section X.Y — <short title>
**Finding:** <what is wrong or missing>
**Evidence:** <plan section, repo rule, codebase mismatch, or missing source>
**Proposed text:** <exact replacement or addition, ready to paste into the plan>
```

Defect types: `MISSING` | `FORBIDDEN` | `VAGUE` | `INCONSISTENT` | `STALE` | `CROSS-PLAN CONFLICT` | `ALREADY IMPLEMENTED` | `STACK MISMATCH` | `RALPHEX COMPAT`

Group findings by severity:

1. Blocking — the plan is not ready for handoff as written
2. Significant — the plan is usable only with meaningful reviewer assumptions
3. Minor — polish, consistency, or clarity improvements

---

## Step 9 — Readiness assessment

Before presenting proposed updates, evaluate the plan against the readiness gate:

| Gate | Question |
|------|----------|
| Scope clarity | Are in-scope and out-of-scope boundaries clear enough to prevent over-building? |
| Behaviour clarity | Are acceptance criteria and major edge cases explicit enough to implement and verify? |
| Reference validity | Are cited plans, sections, and design references valid or clearly marked for user verification? |
| Codebase alignment | Does the plan match the current implementation state rather than ignoring or duplicating existing work? |
| Stack alignment | If project context exists, does the plan fit the actual project stack and rules? |
| Plugin conduct compliance | Do all plan tasks comply with conduct rules from active devkit plugins (§3.6)? |
| Open questions | Are all blocking open questions resolved? |
| Validation path | For dev plans, are concrete validation commands and verification notes present? |
| Agent format | If autonomous-agent execution is required, does the plan pass the format checks in §6? |

Mark each gate ✅ or ❌. If any gate is ❌, the plan is **not ready for handoff** and the failing gates must appear in the blocking findings.

Then ask: **"Shall I write these updates to the plan file?"**

Do not write to the file until the user confirms. When confirmed, apply all updates in a single pass.

---

## Quality bar

A plan that passes this review should score 10/10 across:

| Dimension | 10/10 means |
|-----------|-------------|
| Scope | In-scope and out-of-scope boundaries are clear enough to prevent accidental scope creep |
| Behaviour | User-visible outcomes and implementation expectations are explicit for the relevant states |
| Acceptance criteria | Outcomes are testable and concrete, without relying on reviewer guesswork |
| Consistency | One name per concept unless distinctions are intentional and documented |
| References | Citations are valid, descriptive, and usable |
| Codebase alignment | No material item is already implemented, contradicted, or based on stale assumptions |
| Stack alignment | When project context exists, the plan fits the actual stack and repository rules |
| Type hygiene | Product plans stay user-facing; dev plans stay implementation-focused |
| Completeness | No blocking open questions and no invented behaviour |
| Implementability | Another engineer or agent can execute the plan without guessing the next step |

---

## Capability-aware notes

- **Design references:** if direct design access is available in the current environment, verify referenced nodes/screens when needed. If not available, explicitly mark design references as `user-verification required`.
- **Tool portability:** if a named tool is unavailable, use the closest equivalent tool and preserve the same interaction pattern: small concrete question batches, explicit context, no invented answers.
- **Schema snapshot:** if the project has `database/schema.snapshot.json`, prefer it as the primary source of truth for current database structure over reading individual migrations.
- **Project rules discovery:** look for `CLAUDE.md`, `AGENTS.md`, `.cursor/rules/`, conduct docs, or equivalent repository guidance before enforcing stack-specific rules.

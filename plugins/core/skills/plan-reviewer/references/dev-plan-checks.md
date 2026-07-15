# Dev plan checks — ralphex format

A dev plan translates a product plan into an executable implementation sequence and must follow the ralphex format.

## Structural requirements

1. First line is `# Plan: <Title>`.
2. `## Overview` explains what and why, with no checkboxes.
3. `## Context`, when applicable, states current codebase state, assumptions, and constraints, with no checkboxes.
4. `## Validation Commands` contains concrete test, lint, typecheck, or build commands, with no checkboxes.
5. Link the product plan when one exists.
6. Cover the technical approach across Overview, Context, or tasks: affected files/modules, API/data impacts,
   state/service/data flow, rollout notes, and relevant risks.

## Task requirements

7. Order work dependency-first under `### Task N: <title>` or `### Iteration N: <title>` headers. N may be an integer
   or non-integer such as `2.5` or `2a`.
8. Every task has a `**Files:**` list using `Create / Modify / Read / Delete` targets.
9. Every task has concrete `- [ ]` implementation steps.
10. Checkboxes appear only inside Task or Iteration sections. Checkboxes in Overview, Context, Validation Commands,
    Success criteria, Verification notes, or Risks break the agent loop.
11. Every task ends with `- [ ] Mark completed`.
12. New plans use unchecked boxes; use `- [x]` only for already completed work.

## Closing requirements

13. Verification notes or QA checklist use prose or plain bullets, not checkboxes.
14. Risks and open questions are explicit and contain no checkboxes. Unresolved open questions block handoff.

## Add when applicable

- Out-of-scope or deferred block when boundaries are easy to misread.
- Codebase map for many files or layers.
- Dependency graph or ordering note when ordering is unclear, especially with 5+ tasks.
- Batching notes when several tasks touch the same files.
- Conflict-resolution notes when product spec, design, legacy behaviour, or external constraints disagree.

## Forbidden

- Invented behaviour not traceable to the product plan or approved clarification.
- Product, UX, or architectural decisions silently introduced during implementation planning.
- Checkboxes outside Task or Iteration sections.

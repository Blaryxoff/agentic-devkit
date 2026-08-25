# Risk-Gated Review Specialist Fan-out

Use this playbook from the top-level session for deep or full code review. The top-level session owns reviewer dispatch;
subagents never dispatch reviewers. Resolve the complete reviewer set once, then launch it in one parallel batch when
capacity permits. When capacity is smaller than the reviewer set, launch the maximum independent set in parallel waves.
If the harness has no subagents, run the same reviewers sequentially.

## Fan-out

1. Resolve one exact scope: working-tree diff, branch diff, named files, and the applicable plan or acceptance criteria.
2. Add the stack quality variants selected by `devkit-reviewer-deep`. Add the generic quality fallback below for changed
   code that no stack variant covers.
3. For a full review, add the stack behavioural variants selected by `devkit-reviewer-business-logic`. Add the generic
   implementation fallback below for changed behaviour that no stack variant covers.
4. Add the testing specialist only when its gate opens.
5. Add the documentation specialist only when its gate opens.
6. Add the visual-reference specialist only when its gate opens.
7. Launch all applicable read-only reviewers in one batch or the minimum capacity-bounded waves. Give every reviewer the
   same scope and intent. Never nest orchestration or dispatch the same axis twice.
8. Keep reports separated by reviewer axis. Deduplicate only identical `file:line` plus defect findings, preserving all
   contributing reviewer names.

Every prompt must require read-only operation, real context beyond the diff, and `review-findings-format.md`. Require
`file:line` for source-backed findings and the evidence contract below for visual-reference findings. Never pass one
reviewer's conclusions to another before both have independently reviewed the scope.

## Generic fallbacks

Use these read-only roles only for changed scope that no active stack reviewer covers:

- **Generic quality** — review architecture, security, data correctness, error handling, performance, and simplification.
  Apply `code-smells.md` and local project conventions. Do not repeat scope owned by a stack quality variant.
- **Generic implementation** — review behavioral completeness against the request, plan, acceptance criteria, and nearby
  call sites. Check success/failure paths, permissions, state transitions, compatibility, and user-visible outcomes. Do
  not repeat scope owned by a stack business-logic variant.

Generic fallbacks make core-toolkit, shell, Python, Go, documentation-backed behavior, and unsupported-stack changes
reviewable without pretending a Laravel or frontend variant applies.

## Testing specialist

Open this gate when either condition holds:

- tests or test fixtures changed; or
- production behaviour, permissions, data transitions, error handling, or an acceptance criterion changed and the active
  plan or project test policy requires corresponding tests.

Keep the gate closed when project policy forbids or defers test authoring and no test artifact changed. Reviewing tests
does not authorize running them or writing replacements.

Prompt the specialist to check:

- changed behaviour and required scenarios map to real assertions;
- success, failure, boundary, permission, and integration paths required by the scope are covered;
- tests verify behaviour rather than mocks or implementation details;
- assertions can fail when production behaviour is wrong; no conditional, hardcoded, skipped, or commented-out fake pass;
- setup, teardown, shared state, time, network, and ordering do not make tests coupled or flaky.

## Documentation specialist

Open this gate when the diff changes a public API, CLI flag, configuration key, dependency or system requirement,
installation/upgrade procedure, operational workflow, breaking contract, or user-visible behaviour; also open it when
human documentation changed.

Prompt the specialist to compare the changed contract with its canonical README, API, CLI, configuration, migration, and
operations documentation. Report only missing, stale, or contradictory human documentation. Do not request `CLAUDE.md`
entries; route durable project knowledge through `learning-capture-gate.md`.

## Visual-reference specialist

Open this gate when the reviewed change affects rendered frontend UI and the user or scoped acceptance artifacts supply
a Figma frame, approved screenshot, mockup, or other design reference. A supplied reference makes visual correspondence
part of review acceptance even when the user did not separately ask for a design review.

Prompt the specialist to:

- inspect the running UI at every referenced page/state × applicable viewport; start only the project's minimal local
  server when needed and leave pre-existing servers running;
- apply `plugins/frontend/conduct/design-quality.md` **Reference fidelity** and use
  `plugins/frontend/conduct/visual-implementation.md` §2–§4 for measured browser comparison;
- run the mandated whole-frame composition and complete element-inventory pass before inspecting individual colors,
  spacing, typography, dividers, or other local details. Matching local details never substitutes for the first pass;
- cite the reference, route/state, viewport, expected versus actual measurement or appearance, screenshot evidence, and
  `file:line` when the source cause is traceable;
- list unchecked reference states/viewports as unverified. If the reference or running page is inaccessible, report the
  blocked gate and never infer a clean visual result from source code alone.

Keep this specialist read-only. It reports implementation deltas, not subjective redesign preferences, and never
updates baselines or fixes CSS.

## Simplification

Do not launch a separate simplification reviewer by default. Stack and generic quality reviewers apply `code-smells.md`,
including over-engineering and unnecessary-indirection checks. A separate simplification pass is justified only when the
user asks for it or the change is primarily an abstraction/refactor audit.

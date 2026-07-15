# Product plan checks

A product plan describes user-visible behaviour and business intent. It is the source of truth for what should happen,
not how code should be written.

## Avoid or flag when unnecessary

- Deep implementation detail not needed to explain user-visible behaviour.
- SQL, migration steps, framework internals, or code snippets.
- File paths, class names, method names, route names, or internal enum/storage details that do not materially clarify
  the feature.
- Invented behaviour not traceable to a source.

Do not auto-flag a technical anchor when it is brief, justified, and improves stakeholder precision.

## Required baseline

1. Problem statement or summary.
2. User value or motivation.
3. Scope and non-scope.
4. Explicit pass/fail acceptance criteria. Prose, bullets, or Given/When/Then are acceptable; do not require markdown
   checkboxes.
5. UX notes, user-flow notes, design references, or UI constraints when relevant.

## Required when applicable

- Status header when the repository uses plan maturity or review states.
- Table of contents for long plans, roughly 150+ lines, unless already easy to scan.
- Terminology or glossary when one concept could have multiple names.
- Parent specification, predecessor plan, ticket, or design source references.
- Conflict-resolution rule when sources can disagree.
- Empty, blocked, repeat, partial-data, and failure edge cases for non-trivial flows.
- Loading and error states for asynchronous work.
- Exact visible copy only when the plan changes it or copy precision matters for acceptance.
- Summary table, previous-iteration notes, priorities, or definition of done for iterative plans.

If priorities are used, verify they are internally consistent and not inflated.

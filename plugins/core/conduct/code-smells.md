# Code Smells

Stack-agnostic checklist for code-quality review. Reviewers (`devkit-reviewer-*`) enforce these alongside the active stack's conduct. Report problems only — no positive observations, no personal-preference nits. Focus on consistency with the existing codebase, not on how you would have written it.

> Adapted from `umputun/cc-thingz` (MIT).

## Style consistency

Check that changed code matches the surrounding code:

1. **Naming** — new names follow existing patterns.
2. **Organization** — new code is structured like existing code in the same module/package.
3. **Import ordering** — matches the rest of the project.
4. **Comment style** — follows project conventions (see `code-comments.md`).
5. **Error handling** — matches the project's established pattern.
6. **Logging** — consistent with the rest of the codebase (see `../skills/reviewer-logging` and any stack logging conduct).

## Code smells

1. **Dead code** — unused functions, variables, imports, parameters.
2. **Duplicated logic** — copy-paste that should be consolidated.
3. **Long functions** — doing too many things.
4. **Deep nesting** — excessive if/else or loop nesting.
5. **Magic numbers/strings** — unexplained literal values.
6. **Inconsistent abstraction levels** — mixing high- and low-level operations in one place.

## Anti-patterns

1. **God objects** — types with too many responsibilities.
2. **Shotgun surgery** — one change forces edits across many unrelated files.
3. **Feature envy** — code that uses another module's data more than its own.
4. **Primitive obsession** — primitives where a domain type would be clearer.

## Over-engineering

1. **Pass-through layers** — wrappers, services, or repositories that only forward the same arguments and return value
   without enforcing a boundary, contract, policy, or cross-cutting behavior required by local architecture.
2. **Single-use factories or interfaces** — extension machinery with one fixed implementation and no demonstrated
   consumer, substitution, generated-contract, or test-seam need.
3. **Redundant representations** — DTOs, mappers, or conversion chains that repeat the same shape without enforcing a boundary.
4. **Speculative flexibility** — unused hooks, plugin points, generic options, or configuration for a fixed requirement.
5. **Dead alternatives** — legacy modes, dual implementations, or feature flags whose alternate path has no active caller.
6. **Failure-hiding fallback** — catching a real failure and silently taking a degraded path instead of surfacing the error.
7. **Premature optimization** — caches, pools, custom structures, or concurrency without evidence that the simple path is insufficient.

## What to report

For each finding, follow `review-findings-format.md`:

- **Location** — `file:line`.
- **Issue** — what is inconsistent or smelly.
- **Convention** — what the project convention is (cite a conduct doc or existing code as evidence).
- **Fix** — a concrete change that aligns with the convention.

A finding without evidence is a guess — reframe it as a question per `clarification-protocol.md`.

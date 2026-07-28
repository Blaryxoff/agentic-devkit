# Documentation

Frontend code should explain itself through precise names, TypeScript types, small composables, and explicit state transitions. Inline prose is exceptional.

## What to document

- public integration contracts that TypeScript cannot express
- machine-consumed metadata or required lint directives
- external browser/vendor constraints that force surprising code

## Style guidelines

- keep unavoidable comments to the shortest useful form
- cite an external issue, specification, or invariant when practical
- put longer architecture and usage guidance in external documentation

## Type-first documentation

- use expressive TypeScript types as primary documentation
- do not add JSDoc to private/internal implementation
- do not add JSDoc merely because a symbol is exported

## Examples

- put compact usage examples in tests or markdown documentation
- use markdown docs for larger patterns and architecture decisions

## DO / DO NOT

DO:
- refactor unclear implementation instead of explaining it in a comment
- document only contracts that types and code cannot express

DO NOT:
- leave stale comments after refactors
- write obvious comments that duplicate code line-by-line
- write paragraph-form explanations of business logic or change history
- copy nearby verbose comments as a style convention

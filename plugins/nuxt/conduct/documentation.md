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
- Reserve JSDoc for public contracts or metadata that TypeScript cannot express; exported visibility alone is not a reason to add it.

## Examples

- put compact usage examples in tests or markdown documentation
- use markdown docs for larger patterns and architecture decisions

## Apply these practices

- refactor unclear implementation instead of explaining it in a comment
- document only contracts that types and code cannot express

## Replace these patterns

- Update or remove comments when a refactor makes them stale.
- Express intent through code and types instead of line-by-line comments.
- Put longer explanations of business logic or change history in external documentation.
- Keep comments concise even when nearby examples are verbose.

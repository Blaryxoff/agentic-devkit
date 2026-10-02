# Documentation

Use precise names, native types, small operations, and explicit domain concepts as the primary documentation. Add narrative PHPDoc only when a consumer needs information that code cannot express.

## PHPDoc threshold

Use PHPDoc only when it carries information PHP cannot express and a tool or consumer needs it, such as array shapes, generics, templates, conditional types, or a non-obvious public integration contract. Prefer native parameter, return, property, and exception types whenever they are sufficient.

Refactor unclear private or protected implementation instead of adding explanatory docblocks. Put longer architecture, migration, and operational explanations in external documentation.

## Apply these practices

- use the narrowest standard PHPDoc tag needed by static analysis or IDE tooling
- encode behavior in types and focused tests when project policy permits tests
- keep unavoidable public contract text short and stable

## Replace these patterns

- add PHPDoc to public symbols only when it documents a needed contract
- place business logic, edit history, or ticket context in external documentation
- use types and behavior directly instead of repeating signatures in prose
- reserve `@param`, `@return`, and `@throws` for contracts native types do not express
- follow `plugins/core/conduct/code-comments.md` for comment style

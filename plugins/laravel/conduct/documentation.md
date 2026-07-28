# Documentation

Code should document itself through precise names, native types, small operations, and explicit domain concepts. Do not add narrative PHPDoc merely because a class or method is public.

## PHPDoc threshold

Use PHPDoc only when it carries information PHP cannot express and a tool or consumer needs it, such as array shapes, generics, templates, conditional types, or a non-obvious public integration contract. Prefer native parameter, return, property, and exception types whenever they are sufficient.

Private and protected implementation details must not have explanatory docblocks. Refactor unclear code instead. Longer architecture, migration, and operational explanations belong in external documentation, not above a method.

## DO / DO NOT

**DO:**
- use the narrowest standard PHPDoc tag needed by static analysis or IDE tooling
- encode behavior in types and focused tests when project policy permits tests
- keep unavoidable public contract text short and stable

**DO NOT:**
- generate a docblock for every public symbol
- write paragraph-form explanations of business logic, edit history, or ticket context
- repeat the signature or method name in prose
- use `@param`, `@return`, or `@throws` when native types and behavior already make the contract clear
- copy the style of nearby verbose comments; follow `plugins/core/conduct/code-comments.md`

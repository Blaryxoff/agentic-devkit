# Documentation

Code should be well documented. Every public class, interface, method, function, and module-level contract should have a doc comment following PHPDoc and project conventions.

## Documentation generation

Documentation should be readable directly in IDE/GitHub from docblocks and type declarations. Keep docs close to code and framework conventions.

Run local docs/quality checks with project scripts when available:

```bash
composer test
```

Use this flow to ensure docs stay aligned with code behavior and typed signatures.

## DO / DO NOT

**DO:**
- write a file/class-level doc comment where intent is not obvious
- start doc comments with the name of the declared symbol when practical
- document **why**, not just **what** — the signature already shows the what
- include short usage examples in tests or nearby docs when behavior is non-trivial

**DO NOT:**
- leave public symbols undocumented when intent/contracts are not obvious
- repeat the function signature in prose — `CreateUser handles user creation` adds nothing
- use non-standard annotation style inconsistently; prefer standard PHPDoc tags when needed (`@param`, `@return`, `@throws`)

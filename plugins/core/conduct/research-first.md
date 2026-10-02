# Research Before Coding

Adapted from the search-first development pattern. Applies to all implementation work.

## Rule

Before writing or modifying code, read the relevant codebase areas first. Verify structure, naming, patterns, and conventions against the repository.

## Required research steps

1. **Locate existing code** — search for related classes, functions, components, routes, and tests before creating new ones. Duplication often means something already exists.
2. **Read conventions** — check existing files in the same layer/directory for naming patterns, import style, error handling approach, and organizational conventions.
3. **Understand call sites** — before modifying a function or interface, find all callers and dependents to understand the blast radius.
4. **Check for prior art** — search the codebase for similar features or patterns before inventing a new approach. Follow established patterns unless there is a clear reason to deviate.
5. **Verify assumptions** — if a plan references a file, route, model, or column, confirm it exists and matches the described shape before implementing against it.

## Anti-patterns

- Writing a new service without checking if one with similar responsibility already exists.
- Creating a helper function without searching for existing utilities that do the same thing.
- Assuming a database column name or type without checking the schema or migration.
- Modifying a shared interface without finding all implementations.
- Adding a new pattern (e.g. a new base class, a new directory convention) when the codebase already has an established approach.

## Scope

This applies to implementation, not to planning or review. During planning, speculation about code structure is normal and expected — but the implementer must verify before writing.

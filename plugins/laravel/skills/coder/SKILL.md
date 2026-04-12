---
name: devkit-coder
description: triggers when implementing new code, fixing bugs, or refactoring — applies project-stack architecture, security, and quality rules during implementation
---

# Coder

You are acting as a **senior full-stack developer** for the current project stack.
Your job is to write production-ready code that follows team conventions from the first line.

## Core operating rules

- Keep scope tight and change only what the task requires.
- Reuse existing project patterns before creating new abstractions.
- Do not introduce dependencies unless explicitly approved.
- Prefer explicitness over "smart" implicit behavior.

## Backend implementation standards (Laravel)

1. Use **FormRequest** for request validation.
2. Use **Policies/Gates** for authorization.
3. Keep controllers thin; put business orchestration in existing services/actions where project convention uses them.
4. Prefer Eloquent relationships/scopes/resources to ad-hoc query logic.
5. Prevent N+1 with eager loading.
6. Avoid `env()` outside config files.
7. Return consistent responses (structured page data, redirects with flash/errors, or API Resources).
8. Use transactions for multi-step writes where consistency matters.

## Frontend concerns

For frontend implementation standards, follow the guidelines provided by co-enabled plugins (vue, inertia, tailwind, nuxt, etc.). This skill does not prescribe frontend conventions -- those belong to their respective plugins.

## Planning requirements

- If task is non-trivial, ensure there is a product plan in `docs/plans/product/*.md`.
- Ensure there is a development plan in `docs/plans/dev/*.md` with technical steps.
- Implement in the sequence defined by the dev plan.

## Quality bar before finishing

- Code follows local conventions in sibling files.
- No obvious duplication (DRY) or responsibility leaks (SOLID).
- No secrets, tokens, or sensitive data introduced.
- Edits remain minimal and reversible.

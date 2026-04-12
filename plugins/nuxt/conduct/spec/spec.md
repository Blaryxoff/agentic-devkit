# Specification Template

LLM-ready specification template for Nuxt + TypeScript + BEM features.

## 1. Discovery (required before writing)

- What are we building?
- Who is the user?
- What problem is solved?
- What is in scope and out of scope?
- Which pages/components/composables are affected?
- What are constraints (deadline, performance, security)?

## 2. Spec structure

```markdown
# Spec: <feature-name>

## Summary
Short description and expected outcome.

## Goals
- measurable goal 1
- measurable goal 2

## Non-goals
- explicitly excluded items

## UX flow
- user journey and screen states
- route/query behavior

## Technical plan
- affected files
- composables/services changes
- API contract expectations (request/response)
- runtime config/env changes

## Error handling
- loading/empty/error states
- retry and fallback behavior

## Security
- input/output safety
- auth/session considerations

## Observability
- logs, metrics, and alert-worthy failures

## Rollout and rollback
- release steps
- rollback strategy

## Acceptance criteria
- explicit pass/fail checks
```

## 3. Quality bar

- unambiguous and implementation-ready
- no hidden assumptions
- explicit edge cases
- clear ownership of each change area

## 4. Storage rules

- save specs in project `docs/` following existing folder pattern.
- use clear versioned names when multiple revisions exist.

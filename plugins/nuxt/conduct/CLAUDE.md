# Conduct — Nuxt Frontend Development Standards

This toolkit contains architecture rules, coding conventions, and best practices for Nuxt frontend applications. It is standards/documentation content used as context for AI coding agents (Claude Code, Cursor) and as a reference for human developers.

## Document reading order

Read the conduct documents in this order — each builds on the previous:

1. **[overview.md](./overview.md)** — technology stack, reading order, how to use with AI agents
2. **[architecture.md](./architecture.md)** — layered architecture, domain boundaries, services/actions, contracts, project folder structure
3. **[configs.md](./configs.md)** — frontend config patterns and environment usage boundaries
4. **[error_handling.md](./error_handling.md)** — domain/infrastructure error boundaries and user-safe failure behavior
5. **[logging.md](./logging.md)** — structured frontend logging, log levels, and sensitive-data redaction
6. **[stores.md](./stores.md)** — Pinia store rules, when to use stores vs composables
7. **[dependencies.md](./dependencies.md)** — approved third-party libraries by concern, forbidden packages
8. **[documentation.md](./documentation.md)** — documentation standards and update workflow
9. **[testing/test-cases.md](testing/test-cases.md)** — test-case design for frontend flows

### Reference documents (consult when relevant)

- **[security.md](./security.md)** — input validation, XSS prevention, auth/session hygiene, CORS
- **[makefile.md](./makefile.md)** — standard project task targets
- **[anti_patterns.md](./anti_patterns.md)** — common mistakes with code examples
- **[fast_code_review_checklist.md](./fast_code_review_checklist.md)** — pre-commit/PR review checklist
- **[git.md](./git.md)** — branching strategy, commit conventions, merge requests, tagging
- **[spec/spec.md](spec/spec.md)** — feature specification template
- **[inertia/overview.md](../../inertia/conduct/overview.md)** — Inertia-specific transport rules
- **[vue/overview.md](../../vue/conduct/overview.md)** — Vue-specific conventions
- **[tailwind/overview.md](../../tailwind/conduct/overview.md)** — Tailwind-specific conventions
- **[ownership-map.md](../../core/conduct/ownership-map.md)** — strict policy ownership map

## Key architectural rules

- **Layered architecture** (REQUIRED): business logic belongs in composables/services, while rendering stays in pages/components.
- **Nuxt-first conventions** (REQUIRED): use Nuxt idioms for data fetching, routing, and runtime config.
- **BEM-first styling flow** (REQUIRED): component and page styles follow project BEM naming consistently.
- **DTO/Value object boundaries** (OPTIONAL but preferred): avoid passing raw arrays across layers when structure is stable; use typed objects or validated payloads.
- **Mappers at every boundary**: request-to-domain, model-to-domain/view-model — avoid leaking transport-specific payloads into core business logic.

## Technology stack

| Concern | Technology |
|---------|-----------|
| Runtime | Nuxt 3 |
| Frontend framework | Vue 3 |
| Language | TypeScript |
| UI styling | BEM + SCSS |
| Data layer | HTTP APIs via composables/services |
| Logging | Browser/client logging + remote sinks by project policy |
| Testing | Frontend unit/integration/e2e tooling configured in repo |
| CLI | pnpm scripts |
| Config (env) | Nuxt runtime config + `.env` |

## Standard Makefile targets

| Target | Purpose |
|--------|---------|
| `test` | Run frontend tests |
| `test-unit` | Run frontend unit tests |
| `test-e2e` | Run e2e tests |
| `test-coverage` | Generate coverage report |
| `lint` | Run frontend linting |
| `fmt` | Run formatter |
| `build` | Build frontend assets |
| `ci` | lint + tests + build |

## Development workflow

1. **Spec** — write a feature specification using [spec template](spec/spec.md)
2. **Test cases** — create high-level E2E/Feature test cases
3. **Implement** — feed spec + test cases + conduct rules to AI agent or implement manually
4. **Review** — validate with [fast code review checklist](./fast_code_review_checklist.md)
5. **Commit** — follow [git conventions](./git.md): Conventional Commits format, one logical change per commit, run project pre-commit checks

## Proposing changes to these rules

1. Ensure tone is use-agnostic (not skill/instruction format)
2. Verify no conflicts with or duplicates of existing rules
3. Update [fast_code_review_checklist.md](./fast_code_review_checklist.md) if the change adds checkable items
4. Create a PR

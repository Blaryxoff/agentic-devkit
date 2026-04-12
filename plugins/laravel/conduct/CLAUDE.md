# Conduct — Laravel + Inertia Development Standards

This toolkit contains architecture rules, coding conventions, and best practices for Laravel + Inertia applications. It is standards/documentation content used as context for AI coding agents (Claude Code, Cursor) and as a reference for human developers.

## Document reading order

Read the conduct documents in this order — each builds on the previous:

1. **[overview.md](./overview.md)** — technology stack, reading order, how to use with AI agents
2. **[architecture.md](./architecture.md)** — layered architecture, domain boundaries, services/actions, contracts, project folder structure
3. **[php.md](./php.md)** — naming, typing, class design, error handling, framework integration
4. **[configs.md](./configs.md)** — Laravel config files, env-driven configuration, validation, and defaults
5. **[cmd.md](./cmd.md)** — Artisan command structure, dependency wiring, scheduling, queue workers, graceful shutdown
6. **[error_handling.md](./error_handling.md)** — exceptions, domain/infrastructure error boundaries, wrapping/reporting rules
7. **[logging.md](./logging.md)** — Laravel logging channels, structured context, log levels, what to log/not log
8. **[observability.md](./observability.md)** — tracing/metrics strategy, request lifecycle visibility, logs-to-traces correlation
9. **[dependencies.md](./dependencies.md)** — approved third-party libraries by concern, forbidden packages
10. **[testing/php-testing.md](testing/php-testing.md)** — test placement, mocks, unit/integration tests, data providers, Laravel test tooling

### Reference documents (consult when relevant)

- **[security.md](./security.md)** — input validation, SQL injection, CSRF, CORS, rate limiting
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

- **Layered architecture** (REQUIRED): business logic stays in domain/services; HTTP, persistence, queues, and external APIs stay at boundaries. Keep domain rules framework-light where possible.
- **Laravel-first conventions** (REQUIRED): use Form Requests for validation, Policies/Gates for authorization, Eloquent scopes/relationships for query composition, and Resources/Transformers for response shaping.
- **Inertia-first web flow** (REQUIRED): server routes/controllers return Inertia responses, pages live in Vue components, and page props define the contract between backend and frontend.
- **DTO/Value object boundaries** (OPTIONAL but preferred): avoid passing raw arrays across layers when structure is stable; use typed objects or validated payloads.
- **Mappers at every boundary**: request-to-domain, model-to-domain/view-model — avoid leaking transport-specific payloads into core business logic.

## Technology stack

| Concern | Technology |
|---------|-----------|
| Backend language | PHP 8.3 |
| Backend framework | Laravel 12 |
| Web transport | Nginx + PHP-FPM |
| Frontend transport | Inertia v2 |
| Frontend framework | Vue 3 |
| UI styling | Tailwind CSS v3 |
| Database | PostgreSQL/MySQL via Eloquent ORM |
| Cache/queue | Redis + Laravel Queue |
| Logging | Laravel Monolog channels |
| Testing | PHPUnit, Laravel testing helpers, browser/e2e tooling as configured |
| CLI | Artisan |
| Config (env) | Laravel config + `.env` |

## Standard Makefile targets

| Target | Purpose |
|--------|---------|
| `test` | Run application tests |
| `test-unit` | Run unit tests only |
| `test-feature` | Run feature/integration tests only |
| `test-coverage` | Generate test coverage report |
| `lint` | Run static analysis and frontend linting |
| `fmt` | Run Laravel Pint and frontend formatter |
| `migrate` | Run database migrations |
| `seed` | Seed database fixtures |
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

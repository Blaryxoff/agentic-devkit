# Fast code review checklist

Use this checklist before committing code or when reviewing pull requests. Every item should be checked. This document can also be used by AI agents as a self-check before marking a task complete.

## Architecture

- [ ] Business logic is in services/actions/domain classes, not in controllers, middleware, or form requests
- [ ] Controllers are thin: validate request -> call service/action -> return response
- [ ] Models are thin: data structure, relationships, query scopes, and simple accessors/mutators only
- [ ] Eloquent relationships are used instead of manual joins/duplicated query logic where applicable
- [ ] New value objects / custom casts are used instead of raw arrays/strings where applicable
- [ ] Interfaces/contracts are small and specific (1-3 methods) where abstraction is needed
- [ ] API Resources / DTO mapping exists for boundary crossing (request ↔ domain, domain ↔ response)
- [ ] Inertia page data is shaped intentionally (only required props, no over-fetching)

## Code quality

- [ ] PHP code is formatted with `vendor/bin/pint --dirty`
- [ ] Frontend code is formatted/linted with project ESLint/Prettier rules
- [ ] No lint-ignore directives without a justifying comment
- [ ] Files are under 500 lines
- [ ] Classes/components stay focused and avoid "god objects/components"
- [ ] Variable names are self-describing
- [ ] Imports are clean and unused imports are removed

## Error handling

- [ ] All exceptions/error states are handled — no silent failures
- [ ] Domain/business exceptions are explicit and typed where needed
- [ ] Exceptions are wrapped/re-thrown with useful context where needed
- [ ] Error checks rely on exception types/classes, not fragile string matching
- [ ] Controllers translate domain errors to proper HTTP status/validation/Inertia errors
- [ ] No `dd()`, `dump()`, `die()`, or `exit()` in committed code
- [ ] No swallowed exceptions (`catch` without meaningful handling/logging)

## Logging

- [ ] Logs are structured and contextual (request id, user id, route/job where applicable)
- [ ] Heavy data is not logged (files, large payloads) — only metadata (size, count)
- [ ] No secrets, passwords, tokens, or PII in logs
- [ ] Log levels are appropriate: debug for development, info for events, error for failures
- [ ] No debug output statements left in code (`var_dump`, `print_r`, `console.log` for production paths)
- [ ] Failures in queue/jobs/HTTP integrations include enough context for incident debugging

## Configuration

- [ ] New config fields are defined in `config/*.php` and consumed via `config()`
- [ ] Config validation exists for required fields and value ranges
- [ ] Secrets use environment variables, not hardcoded values
- [ ] `.env.example` is updated with new variables (empty for secrets)
- [ ] No `env()` calls outside of config files

## Testing

- [ ] Unit tests exist for new service methods, entities, and value objects
- [ ] Feature tests exist for new routes/controllers/middleware/Inertia flows where applicable
- [ ] Tests use mocks/fakes, not real external integrations
- [ ] Each test is self-contained — no shared mutable state
- [ ] Data providers are used for parameterized scenarios
- [ ] Test naming follows project PHPUnit convention (descriptive `test_*` behavior names)
- [ ] Laravel fakes are used where applicable (`Queue::fake`, `Mail::fake`, `Http::fake`)
- [ ] Coverage on `app/` meets minimum threshold (80%)

## Async and queues

- [ ] Long-running work is moved to queued jobs, not request/response cycle
- [ ] Jobs are idempotent where applicable (safe retry behavior)
- [ ] Retry/backoff/timeout settings are explicit for non-trivial jobs
- [ ] External calls have timeouts and failure handling
- [ ] Critical async flows have failure visibility (logs/alerts/retry strategy)

## Wiring (Laravel bootstrap/providers)

- [ ] Service container bindings live in service providers
- [ ] Constructor injection is used instead of resolving dependencies manually in methods
- [ ] No business logic in routes/service providers/bootstrap code
- [ ] Route definitions use proper middleware/auth/policy protections
- [ ] Nginx/Laravel entry flow assumptions are respected (public entrypoint, no bypass patterns)

## Dependencies

- [ ] New dependency is from the approved list (see [dependencies.md](./dependencies.md))
- [ ] If proposing a new dependency — justification provided
- [ ] No unnecessary dependencies introduced when framework-native features already solve it

## Migrations

- [ ] New migration is generated with Laravel conventions and clear naming
- [ ] When modifying columns, all existing attributes are preserved in the migration
- [ ] Rollback migration (`down`) is included and valid
- [ ] Indexes/constraints are added for correctness and query performance
- [ ] Migration tested locally before committing

## Git and commit hygiene

- [ ] Commit message follows Conventional Commits format (`<type>: <summary>`)
- [ ] One logical change per commit
- [ ] No secrets or `.env` files in the changeset
- [ ] `composer.lock` and frontend lockfile changes are intentional and consistent
- [ ] Branch is rebased onto latest `main` / `master`

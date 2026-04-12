# Architecture Overview

This document set defines the architecture, conventions, and development rules for Laravel + Inertia (Vue 3) + Tailwind services deployed behind Nginx. It is designed to be used as context for AI coding agents and as a reference for human developers.

## Technology stack

- **Language**: PHP 8.3 + JavaScript (Vue 3)
- **Backend framework**: Laravel 12
- **Frontend transport**: Inertia.js v2
- **UI layer**: Vue 3 + Tailwind CSS v3
- **Web server**: Nginx (reverse proxy / static assets / TLS termination)
- **Database**: PostgreSQL / MySQL (via Eloquent ORM)
- **Cache / queues**: Redis (cache, session, queue drivers)
- **Observability**: Laravel logging stack (Monolog), Telescope, optional OpenTelemetry integration
- **CLI / tooling**: Artisan, Composer, pnpm
- **Testing**: PHPUnit feature + unit tests

## Reading order

Read the documents in this order — each one builds on knowledge from the previous:

1. **[Architecture](./architecture.md)** — start here. Core design rules: layered Laravel architecture (domain, application, infrastructure boundaries), DDD-inspired modeling when needed (entities, value objects, aggregates), request/action/service separation, naming conventions, and project folder structure with annotated directory trees.

2. **[PHP](./php.md)** — PHP-specific conventions: naming, typing, class design, control flow, error handling, Laravel integration patterns.

3. **[Configuration](./configs.md)** — Laravel config conventions: `config/*.php` ownership, environment variable naming, `.env` usage boundaries, config caching, and runtime validation strategy.

4. **[CMD / Wiring](./cmd.md)** — the application composition root: service provider wiring, container bindings, route/middleware registration, queue worker lifecycle, and deployment-aware bootstrap flow.

5. **[Error Handling](./error_handling.md)** — exception taxonomy, domain/application exception mapping, validation and authorization failure handling, global render/report strategy, and fail-safe policy.

6. **[Logging](./logging.md)** — Laravel/Monolog-based logging: channel strategy, contextual logging, per-component naming, log levels, and what to log vs redact.

7. **[Observability](./observability.md)** — tracing and metrics strategy: request/job span conventions, RED metrics, application and infrastructure metrics, Telescope usage, logs-to-traces correlation, and OTEL Collector integration where used.

8. **[Dependencies](./dependencies.md)** — approved third-party packages by concern. Use these first — only propose an alternative if there is a clear reason.

9. **[Documentation](./documentation.md)** — documentation conventions: PHPDoc and JSDoc expectations, architecture decision notes, what to document and what not to, and docs update workflow.

## Reference documents

These documents are not required for initial reading but should be consulted when relevant:

- **[Security](./security.md)** — security rules across all layers: request validation, CSRF/XSS prevention, auth/session hardening, SQL injection prevention, Nginx/Laravel headers, CORS, rate limiting, dependency vulnerability scanning.

- **[Makefile](./makefile.md)** — standard build and automation targets: install, lint, test, assets, migrations, deploy steps. Every project must follow these conventions.

- **[Anti-patterns](./anti_patterns.md)** — common mistakes with ❌/✅ code examples. Covers architecture violations, Eloquent/query misuse, error handling mistakes, logging pitfalls, and testing errors. Use as a self-check.

- **[Fast Code Review Checklist](./fast_code_review_checklist.md)** — checklist to run before committing or reviewing PRs. Covers architecture, validation/authorization, data access, error handling, logging, testing, and deployment safety.

- **[Git Workflow](./git.md)** — branching strategy, commit message conventions, merge request process, tagging, and pre-commit checks.

- **[Feature Spec Template](./spec/spec.md)** — template for writing feature specifications before implementation. Fill out and attach as context when starting a new feature with an AI agent.

# Architecture Overview

This document set defines the architecture, conventions, and development rules for Laravel services deployed behind Nginx. It is designed to be used as context for AI coding agents and as a reference for human developers.

## Technology stack

- **Language**: PHP
- **Backend framework**: Laravel
- **Web server**: Nginx (reverse proxy / static assets / TLS termination)
- **Database**: PostgreSQL / MySQL (via Eloquent ORM)
- **Cache / queues**: Redis (cache, session, queue drivers)
- **Observability**: Laravel logging stack (Monolog), Telescope, optional OpenTelemetry integration
- **CLI / tooling**: Artisan, Composer
- **Testing**: PHPUnit feature + unit tests

## Conduct routing

Open only documents matching the current target; do not read this directory as a sequence.

| Target or risk | Documents |
|---|---|
| New files, changed responsibilities, or cross-layer flow | [architecture.md](./architecture.md), [anti_patterns.md](./anti_patterns.md), [thin_controller_model.md](./thin_controller_model.md) |
| PHP APIs, typing, comments, or documentation | [php.md](./php.md), [documentation.md](./documentation.md) |
| Configuration or packages | [configs.md](./configs.md), [dependencies.md](./dependencies.md) |
| Artisan commands, providers, queues, or scheduling | [cmd.md](./cmd.md) |
| Exceptions, retries, validation failures, or fallbacks | [error_handling.md](./error_handling.md) |
| Authentication, authorization, external input, or secrets | [security.md](./security.md) |
| Migrations, queries, models, transactions, or schema assumptions | [database-safety.md](./database-safety.md), [database_snapshot.md](./database_snapshot.md), [enums.md](./enums.md) |
| Logs, metrics, or tracing | [logging.md](./logging.md), [observability.md](./observability.md) |
| Tests or test-case design | [testing/php-testing.md](./testing/php-testing.md), [testing/test-cases.md](./testing/test-cases.md) |
| Product/dev specifications | Relevant files under [spec/](./spec/) only |
| Make targets, review checklist, or git workflow | [makefile.md](./makefile.md), [fast_code_review_checklist.md](./fast_code_review_checklist.md), [git.md](./git.md) |

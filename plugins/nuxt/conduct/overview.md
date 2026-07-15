# Architecture Overview

This document set defines architecture and development rules for Nuxt frontend applications.

## Technology stack

- **Runtime**: Nuxt
- **Framework**: Vue
- **Language**: TypeScript (strict)
- **Package manager**: pnpm
- **Testing**: frontend unit/integration/e2e tooling configured in the target project

## Conduct routing

Open only documents matching the current target; do not read this directory as a sequence.

| Target or risk | Documents |
|---|---|
| New files, component responsibility, composables, or cross-layer flow | [architecture.md](./architecture.md), [anti_patterns.md](./anti_patterns.md) |
| Runtime configuration or packages | [configs.md](./configs.md), [dependencies.md](./dependencies.md) |
| Exceptions, failed requests, or user-facing fallbacks | [error_handling.md](./error_handling.md) |
| Authentication, external input, session data, or XSS | [security.md](./security.md) |
| Pinia or shared state | [stores.md](./stores.md) |
| Logs, metrics, or tracing | [logging.md](./logging.md), [observability.md](./observability.md) |
| Public APIs or documentation | [documentation.md](./documentation.md) |
| Tests or test-case design | [testing/test-cases.md](./testing/test-cases.md) |
| Product/dev specifications | Relevant files under [spec/](./spec/) only |
| CLI, Make targets, review checklist, or git workflow | [cmd.md](./cmd.md), [makefile.md](./makefile.md), [fast_code_review_checklist.md](./fast_code_review_checklist.md), [git.md](./git.md) |

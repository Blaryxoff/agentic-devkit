# Express Conduct

Apply these rules to Express APIs and their Node workers. Read the workspace manifest, lockfile, router registration, middleware, and runner configuration first. Preserve the installed Express major; Express 4 and 5 handle rejected route promises differently.

## Routing

- Routes, services, dependency boundaries, or startup/shutdown → [architecture.md](./architecture.md).
- Feature design/specification, jobs/events contract, or edge rollout → [specification.md](./specification.md).
- New/moved responsibilities or code review → [anti_patterns.md](./anti_patterns.md) and risk-matched rules.
- Failure mapping, cancellation, retry, or async ownership → [error_handling.md](./error_handling.md).
- TypeScript contracts/statuses → [typed-javascript.md](../../core/conduct/typed-javascript.md).
- Config, package choice, CLI, Make/task scripts, or bootstrap → [runtime-configuration.md](../../core/conduct/runtime-configuration.md).
- Logging, metrics, tracing, health, or operations → [logging-observability.md](../../core/conduct/logging-observability.md).
- Input, cookies, bearer tokens, workspaces, uploads, outbound URLs, or logging → [security.md](./security.md).
- BullMQ, Redis, SSE, WebSockets, Yjs, vectors, storage, or provider calls → [integrations.md](./integrations.md).
- Drizzle queries or migrations → `plugins/drizzle/conduct/overview.md` when `devkit-drizzle` is enabled; otherwise inspect the project's selected persistence adapter.
- Tests or verification → [testing.md](./testing.md).

## Boundaries

- Keep routers responsible for transport, boundary validation, and middleware composition; put business operations in feature services using the project's existing module pattern.
- Pass authenticated actor and tenant scope explicitly into operations, jobs, and integrations. Scope every object lookup and mutation, including nested resources and background work.
- Use the project's error path consistently. In Express 4, catch async rejections and forward to `next(error)` or use the existing wrapper; Express 5 forwards returned rejected promises automatically. Detached promises still need explicit ownership.
- Keep this plugin independent of Nest decorators, DI containers, and ORM choices. Reuse installed libraries; do not introduce a framework migration as routine cleanup.

## Sources

- [Express 4 error handling](https://expressjs.com/en/4x/guide/error-handling/) and [Express 5 migration](https://expressjs.com/en/guide/migrating-5.html).
- [Express production security](https://expressjs.com/en/advanced/best-practice-security.html).

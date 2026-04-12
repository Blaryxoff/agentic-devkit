# Dependencies

This is a list of dependencies that you should try to use first. Only if you think they are not optimal for the task —
propose an alternative with a clear justification.

## Internal packages (project-first)

Several core packages are already part of this Laravel application and should be treated as first-party choices. Prefer
framework-native features and already-installed packages before adding new libraries.

> See [php.md](./php.md) for primary language rules, and follow existing project conventions first.
>
> Full package list is intentionally **not duplicated here**. Use `composer.json` as the source of truth for all current
> installed packages and versions.

| Package                     | Purpose                                                                     |
|-----------------------------|-----------------------------------------------------------------------------|
| `laravel/framework`         | Core framework (routing, container, queue, cache, events, HTTP, validation) |
| `inertiajs/inertia-laravel` | Server adapter for Inertia responses and shared props                       |
| `@inertiajs/vue3`           | Inertia client adapter for Vue pages/forms/navigation                       |
| `laravel/sanctum`           | Token/session-based auth for API + SPA patterns                             |
| `tightenco/ziggy`           | Route name sharing from Laravel to Vue                                      |
| `tailwindcss`               | Utility-first styling system for frontend UI                                |
| `dedoc/scramble`            | OpenAPI docs generation for API routes/controllers                          |
| `stancl/tenancy`            | Multi-tenant architecture boundaries and runtime context                    |
| `laravel/scout`             | Search abstraction and indexing flow conventions                            |
| `spatie/laravel-query-builder` | API filter/sort/include conventions for query endpoints                  |
| `lorisleiva/laravel-actions` | Action/use-case organization patterns used across app flows                |
| `spatie/laravel-medialibrary` | Media/file lifecycle conventions                                         |
| `spatie/laravel-activitylog` | Activity/audit logging conventions                                         |

## Adding new dependencies

Before adding a new dependency:

1. Check if the task can be solved with Laravel core, existing packages, or native browser APIs
2. If not — propose the dependency with reasoning: why existing options don't work, what problem it solves
3. Prefer well-maintained, widely-used libraries with active communities

## HTTP

- **Server**: `laravel/framework` routing + middleware + controllers — default web/API transport layer
    - **API auth**: `laravel/sanctum` — token/session auth for SPA/API flows
    - **Rate limiting**: Laravel rate limiter (`Illuminate\Cache\RateLimiting\Limit`)
- **API documentation**: `dedoc/scramble` — OpenAPI docs generation for Laravel routes/controllers (already used in
  project)
- **Client (server-side)**: `Illuminate\Support\Facades\Http` — Laravel HTTP client with timeout/retry/middleware
  support
- **Client (frontend)**: browser `fetch` / Inertia requests via `@inertiajs/vue3` helpers
- **OpenAPI/Swagger alternatives** (optional): propose only if Scramble cannot satisfy a specific requirement, with
  clear justification

## Message Broker

- **Queues/events first**: use Laravel queues/events before introducing external broker dependencies
    - Queue backends: database/redis/sqs via Laravel queue drivers
    - Wrap broker/queue interactions behind contracts, never call low-level clients directly in domain services
- If Kafka (or another broker) is required, isolate it in infrastructure adapters and keep core/application unaware of
  vendor client types

## Database

- **ORM**: Eloquent (`Illuminate\Database\Eloquent`) — default for domain persistence and relationships
- **Query Builder**: `Illuminate\Database\Query\Builder` — use for complex read queries/performance-sensitive paths
- **Migrations**: Laravel migrations in `database/migrations` — version-controlled schema changes
- **Factories/seeders**: Laravel factories and seeders for test/dev data setup
- **Decimal for money**: use `decimal` database columns + explicit casts/value objects, never floating-point for money

## Cache

- **Cache abstraction**: Laravel cache (`Illuminate\Support\Facades\Cache`)
- **Redis**: Laravel Redis integration (`Illuminate\Redis`) when Redis is used as store/backend

## Observability

- **Logging**: Laravel logging stack (`Monolog` via `config/logging.php`)
- **Errors/exceptions**: framework exception handling + `report()` pipeline
- **Tracing/metrics**: use project-approved integration only when needed; keep instrumentation behind application
  boundaries

## Frontend (Inertia + Vue + Tailwind)

- **UI framework**: `vue` + `@inertiajs/vue3`
- **Styling**: `tailwindcss`
- **Formatting/linting**: `prettier`, `eslint`
- **Route helpers**: `ziggy-js` (via `tightenco/ziggy`)
- Prefer existing shared components and composables before introducing new frontend utility libraries

## Runtime / Web server (Nginx)

- Nginx is runtime infrastructure (reverse proxy, static assets, gzip/cache headers, request limits)
- Application behavior/config belongs in Laravel config and code, not in Nginx business rules
- Do not add app-level dependencies to solve concerns that should be handled by Nginx (static caching, compression, TLS
  termination)

## General / Shared

- **Validation**: Laravel Form Requests (`Illuminate\Foundation\Http\FormRequest`)
- **Authorization**: Laravel policies/gates
- **Jobs**: Laravel queued jobs (`ShouldQueue`)
- **UUID/ULID**: `Illuminate\Support\Str::uuid()` / `Str::ulid()` (or Eloquent key casting strategy)
- **Testing**: PHPUnit + Laravel test helpers (`php artisan test`)
- **Browser/integration checks**: use project-approved tools/workflows only when needed; keep tests deterministic

## Forbidden

These should **never** be used:

| Forbidden                                             | Use instead                            |
|-------------------------------------------------------|----------------------------------------|
| `env()` outside config files                          | `config(...)`                          |
| Raw PHP superglobals in app logic (`$_POST`, `$_GET`) | `Request` / Form Request               |
| Direct SQL string concatenation                       | Eloquent / Query Builder with bindings |
| `float` for money calculations                        | decimal columns + value objects/casts  |
| Business logic in controllers/routes/views            | services/use-cases/domain layer        |
| Exposing secrets via `VITE_*`                         | server-only env + backend config       |

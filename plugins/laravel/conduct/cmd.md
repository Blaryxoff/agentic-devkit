# CMD / Wiring rules

The application bootstrap layer is the composition root of the application — its only responsibility is to wire dependencies and start the app. No business logic belongs here.

## General rules

- Bootstrap/Providers are the **only place** allowed to load env-driven config for wiring (`config/*` + container bindings)
- Bootstrap/Providers are the **only place** allowed to define global logger channels/handlers wiring — logger is then used in lower layers
- Entrypoints (`public/index.php`, `artisan`) are the **only place** allowed to terminate process flow directly with exit codes
- Keep bootstrap/providers focused on wiring; move business logic, conditionals, and data transformations into services/use-cases.
- Fail fast on startup errors with descriptive exceptions or log entries.

## Structure

- `public/index.php` — HTTP entrypoint, framework bootstrap only
- `artisan` — CLI entrypoint, framework bootstrap only
- `app/Providers/AppServiceProvider.php` — container bindings and wiring
- additional providers (`EventServiceProvider`, domain-specific providers) — each file wires its own dependency tree
- with CQRS: separate command/query handlers and bind them explicitly in providers

## Wiring order (must be followed)

Wiring inside providers/bootstrap must follow this order, with comments grouping each section:

```php
// 1. Config
// 2. Logging
// 3. Clients
// 4. Repositories
// 5. Services / Use-cases
// 6. HTTP / Jobs / Listeners
// 7. Run (Nginx -> PHP-FPM -> Laravel)
// 8. Termination hooks / cleanup
```

This matches the dependency direction and makes the wiring easy to read and audit.

## Full wiring example (AppServiceProvider)

```php
// AppServiceProvider::register()
public function register(): void
{
    // 1. Config
    $notificationConfig = config('services.notification');
    // 2. Logging — configured in config/logging.php
    // 3. Clients
    $this->app->singleton(NotificationClient::class, fn () => new NotificationClient(
        baseUrl: $notificationConfig['base_url'],
        apiKey: $notificationConfig['api_key'],
    ));
    // 4. Repositories
    $this->app->bind(UserRepository::class, EloquentUserRepository::class);
    // 5. Services / Use-cases
    $this->app->singleton(UserService::class, fn ($app) => new UserService(
        $app->make(UserRepository::class),
        $app->make(NotificationClient::class),
    ));
    // 6. HTTP / Jobs / Listeners — auto-resolved from container
    // 7. Run — runtime path only
    // 8. Termination hooks / cleanup
}
```

## MustLoad() relationship (Laravel equivalent)

- Config files in `config/*.php` aggregate env-driven values
- `env()` is read only in config files; app code uses `config(...)`
- Bootstrap/providers are the **only place** where low-level wiring decisions should be made from config
- Inject primitive configuration values or dependencies into services and repositories.

## Graceful shutdown

- HTTP lifecycle is terminated by Laravel Kernel (`$kernel->terminate($request, $response)`)
- Let Nginx and PHP-FPM manage web worker/process lifecycle; use framework lifecycle hooks for application cleanup.
- Queue workers and long-running consumers must support graceful stop (`php artisan queue:work` with proper timeout/retry/stop settings)
- If a component needs cleanup on shutdown (closing sockets, flushing buffers), encapsulate it behind framework lifecycle hooks (terminating middleware, queue events, service destructor patterns)

## Constructor rules

- Use explicit dependency injection and type hints in constructors so domain/application dependencies stay visible.
- Config primitives should be passed explicitly (from `config(...)`) or wrapped in typed config objects
- Pass request-scoped values to methods rather than constructors.
- Defer heavy I/O from constructors to explicit methods.

## Entrypoints

- `public/index.php` and `artisan` must stay minimal — only bootstrap framework and dispatch
- All wiring lives in service providers/container bindings, not in entry files directly

## Apply these practices

- follow the 8-step wiring order strictly
- fail fast with descriptive startup errors
- bind contracts to implementations in providers
- pass config/dependencies via DI, not globals

## Replace these patterns

- Keep business logic in services/use-cases, configuration reads in config files, and process termination in entrypoints.
- Pass dependencies through provider wiring and dependency injection.
- Add lifecycle cleanup for long-running workers/consumers.

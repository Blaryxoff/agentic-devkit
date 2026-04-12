# CMD / Wiring rules

The application bootstrap layer is the composition root of the application — its only responsibility is to wire dependencies and start the app. No business logic belongs here.

## General rules

- Bootstrap/Providers are the **only place** allowed to load env-driven config for wiring (`config/*` + container bindings)
- Bootstrap/Providers are the **only place** allowed to define global logger channels/handlers wiring — logger is then used in lower layers
- Entrypoints (`public/index.php`, `artisan`) are the **only place** allowed to terminate process flow directly with exit codes
- No business logic, conditionals, or data transformations in bootstrap/providers — if you feel the need, it belongs in a service/use-case
- All errors during startup must fail fast with descriptive exceptions/log entries — never silently ignored

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

## root.go equivalent example (public/index.php)

```php
<?php

use Illuminate\Contracts\Http\Kernel;
use Illuminate\Http\Request;

define('LARAVEL_START', microtime(true));

require __DIR__.'/../vendor/autoload.php';

$app = require_once __DIR__.'/../bootstrap/app.php';

$kernel = $app->make(Kernel::class);

$response = $kernel->handle(
    $request = Request::capture()
)->send();

$kernel->terminate($request, $response);
```

## Full wiring example (AppServiceProvider)

```php
<?php

namespace App\Providers;

use App\Application\User\Services\UserService;
use App\Domain\User\Contracts\UserRepository;
use App\Infrastructure\Clients\NotificationClient;
use App\Infrastructure\Persistence\User\EloquentUserRepository;
use Illuminate\Support\ServiceProvider;

final class AppServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        // 1. Config
        $notificationConfig = config('services.notification');

        // 2. Logging
        // Logging channels are configured in config/logging.php and used via Log facade

        // 3. Clients
        $this->app->singleton(NotificationClient::class, function () use ($notificationConfig) {
            return new NotificationClient(
                baseUrl: $notificationConfig['base_url'],
                apiKey: $notificationConfig['api_key'],
            );
        });

        // 4. Repositories
        $this->app->bind(UserRepository::class, EloquentUserRepository::class);

        // 5. Services / Use-cases
        $this->app->singleton(UserService::class, function ($app) {
            return new UserService(
                $app->make(UserRepository::class),
                $app->make(NotificationClient::class),
            );
        });

        // 6. HTTP / Jobs / Listeners
        // Controllers, jobs, and listeners resolve dependencies from the container automatically

        // 7. Run (Nginx -> PHP-FPM -> Laravel)
        // Runtime path only; no app logic here

        // 8. Termination hooks / cleanup
        // Use terminating middleware, queue worker stop hooks, or service destructors if needed
    }
}
```

## MustLoad() relationship (Laravel equivalent)

- Config files in `config/*.php` aggregate env-driven values
- `env()` is read only in config files; app code uses `config(...)`
- Bootstrap/providers are the **only place** where low-level wiring decisions should be made from config
- Services and repositories never read env directly — they receive primitive values/dependencies via DI

## Graceful shutdown

- HTTP lifecycle is terminated by Laravel Kernel (`$kernel->terminate($request, $response)`)
- Nginx and PHP-FPM handle worker/process lifecycle externally; app code should not implement custom process signal loops for normal web requests
- Queue workers and long-running consumers must support graceful stop (`php artisan queue:work` with proper timeout/retry/stop settings)
- If a component needs cleanup on shutdown (closing sockets, flushing buffers), encapsulate it behind framework lifecycle hooks (terminating middleware, queue events, service destructor patterns)

## Constructor rules

- Constructors should follow explicit dependency injection and type hints — never hide dependencies via service locators in domain/application code
- Config primitives should be passed explicitly (from `config(...)`) or wrapped in typed config objects
- Avoid passing request context into constructors; pass request-scoped values to methods
- Never perform heavy I/O in constructors — defer side effects to explicit methods

## main.go equivalent

- `public/index.php` and `artisan` must stay minimal — only bootstrap framework and dispatch
- All wiring lives in service providers/container bindings, not in entry files directly

```php
<?php

// artisan (simplified)

require __DIR__.'/vendor/autoload.php';

$app = require_once __DIR__.'/bootstrap/app.php';

$status = $app->make(Illuminate\Contracts\Console\Kernel::class)->handle(
    $input = new Symfony\Component\Console\Input\ArgvInput,
    new Symfony\Component\Console\Output\ConsoleOutput
);

exit($status);
```

## DO / DO NOT

**DO:**
- follow the 8-step wiring order strictly
- fail fast with descriptive startup errors
- bind contracts to implementations in providers
- pass config/dependencies via DI, not globals

**DO NOT:**
- put business logic in bootstrap/providers
- read `env()` outside config files
- terminate process flow from domain/application layers
- hide dependencies behind facades/service locator in domain core
- skip lifecycle cleanup for long-running workers/consumers

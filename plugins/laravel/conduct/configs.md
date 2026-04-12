# Configuration

## Basic

### Every module that needs configuration should have a dedicated config entry in `config/*.php`

Example:

```php
// config/services.php
return [
    'mint' => [
        'burn_topic' => env('MINT_BURN_TOPIC'),
        'mint_topic' => env('MINT_MINT_TOPIC'),
    ],
];
```

### Config files should aggregate child module configs

Core/domain-facing settings should be separated from infrastructure/runtime settings.

Example:

```php
// config/app_modules.php
return [
    'core' => [
        'user_service' => [
            'default_role' => env('USER_SERVICE_DEFAULT_ROLE', 'user'),
        ],
    ],

    'infrastructure' => [
        'database' => [
            'connection' => env('DB_CONNECTION', 'mysql'),
        ],
        'queue' => [
            'default' => env('QUEUE_CONNECTION', 'database'),
        ],
        'cache' => [
            'store' => env('CACHE_STORE', 'database'),
        ],
    ],
];
```

### Environment variables

- `.env.example` should be created with examples of used variables (sensitive variables should always be empty or placeholder)
- `.env` should be added to `.gitignore`

#### `.env.example` example

```env
# ── Application ───────────────────────────────────────────────────────────────
APP_NAME=GrowPlace
APP_ENV=local
APP_KEY=
APP_DEBUG=true
APP_URL=http://grow-place.test

# ── Database ──────────────────────────────────────────────────────────────────
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=grow_place
DB_USERNAME=root
DB_PASSWORD=

# ── Queue / Cache ─────────────────────────────────────────────────────────────
QUEUE_CONNECTION=database
CACHE_STORE=database
REDIS_HOST=127.0.0.1
REDIS_PASSWORD=
REDIS_PORT=6379

# ── Frontend / Inertia / Vite ────────────────────────────────────────────────
VITE_APP_NAME="GrowPlace"
```

## Populating config values

There are two ways to populate config values:

- Laravel config files with environment variables (recommended)
- environment variables only (for very small/simple scripts only)

### Laravel config files with environment variables (recommended)

- use `config/*.php` as the only source of config mapping
- values with sensitive data (secrets, passwords etc.) should be passed using environment variables
- use defaults only for non-sensitive and safe fallback values
- after loading, critical config should be validated early (startup checks / health checks)

#### `config/app.php` example

```php
return [
    'name' => env('APP_NAME', 'Laravel'),
    'env' => env('APP_ENV', 'production'),
    'debug' => (bool) env('APP_DEBUG', false),
    'url' => env('APP_URL', 'http://localhost'),
];
```

#### `config/services.php` example

```php
return [
    'notification' => [
        'base_url' => env('NOTIFICATION_BASE_URL'),
        'api_key' => env('NOTIFICATION_API_KEY'),
        'timeout' => (int) env('NOTIFICATION_TIMEOUT', 10),
    ],
];
```

### Environment variables only

- for framework code, avoid reading `$_ENV` / `getenv()` / `env()` directly outside config files
- if a small bootstrap script must use env-only values, map them once into typed variables and validate immediately
- application code should still consume values through `config(...)` abstraction

Example:

```php
// bootstrap/runtime_check.php (example for script/bootstrap only)
$appUrl = getenv('APP_URL') ?: null;
$appEnv = getenv('APP_ENV') ?: 'production';

if ($appUrl === null) {
    throw new RuntimeException('APP_URL is required');
}
```

In the normal Laravel flow, the same value should be consumed as `config('app.url')`.

## Config validation

Validate critical config immediately after loading. Use a validator class / startup check:

```php
<?php

namespace App\Support\Config;

use InvalidArgumentException;

final class NotificationConfigValidator
{
    public static function validate(): void
    {
        $baseUrl = config('services.notification.base_url');
        $timeout = config('services.notification.timeout');

        if (! is_string($baseUrl) || $baseUrl === '') {
            throw new InvalidArgumentException('services.notification.base_url is required');
        }

        if (! is_int($timeout) || $timeout < 1 || $timeout > 120) {
            throw new InvalidArgumentException('services.notification.timeout must be between 1 and 120');
        }
    }
}
```

Call validation in bootstrap/provider:

```php
public function boot(): void
{
    NotificationConfigValidator::validate();
}
```

## Secrets management

- **Local/dev**: use `.env` file (never committed) or environment variables
- **Production**: use a secrets manager (Vault, AWS Secrets Manager, Kubernetes Secrets, etc.) — secrets are injected as environment variables at runtime
- never hardcode secrets in config files or source code
- sensitive fields in config files should read from `env(...)`, actual values come from environment
- `.env.example` contains all required variables with empty/placeholder values for secrets — this serves as documentation

## Frontend and runtime config notes (Inertia + Vue + Tailwind + Nginx)

- expose only safe client-side values via `VITE_*` variables
- never expose secrets to frontend runtime (`resources/js/**`)
- Inertia shared props must contain only non-sensitive configuration data
- Tailwind theme tokens/config stay in `tailwind.config.js`; do not duplicate the same tokens in multiple places
- Nginx config (`nginx/*.conf`) should control transport/runtime behavior (gzip, caching headers, request limits), while application behavior stays in Laravel config

## DO / DO NOT

**DO:**
- define config keys in `config/*.php` for every module that needs configuration
- aggregate related config keys in dedicated config files (`services.php`, `queue.php`, `cache.php`, custom module config files)
- validate critical config after loading
- use `.env.example` as documentation for required environment variables
- pass config/dependencies through DI (`config(...)` -> constructor argument), not global reads in business logic

**DO NOT:**
- hardcode configuration values in source code
- commit `.env` files or secrets to git
- read `env()` outside config files in app logic
- skip validation — always check required fields and value ranges for critical config
- expose server secrets into Inertia props or `VITE_*` variables

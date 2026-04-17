# Configuration

## Basic

### Every module that needs configuration should have a dedicated config entry in `config/*.php`

### Config files should aggregate child module configs

Core/domain-facing settings should be separated from infrastructure/runtime settings (e.g. `config/app_modules.php` with `core` and `infrastructure` sections).

### Environment variables

- `.env.example` should be created with examples of used variables (sensitive variables should always be empty or placeholder)
- `.env` should be added to `.gitignore`

Group `.env.example` variables with header comments by concern (`# ── Application`, `# ── Database`, `# ── Queue / Cache`, etc.). Use empty values for secrets.

## Populating config values

There are two ways to populate config values:

- Laravel config files with environment variables (recommended)
- environment variables only (for very small/simple scripts only)

### Laravel config files with environment variables (recommended)

- use `config/*.php` as the only source of config mapping
- values with sensitive data (secrets, passwords etc.) should be passed using environment variables
- use defaults only for non-sensitive and safe fallback values
- cast env values explicitly in config files: `(bool) env('APP_DEBUG', false)`, `(int) env('TIMEOUT', 10)`
- after loading, critical config should be validated early (startup checks / health checks)

### Environment variables only

- for framework code, avoid reading `$_ENV` / `getenv()` / `env()` directly outside config files
- if a small bootstrap script must use env-only values, map them once into typed variables and validate immediately
- application code should still consume values through `config(...)` abstraction

In the normal Laravel flow, the same value should be consumed as `config('app.url')`.

## Config validation

Validate critical config immediately after loading. Create a validator class per module and call it from the service provider's `boot()` method. Throw `InvalidArgumentException` for missing or out-of-range values.

## Secrets management

- **Local/dev**: use `.env` file (never committed) or environment variables
- **Production**: use a secrets manager (Vault, AWS Secrets Manager, Kubernetes Secrets, etc.) — secrets are injected as environment variables at runtime
- never hardcode secrets in config files or source code
- sensitive fields in config files should read from `env(...)`, actual values come from environment
- `.env.example` contains all required variables with empty/placeholder values for secrets — this serves as documentation

## Nginx runtime config notes

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
- expose server secrets in response payloads or client-accessible variables

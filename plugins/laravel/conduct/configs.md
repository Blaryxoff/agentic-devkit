# Configuration

## Basic

### Give every module that needs configuration a dedicated entry in `config/*.php`

### Aggregate child module configs in their parent config file

Separate core/domain-facing settings from infrastructure/runtime settings (e.g. `config/app_modules.php` with `core` and `infrastructure` sections).

### Environment variables

- Create `.env.example` with every variable the app reads; leave sensitive values empty or as placeholders.
- Add `.env` to `.gitignore`.

Group `.env.example` variables with header comments by concern (`# ── Application`, `# ── Database`, `# ── Queue / Cache`, etc.). Use empty values for secrets.

## Populating config values

Populate config values in one of two ways:

- Laravel config files with environment variables (default)
- environment variables only (very small bootstrap scripts only)

### Laravel config files with environment variables (default)

- use `config/*.php` as the only source of config mapping
- pass sensitive values (secrets, passwords etc.) through environment variables
- use defaults only for non-sensitive and safe fallback values
- cast env values explicitly in config files: `(bool) env('APP_DEBUG', false)`, `(int) env('TIMEOUT', 10)`
- validate critical config right after loading (startup checks / health checks)

### Environment variables only

- in framework code, never read `$_ENV` / `getenv()` / `env()` outside config files
- if a small bootstrap script must use env-only values, map them once into typed variables and validate immediately
- consume values in application code through `config(...)`, e.g. `config('app.url')`

## Config validation

Validate critical config immediately after loading. Create a validator class per module and call it from the service provider's `boot()` method. Throw `InvalidArgumentException` for missing or out-of-range values.

## Secrets management

- **Local/dev**: use `.env` file (never committed) or environment variables
- **Production**: use a secrets manager (Vault, AWS Secrets Manager, Kubernetes Secrets, etc.) — secrets are injected as environment variables at runtime
- never hardcode secrets in config files or source code
- read sensitive config fields from `env(...)`; actual values come from the environment
- `.env.example` contains all required variables with empty/placeholder values for secrets — this serves as documentation

## Nginx runtime config notes

- Keep transport/runtime behavior (gzip, caching headers, request limits) in Nginx config (`nginx/*.conf`) and application behavior in Laravel config

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

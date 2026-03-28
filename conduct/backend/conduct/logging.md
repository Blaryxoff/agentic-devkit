# Logging

Logger uses Laravel logging channels from `config/logging.php`, powered by [Monolog](https://github.com/Seldaek/monolog) under the hood.

## Initialization

Should be initialized at the very beginning of the app via framework config (`config/logging.php`) and environment (`LOG_CHANNEL`, `LOG_LEVEL`):

```php
'default' => env('LOG_CHANNEL', 'stack'),
```

## Log levels guide

| Level | When to use | Example |
|-------|-------------|---------|
| `Debug` | Detailed information for diagnosing issues. Disabled in production | Variable values, internal state, step-by-step flow |
| `Info` | Normal application events worth recording | Server started, user created, job completed |
| `Warn` | Something unexpected but recoverable happened | Retry attempt, deprecated API called, slow query |
| `Error` | An operation failed but the application continues | DB query failed, external API returned error |
| `Emergency` | Unrecoverable error — application is unusable. **Only for bootstrap/runtime-critical failures** | Missing required config, failed mandatory connection |

## In methods

Every method at the very beginning should enrich log context inherited from the request/job context, adding method name and key arguments.

```php
public function createUser(array $payload): User
{
    Log::withContext([
        'service' => 'user_service',
        'method' => 'createUser',
        'email' => $payload['email'] ?? null,
    ]);

    Log::debug('creating user');

    try {
        $user = User::query()->create($payload);
    } catch (\Throwable $exception) {
        Log::error('failed to create user', ['exception' => $exception]);
        throw $exception;
    }

    Log::info('user created', ['user_id' => $user->id]);

    return $user;
}
```

**IMPORTANT**: heavy variables should be excluded from logging (ex.: uploaded files, binary payloads). Generic context arrays should be used with care as they can include heavy data.

## Services, clients, repositories and handlers

Must have their own logger context inherited from a parent context with a name description. Example for `UserRepository`:

```php
public function __construct(private readonly UserRepository $repository) {}

public function handle(array $data): User
{
    Log::withContext([
        'service' => 'user_service',
        'repo' => 'user_repository',
    ]);

    return $this->repository->create($data);
}
```

Naming convention for logger components:

| Component | Logger field | Example value |
|-----------|-------------|---------------|
| Service | `"service"` | `"user_service"` |
| Repository | `"repo"` | `"user_repo"` |
| Controller | `"controller"` | `"user_controller"` |
| Job / Listener | `"job"` / `"listener"` | `"sync_payments_job"` |
| Client | `"client"` | `"payment_gateway_client"` |

## Request / correlation ID

When tracing is enabled, always include request/trace context in logs (request ID, trace ID, tenant ID when applicable). This enables correlation between Nginx access/error logs, application logs, and traces.

## Errors

Errors are handled through Laravel exception reporting (`report()` / global handler) and structured `Log::*` calls where needed (see [error handling](./error_handling.md)).

## DO / DO NOT

**DO:**
- create a child logger at the beginning of every method with method name and key arguments
- attach request/job context with `Log::withContext()`
- use structured context arrays (`['user_id' => $userId, 'exception' => $e]`) — avoid string-only concatenation
- log at the right level: Debug for dev, Info for events, Warn for recoverable issues, Error for failures

**DO NOT:**
- log secrets, passwords, tokens, API keys, or PII (emails may be logged only partially: `u***@example.com`)
- log full request/response bodies — log only relevant fields
- log uploaded file content, binary blobs, or large data structures directly — log their length or hash instead
- use `var_dump`, `print_r`, `echo`, or `dump` for runtime logging — always use Laravel `Log`
- use `Log::emergency` for non-critical/recoverable errors
- duplicate error logging — if an exception is reported globally, do not log the same error again at the call site without extra context

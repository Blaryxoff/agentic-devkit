# Error handling

- all errors must be handled
- in rare cases, **after user approval**, they can be omitted, but always visible in code (example: explicit `rescue(...)` / `try-catch` with intentional ignore, and not a silent call)

## Basic error handling

### Every module must have domain errors/exceptions defined in the header

- at least one as a module-level error (ex.: `UserServiceException` for user service)
- if needed, every method call can have its own error, wrapping a main module error as `previous`:

```php
<?php

namespace App\Domain\User\Exceptions;

use RuntimeException;
use Throwable;

final class UserServiceException extends RuntimeException
{
    public static function createUser(Throwable $previous): self
    {
        return new self('userService: createUser', previous: $previous);
    }

    public static function getUser(Throwable $previous): self
    {
        return new self('userService: getUser', previous: $previous);
    }
}
```

### All errors in services and repositories, before being returned upward, should be wrapped in a typed domain exception and reported with Laravel logging/reporting

Use native Laravel mechanisms (`report($e)`, `Log::error()`, exception handler `app/Exceptions/Handler.php`) for logging and context.

#### Usage example

```php
try {
    $user = $this->users->create($payload);
} catch (Throwable $e) {
    report($e);
    throw UserServiceException::createUser($e);
}
```

#### Where wrapping/reporting is and is not required

- **Required**: all services (`app/Services/`, actions/use-cases) and repositories (`app/Repositories/` or equivalent infrastructure layer)
- **Not required**: HTTP controllers (`app/Http/Controllers/`) — controllers should translate domain errors into HTTP/Inertia responses
- **Not required**: external clients/integrations — wrap with a local integration error and return; avoid duplicate logging if upper layer already reports

### Error checking at call sites

- Use `instanceof` and typed exceptions to check for specific domain errors — never compare by message string
- Use `$e->getPrevious()` when you need to inspect wrapped low-level exceptions
- Example:

```php
try {
    $user = $this->userService->getUser($userId);
} catch (UserNotFoundException $e) {
    return response()->json(['message' => 'user not found'], 404);
} catch (Throwable $e) {
    report($e);
    return response()->json(['message' => 'internal error'], 500);
}
```

- Never string-match errors (no `$e->getMessage() === '...'`)

### Avoid double wrapping

Do not wrap an exception again with the same meaning if it was already wrapped at the level below. Each exception should be wrapped exactly once per layer boundary.

```php
// bad — double wrapping (repo already wrapped with UserRepositoryException)
try {
    return $this->userRepository->getById($id);
} catch (Throwable $e) {
    throw new UserServiceException('userService: getUser', previous: $e);
}

// good — catch only domain exceptions you want to translate, pass-through others
try {
    return $this->userRepository->getById($id);
} catch (UserRepositoryNotFoundException $e) {
    throw new UserNotFoundException(previous: $e);
}
```

## Full error chain example (controller → service → repository)

```php
<?php

// --- Repository layer ---
// app/Repositories/UserRepository.php

namespace App\Repositories;

use App\Domain\User\Exceptions\UserRepositoryException;
use App\Domain\User\Exceptions\UserRepositoryNotFoundException;
use App\Models\User;
use Throwable;

final class UserRepository
{
    public function getById(string $id): User
    {
        try {
            return User::query()->findOrFail($id);
        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            throw new UserRepositoryNotFoundException(previous: $e);
        } catch (Throwable $e) {
            report($e);
            throw new UserRepositoryException('userRepo: getById', previous: $e);
        }
    }
}

// --- Service layer ---
// app/Services/UserService.php

namespace App\Services;

use App\Domain\User\Exceptions\UserNotFoundException;
use App\Domain\User\Exceptions\UserServiceException;
use App\Repositories\UserRepository;
use Throwable;

final class UserService
{
    public function __construct(private UserRepository $users)
    {
    }

    public function getUser(string $id): \App\Models\User
    {
        try {
            return $this->users->getById($id);
        } catch (\App\Domain\User\Exceptions\UserRepositoryNotFoundException $e) {
            throw new UserNotFoundException(previous: $e);
        } catch (Throwable $e) {
            report($e);
            throw new UserServiceException('userService: getUser', previous: $e);
        }
    }
}

// --- Controller layer ---
// app/Http/Controllers/UserController.php

namespace App\Http\Controllers;

use App\Domain\User\Exceptions\UserNotFoundException;
use App\Services\UserService;
use Illuminate\Http\JsonResponse;
use Throwable;

final class UserController extends Controller
{
    public function __construct(private UserService $users)
    {
    }

    public function show(string $id): JsonResponse
    {
        try {
            $user = $this->users->getUser($id);
        } catch (UserNotFoundException $e) {
            return response()->json(['message' => 'user not found'], 404);
        } catch (Throwable $e) {
            report($e);
            return response()->json(['message' => 'internal error'], 500);
        }

        return response()->json(['data' => $user]);
    }
}
```

## HTTP controller error handling

- controllers should translate domain/repository errors into HTTP status codes using typed exceptions
- never expose internal error details to the client — return generic messages
- use a consistent error response structure:

```php
return response()->json([
    'message' => 'internal error',
], 500);
```

- common mappings:
  - `NotFound` exceptions → `404 Not Found`
  - `AlreadyExists` / duplicate key exceptions → `409 Conflict`
  - validation errors (`ValidationException`) → `422 Unprocessable Entity`
  - authorization errors (`AuthorizationException`) → `403 Forbidden`
  - authentication errors (`AuthenticationException`) → `401 Unauthorized`
  - everything else → `500 Internal Server Error`

## Inertia + Vue error handling

- for Inertia requests, return domain-safe errors via redirects and session flash (or shared props), not raw stack traces
- keep validation in FormRequest and surface via Inertia form errors
- use dedicated error pages (`resources/js/Pages/Errors/*.vue`) for `403/404/500`
- in Vue, always handle failed form submissions (`onError`, `errors`) and avoid swallowing Promise rejections

## Nginx and edge error handling

- Nginx should return standard upstream errors (`502/503/504`) without exposing internal PHP-FPM details
- keep `APP_DEBUG=false` in production so framework exceptions are not exposed to clients
- define error pages/behaviour consistently between Nginx and Laravel exception rendering
- propagate correlation/request IDs through Nginx and Laravel logs for incident tracing

## Panic usage

- fatal exits are **only allowed in application bootstrap** for unrecoverable misconfiguration (missing required config, failed mandatory connection)
- abrupt process termination from normal request/business code is **strictly forbidden** — throw/return typed exceptions instead
- never recover silently from fatal conditions; if recovery middleware/handler is used, it must log full context and return a safe error response

## DO / DO NOT

**DO:**
- define typed domain exceptions at module boundaries
- wrap low-level exceptions into domain/application exceptions in services/repositories
- use typed `catch` blocks (`instanceof`) at call sites
- translate domain exceptions to HTTP/Inertia responses in controllers/handlers

**DO NOT:**
- compare errors by message string
- string-match exceptions with `$e->getMessage() === '...'`
- double-wrap exceptions with the same semantics
- expose internal exception messages to API or Inertia clients
- terminate request flow abruptly in business code
- silently ignore exceptions — make intentional suppression explicit

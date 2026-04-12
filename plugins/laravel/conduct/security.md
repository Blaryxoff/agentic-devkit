# Security rules

Security rules apply across all layers. Every developer and AI agent working on this codebase must follow these guidelines.

## Input validation

- validate all external input at the controller/request boundary before it reaches service/domain logic
- never trust data from HTTP requests, Inertia form payloads, queued jobs, webhooks, or any external source
- use Form Request classes and value objects for validation — invalid input must be rejected early:

```php
// controller receives raw input, passes through Form Request rules
// invalid payload is rejected before business logic executes
final class UserController extends Controller
{
    public function store(StoreUserRequest $request, UserService $service): JsonResponse
    {
        $validated = $request->validated();

        $user = $service->createUser($validated['email']);

        return response()->json(['id' => $user->id], 201);
    }
}
```

- never pass raw user input directly to database queries — always use Eloquent/query builder parameter binding
- validate string lengths, numeric ranges, and enum values explicitly in Form Request rules and domain/value objects when applicable

## SQL injection

Eloquent and query builder use parameterized queries by default — **never use raw string interpolation**:

```php
// ❌ WRONG — SQL injection vulnerability
DB::select("SELECT * FROM users WHERE email = '{$email}'");
User::query()->whereRaw("email = '{$email}'")->first();

// ✅ CORRECT — parameterized query
User::query()->where('email', $email)->first();
DB::select('SELECT * FROM users WHERE email = ?', [$email]);
```

## Authentication and tokens

- use Laravel authentication features (session auth, Sanctum, policies/gates) as the default
- if JWT is required, always validate token signature and expiry (`exp`) before accepting claims
- always check token audience/issuer where applicable
- store token secrets/keys in environment variables or secret manager, never in source code
- use short-lived access tokens and explicit revocation strategy for refresh/session tokens

```php
// ❌ WRONG — decoding claims without verification
$payload = json_decode(base64_decode(explode('.', $token)[1] ?? ''), true);

// ✅ CORRECT — verify signature and claims before trust
use Firebase\JWT\JWT;
use Firebase\JWT\Key;

$decoded = JWT::decode($token, new Key(config('services.jwt.public_key'), 'RS256'));
```

## Secrets management

- **never** hardcode secrets (API keys, passwords, tokens, private keys) in source code or config values
- **never** log secrets — see [logging.md](./logging.md)
- **never** include secrets in error messages returned to clients
- use environment variables for all secrets; in production use a secret manager (Vault, cloud secret manager, container secrets)
- rotate secrets with minimal downtime; avoid code changes for secret rotation
- `.env.example` documents variable names with **empty** values for secrets

## Password handling

- **never** store plain-text passwords — always hash with Laravel hashing (`bcrypt` / `argon2id`)
- **never** compare passwords with `==` — use Laravel hash comparison

```php
use Illuminate\Support\Facades\Hash;

// hashing
$hashed = Hash::make($plainPassword);

// comparison — use Hash::check, never ==
if (! Hash::check($inputPassword, $storedHash)) {
    throw ValidationException::withMessages([
        'email' => __('auth.failed'),
    ]);
}
```

## HTTP security headers

Configure security headers at the Nginx layer and enforce app-level policy where needed:

```nginx
add_header X-Content-Type-Options "nosniff" always;
add_header X-Frame-Options "DENY" always;
add_header Referrer-Policy "strict-origin-when-cross-origin" always;
add_header Content-Security-Policy "default-src 'self'" always;
add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
```

## CORS

- configure CORS explicitly — never use wildcard `*` origins in production with credentials enabled
- whitelist specific origins per environment via `config/cors.php`

```php
return [
    'paths' => ['api/*', 'sanctum/csrf-cookie'],
    'allowed_methods' => ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
    'allowed_origins' => explode(',', env('CORS_ALLOWED_ORIGINS', '')),
    'allowed_headers' => ['Content-Type', 'X-Requested-With', 'Authorization', 'X-CSRF-TOKEN'],
    'supports_credentials' => true,
];
```

## Rate limiting

- apply rate limiting to all public and authentication endpoints
- use Laravel rate limiter definitions and `throttle` middleware; use Redis-backed limits in distributed setups

```php
// routes/api.php
Route::middleware('throttle:api')->group(function () {
    Route::post('/login', [AuthController::class, 'login']);
    Route::post('/password/email', [ForgotPasswordController::class, 'store']);
});
```

## TLS

- in production all browser and service traffic must use TLS — no plain HTTP for public endpoints
- TLS certificates are managed by infrastructure (Nginx/ingress/load balancer), not by application code
- never disable TLS verification in HTTP clients (`verify => false`) except tightly scoped local development tooling
- configure Laravel trusted proxies correctly so scheme/host are resolved safely behind Nginx

## Dependency security

- run dependency vulnerability scans regularly (`composer audit`, `pnpm audit`)
- keep security advisory packages and CI checks enabled for Composer dependencies
- add dependency security checks to CI as required gates

```bash
composer audit
pnpm audit --prod
```

## Error messages to clients

- **never** return internal error details, stack traces, SQL errors, or vendor exception messages to clients
- return generic user-facing messages; log/report the real exception server-side:

```php
// ❌ WRONG — leaks internal details
return response()->json(['error' => $exception->getMessage()], 500);

// ✅ CORRECT — generic client message, full error reported server-side
report($exception);

return response()->json([
    'message' => 'Internal server error',
], 500);
```

## DO / DO NOT

**DO:**
- validate all external input via Form Requests at the request boundary
- use parameterized queries via Eloquent/query builder
- hash passwords with Laravel `Hash` before storing
- set security headers via Nginx and enforce app security middleware/policies
- run dependency vulnerability checks in CI

**DO NOT:**
- hardcode secrets anywhere in source code or config values
- log secrets, passwords, tokens, or unnecessary PII
- use wildcard CORS origins in production when credentials are enabled
- disable TLS verification in production HTTP clients
- return raw internal errors to API clients
- compare passwords with `==` — always use hash comparison

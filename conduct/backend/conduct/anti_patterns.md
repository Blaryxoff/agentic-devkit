# Anti-patterns

This document contains common mistakes and their corrections. Every example shows the **wrong** way first, then the *
*correct** way. Use this as a reference to avoid repeating known bad patterns.

## Architecture anti-patterns

### AP-1: Core imports adapter

```php
<?php

// ❌ WRONG — core depends on adapter
namespace App\Domain\User\Services;

use App\Infrastructure\Repositories\EloquentUserRepository;

final class UserService
{
    public function __construct(private EloquentUserRepository $repo)
    {
    }
}
```

```php
<?php

// ✅ CORRECT — core depends on contract interface
namespace App\Domain\User\Services;

use App\Domain\User\Contracts\UserRepository;

final class UserService
{
    public function __construct(private UserRepository $repo)
    {
    }
}
```

### AP-2: Business logic in controller

```php
<?php

// ❌ WRONG — controller contains business rules
public function store(Request $request): RedirectResponse
{
    $amount = (float) $request->input('amount');

    // business logic leaked into controller
    if ($amount < 10) {
        return back()->withErrors(['amount' => 'minimum order is 10']);
    }

    $discount = 0;
    if ($amount > 100) {
        $discount = $amount * 0.1;
    }

    $finalAmount = $amount - $discount;
    Order::query()->create(['amount' => $finalAmount]); // controller hits model directly

    return redirect()->route('orders.index');
}
```

```php
<?php

// ✅ CORRECT — controller delegates to service, logic lives in domain
public function store(StoreOrderRequest $request, OrderService $orderService): RedirectResponse
{
    try {
        $orderService->createOrder($request->validated());
    } catch (MinimumOrderException $e) {
        return back()->withErrors(['amount' => 'minimum order is 10']);
    }

    return redirect()->route('orders.index');
}
```

### AP-3: Adapter imports another adapter

```php
<?php

// ❌ WRONG — controller orchestrates infrastructure adapters directly
final class OrderController extends Controller
{
    public function store(Request $request, StripeClient $stripe, SlackNotifier $notifier): RedirectResponse
    {
        $paymentId = $stripe->charge((int) $request->input('amount'));
        $notifier->send("order paid: {$paymentId}");

        return redirect()->route('orders.index');
    }
}
```

```php
<?php

// ✅ CORRECT — controller depends on application service, service orchestrates adapters
final class OrderController extends Controller
{
    public function __construct(private OrderService $orderService)
    {
    }

    public function store(StoreOrderRequest $request): RedirectResponse
    {
        $this->orderService->createOrder($request->validated());

        return redirect()->route('orders.index');
    }
}
```

## Laravel + PHP anti-patterns

### AP-4: Passing unvalidated arrays instead of typed data

```php
<?php

// ❌ WRONG — unvalidated array, easy to pass wrong shape
public function createUser(array $payload): User
{
    return User::query()->create($payload);
}
```

```php
<?php

// ✅ CORRECT — validated request + explicit parameters
public function createUser(string $email, string $role): User
{
    return User::query()->create([
        'email' => $email,
        'role' => $role,
    ]);
}
```

### AP-5: Heavy work in request lifecycle

```php
<?php

// ❌ WRONG — long-running work blocks HTTP request
public function store(StoreReportRequest $request): RedirectResponse
{
    $report = Report::query()->create($request->validated());
    app(ReportExporter::class)->export($report); // takes minutes

    return redirect()->route('reports.show', $report);
}
```

```php
<?php

// ✅ CORRECT — dispatch queued job for heavy work
public function store(StoreReportRequest $request): RedirectResponse
{
    $report = Report::query()->create($request->validated());
    ExportReportJob::dispatch($report->id);

    return redirect()->route('reports.show', $report);
}
```

### AP-6: Request stored in service

```php
<?php

// ❌ WRONG — request stored as field, becomes hidden dependency
final class UserService
{
    public function __construct(private Request $request)
    {
    }
}
```

```php
<?php

// ✅ CORRECT — pass only required data per-call
final class UserService
{
    public function createUser(array $validatedData): User
    {
        return User::query()->create($validatedData);
    }
}
```

## Error handling anti-patterns

### AP-7: String-matching errors

```php
<?php

// ❌ WRONG — fragile string comparison
if ($e->getMessage() === 'User not found') {
    abort(404);
}
```

```php
<?php

// ✅ CORRECT — exception type checks
if ($e instanceof ModelNotFoundException) {
    abort(404);
}
```

### AP-8: Silent error swallowing

```php
<?php

// ❌ WRONG — exception silently ignored
try {
    $user = $this->repo->findById($id);
} catch (Throwable $e) {
    return new User(); // pretend nothing happened
}
```

```php
<?php

// ✅ CORRECT — exception explicitly handled
try {
    $user = $this->repo->findById($id);
} catch (Throwable $e) {
    report($e);
    throw $e;
}
```

### AP-9: Double reporting

```php
<?php

// ❌ WRONG — same exception reported twice
try {
    $this->service->syncUser($id);
} catch (Throwable $e) {
    report($e); // first report
    throw new RuntimeException('sync failed', previous: $e); // Handler reports again
}
```

```php
<?php

// ✅ CORRECT — report once with useful context
try {
    $this->service->syncUser($id);
} catch (Throwable $e) {
    throw new RuntimeException("sync failed for user {$id}", previous: $e);
}
```

## Logging anti-patterns

### AP-10: Logging secrets

```php
<?php

// ❌ WRONG — token and password in logs
Log::info('user login attempt', [
    'token' => $token,
    'password' => $request->input('password'),
]);
```

```php
<?php

// ✅ CORRECT — no sensitive data, only identifiers
Log::info('user login attempt', [
    'user_id' => $user->id,
    'email' => Str::mask($user->email, '*', 3),
]);
```

### AP-11: Logging heavy data

```php
<?php

// ❌ WRONG — logging full payload/file content
Log::debug('file processed', [
    'file' => $fileContent,   // could be megabytes
    'response' => $fullResp,  // could be huge array/object
]);
```

```php
<?php

// ✅ CORRECT — log metadata, not data
Log::debug('file processed', [
    'file_size_bytes' => strlen($fileContent),
    'content_type' => $contentType,
]);
```

## Configuration anti-patterns

### AP-12: Hardcoded values

```php
<?php

// ❌ WRONG — magic numbers and strings
public function process(): void
{
    Http::timeout(30)->post('https://api.example.com/process');
}
```

```php
<?php

// ✅ CORRECT — values from config
public function process(): void
{
    Http::timeout(config('services.partner.timeout'))
        ->post(config('services.partner.base_url').'/process');
}
```

### AP-13: env() in service layer

```php
<?php

// ❌ WRONG — service reads environment directly
public function send(): void
{
    $apiKey = env('API_KEY'); // breaks testability, hidden dependency
}
```

```php
<?php

// ✅ CORRECT — read from config, inject value where needed
final class SenderService
{
    public function __construct(private string $apiKey)
    {
    }

    public static function fromConfig(): self
    {
        return new self(config('services.partner.api_key'));
    }
}
```

## Testing anti-patterns

### AP-14: Real adapters in unit tests

```php
<?php

// ❌ WRONG — unit test uses real database
public function test_create_user(): void
{
    $repo = new EloquentUserRepository();
    $service = new UserService($repo);
    $service->createUser('user@mail.com', 'admin');
    // this is integration behavior, not unit scope
}
```

```php
<?php

// ✅ CORRECT — unit test uses mock
public function test_create_user(): void
{
    $repo = Mockery::mock(UserRepository::class);
    $repo->shouldReceive('create')->once()->andReturn(new User());

    $service = new UserService($repo);
    $service->createUser('user@mail.com', 'admin');
}
```

### AP-15: Tests depending on order

```php
<?php

// ❌ WRONG — test B depends on state from test A
private static ?User $sharedUser = null;

public function test_a_create_user(): void
{
    self::$sharedUser = User::factory()->create();
}

public function test_b_get_user(): void
{
    $result = User::query()->findOrFail(self::$sharedUser->id); // depends on test_a running first
}
```

```php
<?php

// ✅ CORRECT — each test is self-contained
public function test_create_user(): void
{
    $user = User::factory()->create();
    $this->assertNotNull($user->id);
}

public function test_get_user(): void
{
    $user = User::factory()->create();
    $result = User::query()->findOrFail($user->id);
    $this->assertSame($user->id, $result->id);
}
```

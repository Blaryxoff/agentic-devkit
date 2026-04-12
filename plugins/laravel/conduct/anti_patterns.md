# Anti-patterns

This document contains common mistakes and their corrections. Every example shows the **wrong** way first, then the *
*correct** way. Use this as a reference to avoid repeating known bad patterns.

## Architecture anti-patterns

### AP-1: Core imports adapter

```php
// ❌ WRONG — core depends on adapter
use App\Infrastructure\Repositories\EloquentUserRepository;

final class UserService
{
    public function __construct(private EloquentUserRepository $repo) {}
}
```

```php
// ✅ CORRECT — core depends on contract interface
use App\Domain\User\Contracts\UserRepository;

final class UserService
{
    public function __construct(private UserRepository $repo) {}
}
```

### AP-2: Business logic in controller

```php
// ❌ WRONG — controller contains business rules
public function store(Request $request): RedirectResponse
{
    $amount = (float) $request->input('amount');
    if ($amount < 10) {
        return back()->withErrors(['amount' => 'minimum order is 10']);
    }
    $discount = $amount > 100 ? $amount * 0.1 : 0;
    Order::query()->create(['amount' => $amount - $discount]);
    return redirect()->route('orders.index');
}
```

```php
// ✅ CORRECT — controller delegates to service
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
// ❌ WRONG — controller orchestrates infrastructure adapters directly
public function store(Request $request, StripeClient $stripe, SlackNotifier $notifier): RedirectResponse
{
    $paymentId = $stripe->charge((int) $request->input('amount'));
    $notifier->send("order paid: {$paymentId}");
    return redirect()->route('orders.index');
}
```

```php
// ✅ CORRECT — controller depends on application service
public function store(StoreOrderRequest $request): RedirectResponse
{
    $this->orderService->createOrder($request->validated());
    return redirect()->route('orders.index');
}
```

## Laravel + PHP anti-patterns

### AP-4: Passing unvalidated arrays instead of typed data

```php
// ❌ WRONG — unvalidated array, easy to pass wrong shape
public function createUser(array $payload): User { ... }

// ✅ CORRECT — explicit typed parameters
public function createUser(string $email, string $role): User { ... }
```

### AP-5: Heavy work in request lifecycle

```php
// ❌ WRONG — long-running work blocks HTTP request
$report = Report::query()->create($request->validated());
app(ReportExporter::class)->export($report); // takes minutes

// ✅ CORRECT — dispatch queued job for heavy work
$report = Report::query()->create($request->validated());
ExportReportJob::dispatch($report->id);
```

### AP-6: Request stored in service

```php
// ❌ WRONG — request stored as field, becomes hidden dependency
public function __construct(private Request $request) {}

// ✅ CORRECT — pass only required data per-call
public function createUser(array $validatedData): User { ... }
```

## Error handling anti-patterns

### AP-7: String-matching errors

```php
// ❌ WRONG — fragile string comparison
if ($e->getMessage() === 'User not found') { abort(404); }

// ✅ CORRECT — exception type checks
if ($e instanceof ModelNotFoundException) { abort(404); }
```

### AP-8: Silent error swallowing

```php
// ❌ WRONG — exception silently ignored
try { $user = $this->repo->findById($id); }
catch (Throwable $e) { return new User(); }

// ✅ CORRECT — exception explicitly handled
try { $user = $this->repo->findById($id); }
catch (Throwable $e) { report($e); throw $e; }
```

### AP-9: Double reporting

```php
// ❌ WRONG — same exception reported twice
catch (Throwable $e) {
    report($e); // first report
    throw new RuntimeException('sync failed', previous: $e); // Handler reports again
}

// ✅ CORRECT — report once with useful context
catch (Throwable $e) {
    throw new RuntimeException("sync failed for user {$id}", previous: $e);
}
```

## Logging anti-patterns

### AP-10: Logging secrets

```php
// ❌ WRONG — token and password in logs
Log::info('user login attempt', ['token' => $token, 'password' => $request->input('password')]);

// ✅ CORRECT — no sensitive data, only identifiers
Log::info('user login attempt', ['user_id' => $user->id, 'email' => Str::mask($user->email, '*', 3)]);
```

### AP-11: Logging heavy data

```php
// ❌ WRONG — logging full payload/file content
Log::debug('file processed', ['file' => $fileContent, 'response' => $fullResp]);

// ✅ CORRECT — log metadata, not data
Log::debug('file processed', ['file_size_bytes' => strlen($fileContent), 'content_type' => $contentType]);
```

## Configuration anti-patterns

### AP-12: Hardcoded values

```php
// ❌ WRONG — magic numbers and strings
Http::timeout(30)->post('https://api.example.com/process');

// ✅ CORRECT — values from config
Http::timeout(config('services.partner.timeout'))->post(config('services.partner.base_url').'/process');
```

### AP-13: env() in service layer

```php
// ❌ WRONG — service reads environment directly
$apiKey = env('API_KEY'); // breaks testability, hidden dependency

// ✅ CORRECT — inject via config
public function __construct(private string $apiKey) {}
public static function fromConfig(): self { return new self(config('services.partner.api_key')); }
```

## Testing anti-patterns

### AP-14: Real adapters in unit tests

```php
// ❌ WRONG — unit test uses real database
$repo = new EloquentUserRepository(); // real adapter in unit test
$service = new UserService($repo);

// ✅ CORRECT — unit test uses mock
$repo = Mockery::mock(UserRepository::class);
$repo->shouldReceive('create')->once()->andReturn(new User());
$service = new UserService($repo);
```

### AP-15: Tests depending on order

```php
// ❌ WRONG — test B depends on state from test A
private static ?User $sharedUser = null;
public function test_a_create_user(): void { self::$sharedUser = User::factory()->create(); }
public function test_b_get_user(): void { User::query()->findOrFail(self::$sharedUser->id); }

// ✅ CORRECT — each test is self-contained
public function test_get_user(): void
{
    $user = User::factory()->create();
    $this->assertSame($user->id, User::query()->findOrFail($user->id)->id);
}
```

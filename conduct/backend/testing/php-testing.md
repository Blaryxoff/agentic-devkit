# Testing rules

> This document covers PHP/Laravel-specific rules for implementing tests in code — tooling, patterns, and conventions. For language-agnostic test planning and design guidelines, see [test-cases.md](./test-cases.md).

## General rules

- test files live under `tests/Unit` and `tests/Feature`, named `*Test.php`
- never test private/protected methods directly — test behavior through public interfaces
- data providers are preferred for multiple similar cases
- every test **MUST** have a corresponding test case.

## Test cases

See [test-cases](./test-cases.md)

## Mocks

- use PHPUnit test doubles (`createMock`) or Mockery for interfaces/contracts
- keep mocks in test files unless a reusable fake is needed in `tests/Fakes/`
- never mock what you do not own (framework internals) — mock your own boundaries
- avoid hand-written mocks for simple interfaces when PHPUnit/Mockery can generate them
- if using Mockery, always close it in `tearDown()` (or use Laravel base test cleanup)

### Mock example

```php
public function test_create_user_fails_when_email_already_exists(): void
{
    $userRepository = $this->createMock(UserRepository::class);
    $userRepository
        ->method('findByEmail')
        ->with('test@example.com')
        ->willReturn($this->existingUser());

    $service = new UserService($userRepository);

    $this->expectException(DuplicateEmailException::class);

    $service->createUser('test@example.com');
}
```

## Unit tests

### Rules

- cover all service classes, value objects, and domain entities
- use mocks/fakes for external dependencies — never use real DB, queue, mail, HTTP in unit tests
- each test should cover one behavior, not one method — a single method may have multiple tests
- aim for full branch coverage on core business logic
- naming convention: `test_<method_or_behavior>_<scenario>` ex.: `test_create_user_fails_with_duplicate_email`

### Single test example

```php
public function test_create_user_fails_with_duplicate_email(): void
{
    $repository = $this->createMock(UserRepository::class);
    $repository->method('findByEmail')->willReturn(new User('test@example.com'));

    $service = new UserService($repository);

    $this->expectException(DuplicateEmailException::class);
    $service->createUser('test@example.com');
}
```

### Data provider example

```php
#[\PHPUnit\Framework\Attributes\DataProvider('invalidEmails')]
public function test_new_email_rejects_invalid_values(string $email): void
{
    $this->expectException(InvalidArgumentException::class);
    Email::fromString($email);
}

public static function invalidEmails(): array
{
    return [
        'empty string' => [''],
        'missing at-sign' => ['userexample.com'],
        'missing domain' => ['user@'],
    ];
}
```

### Test helpers

- place shared test data in class constants, factories, or dedicated helper methods
- use model factories for entities persisted in tests
- extract repeated setup into helper methods in `tests/TestCase.php` or traits under `tests/Support/`

```php
protected function makeTestUser(array $attributes = []): User
{
    return User::factory()->make(array_merge([
        'email' => 'test@example.com',
    ], $attributes));
}
```

## Integration tests

### Rules

- use Feature tests for HTTP, middleware, auth, validation, and persistence flows
- integration tests must run against a dedicated test environment (`APP_ENV=testing`)
- use `RefreshDatabase` (or transactions) for isolation; each test must clean up after itself
- use factories/seeders for fixtures; avoid static YAML/JSON fixtures unless necessary
- never run integration tests against shared/staging/production databases
- because integration tests are slower and more resource intensive, create them only for main flows (happy path, highly probable path, or high-damage fail path)
- integration tests should be in `tests/Feature` and structured by feature/flow
- for Inertia responses, assert component names and required props

### Integration test example (HTTP + DB)

```php
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class RegisterUserTest extends TestCase
{
    use RefreshDatabase;

    public function test_user_can_register(): void
    {
        $response = $this->post('/register', [
            'name' => 'Test User',
            'email' => 'test@example.com',
            'password' => 'password',
            'password_confirmation' => 'password',
        ]);

        $response->assertRedirect('/dashboard');
        $this->assertDatabaseHas('users', [
            'email' => 'test@example.com',
        ]);
    }
}
```

## Frontend testing (Inertia + Vue + Tailwind)

- keep page/component behavior tests close to user outcomes (rendered state, events, form submission states)
- when testing Inertia pages, prefer asserting server-provided props and visible UI states together
- validate critical Tailwind-driven states (error, disabled, loading, dark mode) with component tests or browser tests
- reserve browser/E2E tests for key Nginx-served user journeys (auth, checkout, payment, profile updates)

## Coverage

- minimum coverage for core application code (`app/`): 80%
- run coverage: `php artisan test --coverage`
- view HTML report: `php artisan test --coverage-html storage/test-coverage`
- add and maintain a `composer test-coverage` script

## DO / DO NOT

**DO:**

- use data providers for parameterized scenarios
- use factories and framework assertions (`assertDatabaseHas`, `assertRedirect`, etc.)
- isolate side effects with fakes (`Mail::fake()`, `Queue::fake()`, `Http::fake()`) when appropriate

**DO NOT:**

- test private/protected methods directly
- use real external services in unit tests
- couple tests tightly to implementation details that can change without behavior changes

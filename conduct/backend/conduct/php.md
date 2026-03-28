# PHP specific rules

## Language baseline

- use PHP 8.3+ features when they improve clarity and safety
- add `declare(strict_types=1);` in PHP source files unless project convention explicitly excludes it
- prefer framework-idiomatic code over "plain PHP patterns" that bypass established conventions

## Naming conventions

- class/interface/enum names: `PascalCase`
- methods/properties/variables: `camelCase`
- constants: `UPPER_SNAKE_CASE`
- booleans should read as predicates: `isActive`, `hasAccess`, `canPublish`
- avoid vague names (`data`, `helper`, `manager`, `utils`) when a domain name exists

## Class design

- use constructor property promotion for injected dependencies when it improves readability
- avoid empty constructors
- keep constructors lightweight; do not execute heavy business logic in `__construct`
- prefer `final` for classes that are not intended for inheritance
- prefer immutable value objects where possible

Example:

```php
final class CreateOrderAction
{
    public function __construct(
        private OrderRepository $orders,
        private PaymentGateway $payments,
    ) {
    }
}
```

## Type declarations

- always declare parameter types and return types
- use nullable types explicitly (`?string`, `?User`)
- use union/intersection types only when they simplify contracts (not to hide poor modeling)
- avoid mixed/implicit types unless unavoidable at boundaries

Example:

```php
public function findByEmail(string $email): ?User
{
    // ...
}
```

## Control flow and readability

- always use braces for `if/else/for/foreach/while`
- prefer early returns to reduce nested branching
- keep methods focused on one responsibility
- split long methods into meaningful private methods or dedicated classes

## Error handling

- never swallow exceptions silently
- throw domain-meaningful exceptions or return explicit failure results according to project style
- include contextual information in exception/log messages
- do not use exceptions for normal control flow

Example:

```php
if (! $user->canPurchase($product)) {
    throw new DomainException('User is not allowed to purchase this product.');
}
```

## Collections and arrays

- prefer typed DTOs/value objects for structured payloads passed across layers
- if arrays are required, document shape via PHPDoc
- avoid deep associative arrays as implicit contracts

Example:

```php
/** @return array{total:int, items:list<OrderSummary>} */
public function summarize(OrderCollection $orders): array
{
    // ...
}
```

## Comments and PHPDoc

- avoid comments that restate obvious code
- use PHPDoc for:
  - complex array shapes
  - generic-like collections
  - non-obvious behavior contracts
- remove stale comments during refactoring

## Framework integration (when using Laravel)

- keep controllers thin; delegate business logic to domain/service/action layer by project convention
- keep Eloquent models thin: data structure, relationships, simple accessors/mutators, and query scopes only
- use FormRequest for request validation
- use policies/gates for authorization
- use Eloquent relationships/scopes/resources instead of ad-hoc repetitive query logic
- prevent N+1 via eager loading where relevant
- avoid `env()` outside config files
- prefer queued jobs for long-running work

## Security basics

- never commit or log secrets/tokens/passwords/PII
- validate all external input
- avoid raw SQL string composition with user input
- ensure authorization checks are explicit and close to write operations

## Testing and quality

- write/maintain tests in the project's testing style (PHPUnit unless project says otherwise)
- test behavior, not private implementation details
- keep tests deterministic and isolated
- run project formatting/linting tooling before finalizing changes

## DO / DO NOT

**DO:**
- use explicit types and clear method contracts
- keep classes small and cohesive
- prefer reuse over duplication
- follow existing project conventions from sibling files

**DO NOT:**
- add dependencies without clear need and approval
- hide errors with empty `catch` blocks
- put heavy business logic into controllers
- bypass framework conventions without strong reason

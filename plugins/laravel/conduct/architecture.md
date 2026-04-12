# Code architecture rules

> **Project layout note**: This project uses a conventional Laravel structure (`app/Http/`, `app/Services/`,
`app/Models/`, etc.) inherited from Laravel 10 and intentionally kept as-is. The `app/Domain/`, `app/Application/`,
`app/Infrastructure/` folder examples below are **aspirational targets** for new complex modules — not a requirement to
> restructure existing code. Always follow the existing layout in sibling files first; introduce deeper layering only
> when complexity clearly justifies it.

Code must be scalable, maintainable and performant. It should be easy to test, extend, support and easy to onboard a new
developer.
Following architecture/design patterns are used:

- layered + hexagonal boundaries - REQUIRED (contracts & implementations)
- ddd - REQUIRED (domain driven design, simplified)
- typed domain values - REQUIRED
- cqrs - OPTIONAL (command query responsibility segregation)
- variables naming conventions - REQUIRED
- comments and documentation - REQUIRED
- files and folders structuring - REQUIRED

**IMPORTANT**: remember that even if now all modules belong to one app (one code base), they can be split to separate
repositories in the future. So design in the way to make the split easy, fast and error-free.

## Hexagonal architecture key points

- Your domain/business (core) logic knows nothing about the outside world — no HTTP, no SQL, no queue broker, no
  filesystem. Everything external connects through contracts (interfaces you define) implemented by infrastructure
  adapters (concrete classes).
- Adapters can import from core/application, core never imports from adapters (instead it uses contracts/interfaces).
  Adapters don't import adapters for orchestration.
- Try to create small, specific interfaces and avoid general-purpose one.
- For web runtime boundary, treat Nginx/PHP-FPM as transport infrastructure: application/domain rules must not depend on
  web server implementation details.

### Port interface example

```php
interface UserRepository
{
    public function create(User $user): void;
    public function getById(UserId $id): ?User;
    public function getByEmail(Email $email): ?User;
    public function update(User $user): void;
    public function delete(UserId $id): void;
}
```

## Domain driven design rules

| Concept | Definition | Use when | Key constraint |
|---|---|---|---|
| **Entity** | Object defined by identity, not attributes. Mutable, has lifecycle. | Must be tracked over time (Order, User, Account) | Validates invariants in constructor and mutators |
| **Value object** | Object defined by attributes. Immutable, no identity. Equal if data matches. | Identity doesn't matter — just the value (Money, Email, DateRange) | Immutable; validation in constructor |
| **Aggregate** | Cluster of entities + value objects with one Aggregate Root as sole entry point | Multiple entities must change atomically with shared invariants (Order + OrderLines) | External code references root only; save as a whole; each aggregate = transaction boundary |

**DDD rules:**

- Contracts (interfaces) used only inside Application Services — never in entities or value objects.
- **Services/Actions constraint**: one public method = one business scenario. Avoid god-services. Extract a new service/action when a method does not belong to the existing scenario.
- Push logic into value objects, entities and aggregates — keep services slim.
- Eloquent models stay thin: data shape, relationships, simple accessors/mutators, and query scopes only. Business workflows belong in services/actions/domain.
- Entities and value objects: do one thing well, expose behavior methods, avoid uncontrolled public mutation, provide predictable serialization (`__toString()` / `toArray()`) where needed.
- Use aggregates only when multiple entities must change together and splitting them risks broken invariants. If a single entity enforces its own rules independently, an aggregate is not needed.

### Entity example

```php
final class User
{
    public function __construct(
        private UserId $id,
        private Email $email,
        private string $username,
        private Role $role,
        private DateTimeImmutable $createdAt,
        private DateTimeImmutable $updatedAt,
    ) {
        if ($this->username === '') {
            throw new InvalidArgumentException('username cannot be empty');
        }
    }

    // typed getters: id(), email(), username(), role() ...

    public function rename(string $username): void
    {
        if ($username === '') {
            throw new InvalidArgumentException('username cannot be empty');
        }
        $this->username = $username;
        $this->updatedAt = new DateTimeImmutable('now');
    }
}
```

### Value object example

```php
final class Email
{
    public function __construct(private string $value)
    {
        $normalized = mb_strtolower(trim($this->value));
        if (! filter_var($normalized, FILTER_VALIDATE_EMAIL)) {
            throw new InvalidArgumentException("invalid email '{$this->value}'");
        }
        $this->value = $normalized;
    }

    public function value(): string { return $this->value; }
    public function equals(self $other): bool { return $this->value === $other->value; }
    public function __toString(): string { return $this->value; }
}
```

### Mapper example (domain ↔ DTO)

```php
final class UserMapper
{
    public function toDomain(UserModel $model): DomainUser
    {
        return new DomainUser(
            new UserId((string) $model->id),
            new Email($model->email),
            $model->username,
            Role::from($model->role),
            new DateTimeImmutable($model->created_at->toIso8601String()),
            new DateTimeImmutable($model->updated_at->toIso8601String()),
        );
    }

    public function toDTO(DomainUser $user): array
    {
        return [
            'id' => $user->id()->value(),
            'email' => $user->email()->value(),
            'username' => $user->username(),
            'role' => $user->role()->value,
        ];
    }
}
```

## Typed domain values key points

- avoid passing arguments by using general types (strings, integers and etc.). ex.: better to use Email value object
  instead of string or Money value object instead of float.
- for external boundaries (controllers, jobs, events), convert primitives to typed objects early and keep typed values
  through the core flow.

## CQRS pattern key points

- split your system into two paths: one for writing (Commands), one for reading (Queries). Never mix them.
- A command is an intent to change something. It should be named in the imperative. Command Rules
    - Return void or just a new resource ID
    - One handler per command
    - Validate inputs via Form Request before reaching the handler
    - Never query and return business data from a command handler
    - Never share a handler between two commands
- A query asks a question. It must have zero side effects. Query Rules
    - Always return a DTO (Data Transfer Object), not a domain entity
    - Read from the read-optimised store/view if you have one
    - Can be called multiple times with no side effects
    - Never modify state inside a query handler
    - Never reuse command models as query return types
- When your read and write loads are very different, use separate read/write connections or stores

## Variables naming convention

- variable names should be self-describing
- only use short variable names in local and simple operations

## Files and folders structuring

- try to keep files less than 500 lines, if bigger - consider to split onto files
- try to keep less than 10 files by folder, if bigger - consider to split into subfolders

### File naming rules

- PHP classes: use `StudlyCase` file names matching class names (`UserService.php`, `BroadcastRepository.php`)
- Vue pages/components: use `PascalCase` file names (`Users/Index.vue`, `Orders/Create.vue`)
- test files: `<ClassName>Test.php` — placed in `tests/Feature` or `tests/Unit`
- DTO files: `*Data.php` / `*Dto.php` inside data/DTO folder
- mapper files: `*Mapper.php` inside infrastructure/application mapping folder
- config files: keep env-driven values in `config/*.php`
- separate concerns into dedicated classes/files when code grows: `CreateUserHandler.php`, `GetUserQuery.php`,
  `UserPolicy.php`

### Project structure (base)

```
app/
├── Domain/                       # core domain (framework-light)
│   └── User/
│       ├── Entities/User.php
│       ├── ValueObjects/Email.php, UserId.php
│       └── Contracts/UserRepository.php
├── Application/                  # use-cases / orchestration
│   └── User/
│       ├── Services/UserService.php
│       ├── Data/CreateUserData.php
│       └── Mappers/UserResponseMapper.php
├── Infrastructure/               # implementations of contracts
│   ├── Persistence/User/
│   │   ├── EloquentUserRepository.php
│   │   └── Mapper/UserMapper.php
│   └── Clients/BillingClient.php, NotificationClient.php ...
├── Http/
│   ├── Controllers/              # inbound HTTP adapter
│   ├── Requests/                 # validation
│   └── Middleware/
├── Jobs/                         # async commands
├── Models/                       # Eloquent models
├── Policies/
└── Providers/

bootstrap/, config/, database/{factories,migrations,seeders}/
public/, storage/
resources/js/{Pages,Components,Layouts}/, resources/css/
routes/{web.php,api.php}
tests/{Feature,Unit}/
nginx/default.conf
composer.json, package.json, vite.config.js
```

### CQRS additions (changes to Application/ and Infrastructure/ only)

When using CQRS, replace `Services/` with `Commands/` + `Queries/` + `ReadModels/`:

```
app/Application/User/
├── Commands/
│   ├── CreateUserCommand.php
│   └── CreateUserHandler.php
├── Queries/
│   ├── GetUserQuery.php
│   └── GetUserHandler.php
└── ReadModels/
    └── UserView.php

app/Infrastructure/Persistence/User/
├── UserCommandRepository.php
└── UserQueryRepository.php

app/Http/Controllers/
├── UserCommandController.php
└── UserQueryController.php
```

## DO / DO NOT

**DO:**

- define contracts (interfaces) in core/application, implement them in infrastructure
- keep entities and value objects self-contained with validation in constructors/factories
- use mappers for every boundary crossing (controller/request ↔ domain, repository/model ↔ domain, domain ↔ Inertia
  props)
- split files by concern when they grow beyond 500 lines

**DO NOT:**

- import infrastructure adapters from domain core — ever
- import one adapter from another adapter for orchestration
- put business logic in controllers, repositories, route closures, or view components
- use general types (string, int, float) where a value object or entity ID exists
- bypass Inertia boundaries by leaking backend internals directly into Vue pages

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
<?php

// app/Domain/User/Contracts/UserRepository.php
namespace App\Domain\User\Contracts;

use App\Domain\User\Entities\User;
use App\Domain\User\ValueObjects\Email;
use App\Domain\User\ValueObjects\UserId;

interface UserRepository
{
    public function create(User $user): void;

    public function getById(UserId $id): ?User;

    public function getByEmail(Email $email): ?User;

    public function update(User $user): void;

    public function delete(UserId $id): void;
}
```

## Domain driven design key points

- Entity: An object defined by its identity, not its attributes. Two entities with the same data are still different
  objects if they have different IDs. Use when: the object has a lifecycle and must be tracked over time (Orders, Users,
  Accounts). Something having an ID.
- Value objects: An object defined by its attributes, with no identity. Immutable. Two value objects with the same data
  are equal. Use when: identity doesn't matter — just the value (Money, Address, DateRange, Email)
- Aggregate: A cluster of entities and value objects treated as a single unit. One object is the Aggregate Root — the
  only entry point for changes.
  Rules:
    - External objects can only reference the root, never internal entities directly
    - All invariants (business rules) are enforced within the aggregate
    - Each aggregate is a transaction boundary — save it as a whole
    - Use aggregates when: multiple entities must change together as one atomic operation and splitting them would risk
      broken invariants (e.g. an Order with OrderLines — you never save a line without its parent order). If a single
      entity can enforce its own rules and is saved independently, an aggregate is not needed.
- Contracts should only be used inside Application Services, never in entities or value objects.
- Make services slim so put as much logic as possible into value objects, entities and aggregates
- Eloquent models should stay thin: data shape, relationships, simple accessors/mutators, and query scopes are
  acceptable; business workflows belong in services/actions/domain.
- A value object and entity:
    - should do one thing and do it well.
    - should expose clear behavior methods and avoid uncontrolled public mutation.
    - should provide predictable serialization (`__toString()` / `toArray()`) where needed.

### Entity example

```php
<?php

// app/Domain/User/Entities/User.php
namespace App\Domain\User\Entities;

use App\Domain\User\ValueObjects\Email;
use App\Domain\User\ValueObjects\Role;
use App\Domain\User\ValueObjects\UserId;
use DateTimeImmutable;
use InvalidArgumentException;

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

    public function id(): UserId
    {
        return $this->id;
    }

    public function email(): Email
    {
        return $this->email;
    }

    public function username(): string
    {
        return $this->username;
    }

    public function role(): Role
    {
        return $this->role;
    }

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
<?php

// app/Domain/User/ValueObjects/Email.php
namespace App\Domain\User\ValueObjects;

use InvalidArgumentException;

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

    public function value(): string
    {
        return $this->value;
    }

    public function equals(self $other): bool
    {
        return $this->value === $other->value;
    }

    public function __toString(): string
    {
        return $this->value;
    }
}
```

```php
<?php

// app/Domain/User/ValueObjects/UserId.php
namespace App\Domain\User\ValueObjects;

use Illuminate\Support\Str;
use InvalidArgumentException;

final class UserId
{
    public function __construct(private string $value)
    {
        if (! Str::isUuid($this->value)) {
            throw new InvalidArgumentException("invalid user id '{$this->value}'");
        }
    }

    public static function generate(): self
    {
        return new self((string) Str::uuid());
    }

    public function value(): string
    {
        return $this->value;
    }

    public function equals(self $other): bool
    {
        return $this->value === $other->value;
    }

    public function __toString(): string
    {
        return $this->value;
    }
}
```

### Mapper example (domain ↔ DTO)

```php
<?php

// app/Infrastructure/Persistence/User/Mapper/UserMapper.php
namespace App\Infrastructure\Persistence\User\Mapper;

use App\Domain\User\Entities\User as DomainUser;
use App\Domain\User\ValueObjects\Email;
use App\Domain\User\ValueObjects\Role;
use App\Domain\User\ValueObjects\UserId;
use App\Models\User as UserModel;
use DateTimeImmutable;

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

```php
<?php

// app/Models/User.php
namespace App\Models;

use Illuminate\Database\Eloquent\Model;

final class User extends Model
{
    protected $table = 'users';

    protected $fillable = [
        'id',
        'email',
        'username',
        'role',
    ];
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
    - Validate inputs inside the handler (or via Form Request / pipeline)
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

### Project structure without CQRS

```
example-project/
├── app/
│   ├── Domain/                       # core domain (framework-light)
│   │   ├── User/
│   │   │   ├── Entities/
│   │   │   │   └── User.php
│   │   │   ├── ValueObjects/
│   │   │   │   ├── Email.php
│   │   │   │   └── UserId.php
│   │   │   └── Contracts/
│   │   │       └── UserRepository.php
│   │   └── ...
│   ├── Application/                  # use-cases / orchestration
│   │   ├── User/
│   │   │   ├── Services/
│   │   │   │   └── UserService.php
│   │   │   ├── Data/
│   │   │   │   └── CreateUserData.php
│   │   │   └── Mappers/
│   │   │       └── UserResponseMapper.php
│   │   └── ...
│   ├── Infrastructure/               # implementations of contracts
│   │   ├── Persistence/
│   │   │   └── User/
│   │   │       ├── EloquentUserRepository.php
│   │   │       └── Mapper/
│   │   │           └── UserMapper.php
│   │   ├── Clients/
│   │   │   ├── BillingClient.php
│   │   │   ├── NotificationClient.php
│   │   │   └── ...
│   │   └── ...
│   ├── Http/
│   │   ├── Controllers/              # inbound HTTP adapter
│   │   ├── Requests/                 # validation
│   │   └── Middleware/
│   ├── Jobs/                         # async commands
│   ├── Models/                       # Eloquent models
│   ├── Policies/
│   └── Providers/
├── bootstrap/
├── config/
├── database/
│   ├── factories/
│   ├── migrations/
│   └── seeders/
├── public/
├── resources/
│   ├── js/
│   │   ├── Pages/                    # Inertia Vue pages
│   │   ├── Components/
│   │   └── Layouts/
│   └── css/
├── routes/
│   ├── web.php
│   └── api.php
├── storage/
├── tests/
│   ├── Feature/
│   └── Unit/
├── nginx/                            # Nginx site / reverse-proxy config
│   └── default.conf
├── composer.json
├── package.json
└── vite.config.js
```

### Project structure with CQRS (partial) (showing only changed parts)

```
example-project/
├── app/
│   ├── Application/
│   │   ├── User/
│   │   │   ├── Commands/
│   │   │   │   ├── CreateUserCommand.php
│   │   │   │   ├── CreateUserHandler.php
│   │   │   │   └── ...
│   │   │   ├── Queries/
│   │   │   │   ├── GetUserQuery.php
│   │   │   │   ├── GetUserHandler.php
│   │   │   │   └── ...
│   │   │   ├── ReadModels/
│   │   │   │   └── UserView.php
│   │   │   └── ...
│   │   └── ...
│   ├── Infrastructure/
│   │   ├── Persistence/
│   │   │   └── User/
│   │   │       ├── UserCommandRepository.php
│   │   │       ├── UserQueryRepository.php
│   │   │       └── ...
│   │   └── ...
│   ├── Http/
│   │   ├── Controllers/
│   │   │   ├── UserCommandController.php
│   │   │   ├── UserQueryController.php
│   │   │   └── ...
│   │   └── ...
│   └── ...
└── ...
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

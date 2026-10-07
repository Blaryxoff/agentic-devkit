# NestJS Conduct

Apply these rules to NestJS application code. Read the [official NestJS documentation](https://docs.nestjs.com/) for the installed version when changing framework APIs or integration behavior.

## Routing

- New capabilities or cross-module flow: load [architecture.md](./architecture.md) and inspect neighboring feature modules.
- External input, authentication, authorization, or personal data: load [security.md](./security.md) and inspect the project's request schema and role policy.
- Persistence, migrations, transactions, or jobs: load [database-safety.md](./database-safety.md) and inspect the selected integrations.
- Tests: load [testing.md](./testing.md) and follow the project's test policy.

## Boundaries

- Organize capabilities in feature modules. Export only providers consumed by another module; use dependency injection for services and external adapters.
- Keep controllers focused on HTTP transport. Validate and transform input at the boundary, then delegate business decisions to providers or domain services.
- Keep tenant scope, transaction context, and retry behavior explicit across providers and jobs.
- Translate expected domain failures into stable API responses; let unexpected failures reach the application's exception and logging path without exposing secrets or personal data.
- Reuse project-owned request and response contracts when present. Do not duplicate schemas in controllers or client packages.

## Verification

- Run the target project's lint, build, and focused tests for changed modules. Probe HTTP or integration behavior when it depends on guards, dependency injection, transactions, or framework wiring.

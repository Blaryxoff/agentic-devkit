# Architecture Overview

This document set defines architecture and development rules for Nuxt 3 frontend applications.

## Technology stack

- **Runtime**: Nuxt 3
- **Framework**: Vue 3
- **Language**: TypeScript (strict)
- **Styling**: BEM + SCSS
- **Package manager**: pnpm
- **Testing**: frontend unit/integration/e2e tooling configured in the target project

## Reading order

1. **[Architecture](./architecture.md)** - component boundaries, composable/service layering, and folder structure.
2. **[Configuration](./configs.md)** - environment usage boundaries and runtime config conventions.
3. **[Error Handling](./error_handling.md)** - error taxonomy and user-facing failure behavior.
4. **[Logging](./logging.md)** - structured logs, redaction rules, and signal quality.
5. **[State Management](./stores.md)** - Pinia store rules, when to use stores vs composables.
6. **[Dependencies](./dependencies.md)** - approved package strategy and dependency hygiene.
7. **[Documentation](./documentation.md)** - docs standards and update workflow.

## Reference documents

- **[Security](./security.md)** - XSS/input/auth/session/cors security rules.
- **[Makefile](./makefile.md)** - standard build and automation targets.
- **[Anti-patterns](./anti_patterns.md)** - common mistakes with bad/good examples.
- **[Git Workflow](./git.md)** - branching, commits, and PR flow.
- **[Feature Spec Template](../spec/spec.md)** - feature spec template before implementation.

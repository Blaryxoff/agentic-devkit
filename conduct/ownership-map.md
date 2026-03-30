# Rule Ownership Map

This file defines strict ownership for plugin rule families.

## Why

To avoid duplicated or conflicting rules, each policy family has one owner plugin.

## Owners

- `rubx-core`:
  - shared process standards
  - spec/test-case workflow
  - global review/reporting conventions
- `rubx-laravel`:
  - Laravel and backend architecture conventions
  - FormRequest, Policy/Gate, Eloquent, service/action patterns
- `rubx-frontend`:
  - tool-agnostic frontend architecture
  - generic CSS best practices (deduplication, reusable variables/tokens)
- `rubx-inertia`:
  - Inertia transport, page props contracts, and form/navigation behavior
- `rubx-vue`:
  - Vue component, composable, and state organization conventions
- `rubx-tailwind`:
  - Tailwind utility conventions and repeated arbitrary value policy
- `rubx-nuxt`:
  - Nuxt runtime/SSR/data-fetching conventions

## Ownership Rules

1. A policy must have one owner only.
2. Non-owner plugins may reference owner policies, but must not duplicate full policy text.
3. Conduct docs remain canonical source of truth; skills summarize and enforce them.

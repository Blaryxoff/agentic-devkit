# Configuration

Configuration must be explicit, environment-aware, and safe for frontend bundles.

## Nuxt config boundaries

- framework/runtime config lives in `nuxt.config.ts`.
- client-safe values go to `runtimeConfig.public`.
- private values stay in `runtimeConfig` private section.

## Environment variables

- keep `.env` ignored by git.
- keep `.env.example` updated with variable names only.
- never commit secrets or production keys.

## Validation rules

- validate required config at app startup where feasible.
- provide safe defaults only for non-sensitive values.
- document expected types and valid ranges.

## Frontend exposure rules

- only expose values that are safe for browser visibility.
- never expose secret keys in client-side runtime.
- keep API base URLs and feature flags explicit.

## Naming conventions

- use clear, project-prefixed env names.
- avoid ambiguous names like `KEY` or `URL`.
- keep variable naming consistent across environments.

## DO / DO NOT

DO:
- centralize config reads through Nuxt runtime config
- document every new env var in `.env.example`

DO NOT:
- hardcode env-specific values in components/composables
- duplicate config sources in multiple files without reason

# Error Handling

All errors must be handled explicitly.

## Core principles

- model UI/network/async status with explicit states.
- never swallow errors silently.
- never branch on message text; branch on typed error class/code.
- show user-safe messages and keep diagnostics in logs/telemetry.

## State model

Use predictable state transitions:

`idle -> loading -> success | error`

For retries:

`error -> loading -> success | error`

## API and composable boundaries

- wrap HTTP calls in composables/services.
- normalize transport errors into typed app errors.
- return stable result shape from composables.

Example:

```ts
export type LoadState = 'idle' | 'loading' | 'success' | 'error'
```

## UI behavior rules

- every async screen must define loading, empty, and error states.
- forms must display field-level and global errors.
- disable duplicate submissions while request is in-flight.
- keep failed user input in form state when reasonable.

## Retry and fallback

- retry only idempotent operations.
- use bounded retries with backoff for transient failures.
- provide explicit retry action in UI when automatic retries stop.

## Logging integration

- log one meaningful error per failure path.
- include operation name, route, and non-sensitive identifiers.
- avoid duplicate logging for the same error chain.

## DO / DO NOT

DO:
- define typed error helpers in shared layer
- keep error handling centralized in composables/services
- map errors to clear user messaging

DO NOT:
- ignore Promise rejections
- use broad catch without follow-up action
- expose stack traces/internal payloads to users

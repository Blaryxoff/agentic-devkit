# Error Handling

All errors must be handled explicitly.

## Core principles

- model UI/network/async status with explicit states.
- Handle every error explicitly and report unexpected failures through the approved error path.
- Branch on typed error classes or codes.
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

Model state as a union type: `'idle' | 'loading' | 'success' | 'error'`.

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
- Emit one log per error chain and add context only when a later layer contributes useful information.

## Apply these practices

- define typed error helpers in shared layer
- keep error handling centralized in composables/services
- map errors to clear user messaging

## Replace these patterns

- Handle every Promise rejection.
- Pair each catch block with an explicit recovery, reporting, or propagation action.
- Show user-safe messages and keep stack traces and internal payloads in diagnostics.

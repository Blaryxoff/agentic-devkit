# Logging

Use structured logging for meaningful frontend diagnostics.

## Levels

| Level | Use case |
|---|---|
| `debug` | local diagnostics and development traces |
| `info` | important lifecycle events |
| `warn` | recoverable issues and degraded behavior |
| `error` | failed operations requiring attention |

## Context fields

Include relevant non-sensitive context:

- `feature` or `module`
- `operation`
- `route`
- `requestId` / `traceId` (if available)
- stable entity identifiers (non-PII)

## Frontend logging rules

- centralize logging via utility/composable wrapper.
- avoid direct `console.log` in production paths.
- log once per failure path; avoid duplicates.
- prefer structured objects over string concatenation.

## Sensitive data policy

Never log:

- auth tokens or secrets
- passwords
- personal data that is not required for debugging
- full payload bodies when metadata is enough

## Performance notes

- do not log inside hot loops unless sampled.
- avoid logging large objects and binary data.
- strip heavy nested fields before logging.

## DO / DO NOT

DO:
- use consistent fields across modules
- connect logs with error handling and observability docs

DO NOT:
- leave debug logs in release code paths
- log sensitive values

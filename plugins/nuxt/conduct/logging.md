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
- Use the central logging utility instead of direct `console.log` in production paths.
- Emit one meaningful log per failure path and enrich it with new context when needed.
- prefer structured objects over string concatenation.

## Sensitive data policy

Log only the metadata needed for diagnosis; exclude:

- auth tokens or secrets
- passwords
- personal data that is not required for debugging
- full payload bodies when metadata is enough

## Performance notes

- Sample logs from hot loops.
- Log summaries or metadata instead of large objects and binary data.
- strip heavy nested fields before logging.

## Apply these practices

- use consistent fields across modules
- connect logs with error handling and observability docs

## Replace these patterns

- Remove debug logs from release code paths.
- Keep sensitive values out of logs.

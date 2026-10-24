# Express Failure Contracts

Apply [typed-javascript.md](../../core/conduct/typed-javascript.md) for typed errors/results, causes, promise ownership, no silent suppression, single reporting, and process-exit boundaries.

- Define a stable application error taxonomy at the existing boundary; add error classes only when project style requires them. Keep transport mapping in the router/global error adapter and provider normalization in its client.
- Preserve the project's public error envelope and field-error keys. Default categories map to validation 400/422, unauthenticated 401, forbidden 403, missing resource 404, state/uniqueness conflict 409, throttled 429, and unexpected failure 500; use existing contracts when their documented statuses differ.
- Keep SQL/provider/internal stack details out of responses. Include a safe request ID for diagnosis; authentication/resource-existence policies may deliberately return the same public response for different internal causes.
- Forward async failures correctly for Express 4 versus 5. Check `headersSent` and stream protocol before sending an error; clear timers/listeners and abort/retain background work according to its explicit ownership contract.
- Distinguish worker retry from HTTP retry and provider failover. Treat queue redelivery and ambiguous external success as possible; preserve enough durable state to reconcile instead of repeating a paid or destructive effect blindly.
- Keep reverse-proxy failures consistent with API behavior and private infrastructure details hidden. Verify timeout, cancellation, partial streaming, and terminal failure through the actual adapter when the change depends on them.

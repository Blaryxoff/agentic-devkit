# NestJS Security

- Validate untrusted HTTP, webhook, queue, and integration data before it reaches business operations. Use the project's chosen schema and a Nest pipe or equivalent boundary validation; TypeScript types alone do not validate runtime input.
- Authenticate requests before resolving the acting user or tenant. Use guards for route-aware authorization and recheck ownership or state constraints inside the operation that changes data.
- Derive tenant identity from trusted context, not a caller-provided tenant field. Carry that context explicitly into background work and database transactions.
- Bind SQL values through the selected driver or query builder. Never interpolate request data into SQL, shell commands, URLs, or template code.
- Keep credentials in configured secrets, and exclude secrets and personal data from logs, exception messages, and public responses.
- Verify webhook signatures and replay rules using the integration's actual contract. Make callback processing idempotent.

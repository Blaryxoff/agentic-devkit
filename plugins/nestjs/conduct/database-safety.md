# NestJS Data and Jobs

- Read the project's schema, migrations, and database adapter before changing data access. Use database constraints for required uniqueness, foreign keys, and state invariants where they apply.
- Keep each business operation's related writes in one short transaction. Pass the transaction handle through every participating query; a query through the ordinary connection does not join that transaction automatically.
- Set tenant or request-local database context inside the transaction that executes the protected query. Verify the application role and policy behavior in an integration test when row-level security is used.
- Enqueue a durable job in the same transaction as the state change when both must commit or roll back together. Otherwise use a documented outbox or equivalent recovery path.
- Treat jobs, callbacks, and external deliveries as retryable. Store an idempotency key or unique business constraint, and distinguish confirmed failure from an ambiguous remote outcome before retrying.
- Keep network calls outside open database transactions. For long-running work, use persisted state and a lease or version check before publishing a result.
- Review migration compatibility with already-running application and worker versions before deploying a destructive schema change.

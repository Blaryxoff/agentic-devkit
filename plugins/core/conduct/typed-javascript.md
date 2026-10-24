# JavaScript and TypeScript Contracts

Use this document for typed JavaScript application boundaries. Preserve the project's naming, module format, strictness, and public API; do not migrate CommonJS/ESM or loosen compiler settings as an incidental fix.

## Types and domain values

- Give exported functions, integration adapters, request/response DTOs, and persistent state explicit contracts. Prefer inferred local types where they are already precise.
- Accept untrusted data as `unknown`, validate it at entry, then narrow it. Avoid `any`, double assertions, non-null assertions, and suppression directives that hide an unresolved contract.
- Represent status/type fields with the project's enum or literal-union/schema convention. Keep allowed values, display labels, API validation, database constraints, and rendering branches aligned; do not force TypeScript enums or a database enum into an established union/check-constraint design.
- Model async states as discriminated variants when flags would permit contradictory states. Check exhaustive handling and define a safe boundary response for unknown values from a newer server.
- Preserve domain invariants in focused operations or immutable value types when complexity warrants them. Normalize money, identifiers, dates, durations, null/undefined, and serialization explicitly at boundaries.
- Keep constructors and module imports lightweight; compose dependencies in the application entry point. Avoid mutable module singletons for request/account-scoped state.
- Use native types and precise names before JSDoc. Follow [code-comments.md](./code-comments.md); put architecture, operational, and migration explanations in external docs, not private implementation narrative.

## Errors and async ownership

- Use typed errors or discriminated results following project style. Preserve the original `cause` when translating a low-level failure into a different domain/integration meaning.
- Branch on stable error classes/codes or validated provider metadata; do not string-match human-readable messages for application control flow. Isolate unavoidable legacy/provider parsing in the adapter with evidence for its contract.
- Add context at a boundary without repeatedly wrapping the same error or reporting it at every layer. Assign one terminal reporting owner; return a safe, stable error code/message/field shape to the client.
- Handle every promise: await it, return it to a framework that owns rejection, or register an explicit background task/error path. Empty catches, ignored promise rejections, and success-shaped fallbacks that conceal failure are defects.
- Distinguish expected denial/validation, cancellation, transient failure, permanent failure, and ambiguous side effects. Retry only the failure class and operation that the idempotency contract allows.
- Keep fatal process exit in bootstrap or the owning runtime shutdown path. Business operations report/throw failures; they do not terminate a server, worker, mobile app, or desktop process.
- Make intentional suppression explicit in the contract and safe reporting path; obtain approval before omitting required error handling. Redact secrets and personal data from causes, public responses, and diagnostic serialization.

Source: [TypeScript narrowing and exhaustive checking](https://www.typescriptlang.org/docs/handbook/2/narrowing.html).

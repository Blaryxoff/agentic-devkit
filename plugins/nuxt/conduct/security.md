# Security Rules

Security rules apply across all frontend layers.

## Input and output safety

- never trust route query, form input, local storage, or external API payloads.
- validate and normalize data at boundaries before business/UI usage.
- render user-generated content as plain text by default.
- avoid raw HTML rendering (`v-html`) unless content is sanitized and trusted.

## XSS and DOM safety

- never inject unsanitized strings into HTML.
- avoid direct DOM APIs unless Vue template/reactivity cannot solve the task.
- do not build HTML strings manually for insertion into the DOM.

## Auth/session/token hygiene

- do not store secrets in client code.
- treat tokens as sensitive: no logs, no exposure in UI state snapshots.
- prefer secure cookie/session flows where project backend supports them.
- if local storage/session storage is used, document risk and scope.

## Nuxt runtime config rules

- only expose safe public values via `runtimeConfig.public`.
- private keys must stay server-side only (`runtimeConfig` private fields).
- never hardcode API keys/tokens in source files.

## Network and CORS awareness

- use HTTPS in production.
- never bypass TLS verification in production integrations.
- handle CORS failures with user-safe messaging and retry guidance.

## Dependency security

- run dependency checks regularly (`pnpm audit`).
- avoid unmaintained or low-trust packages.
- do not add dependencies that duplicate existing capabilities.

## Logging and error exposure

- never log tokens, secrets, passwords, or PII.
- do not expose stack traces/internal endpoints in user-facing errors.
- provide generic user messages and structured internal diagnostics.

## DO / DO NOT

DO:
- sanitize risky content before rendering
- keep secret values out of frontend bundles
- review auth/session flows for leakage risks

DO NOT:
- use `v-html` on untrusted content
- commit secrets to repo or config
- leak sensitive payloads in logs or telemetry

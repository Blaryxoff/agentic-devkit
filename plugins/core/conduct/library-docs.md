# Current Library Docs

Verify a library or framework API against up-to-date documentation before using or recommending it, instead of trusting training-cutoff memory. Training data lags behind releases — APIs get renamed, deprecated, or removed. Fetch on demand per `mcp-economy.md`; never bulk-preload docs.

## Trigger — fetch docs first

Fetch current docs before writing or suggesting code when any holds:

- You are not certain the API signature, option name, or config key matches the **installed** version.
- The task involves version-specific behaviour: migrations, breaking changes, deprecations, new APIs.
- The user names a specific library, framework, SDK, or CLI and expects current usage.
- You are about to write boilerplate from memory for a fast-moving library (build tools, web frameworks, cloud SDKs).

## How — Context7 when available

1. Resolve the library id (Context7: `resolve-library-id`), then fetch scoped docs (`get-library-docs`) for the **specific topic**, not the whole library.
2. Pin to the version in the project's lockfile/manifest (`package.json`, `composer.json`, `go.mod`, etc.) — request that version's docs, not "latest".
3. Keep the fetch narrow: pass a topic and a token limit so the injected chunk stays small. The docs live in context only for the turn that needs them.

## When to skip

- Language stdlib and long-stable APIs you are confident in.
- No third-party library is involved.
- Pure refactor/formatting that does not change which APIs are called.

State the assumption when you skip ("using the stdlib `X` API as of <version>") so a wrong guess is visible.

## Graceful absence

If Context7 (or an equivalent docs source) is not configured, do not block: proceed with best knowledge, and explicitly flag any API whose current correctness you could not verify so the user can confirm.

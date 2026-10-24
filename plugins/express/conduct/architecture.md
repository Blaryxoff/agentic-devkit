# Express Architecture

- Trace a feature from registered router through middleware, validated input, service, persistence/integration, and response before choosing files to change.
- Match adjacent feature modules and contract schemas. Keep framework `Request`/`Response` objects out of reusable operations when the project already passes plain typed arguments.
- Validate all external input at runtime, including query strings, path parameters, worker payloads, callbacks, and WebSocket messages. TypeScript types alone do not validate input; use the installed schema library and major, including Zod 4 when present.
- Order middleware deliberately: trust proxy policy, request limits, CORS/cookies, authentication, authorization, routers, missing-route response, then the four-argument error handler. Preserve route-specific raw bodies for signed webhooks.
- Map expected domain errors to stable statuses and safe response bodies. Send one response; delegate errors after streaming headers to the configured close/error path rather than attempting another JSON response.
- Initialize infrastructure and workers through the existing composition root. On termination, stop accepting work, close streams, drain/close workers, then close Redis and database pools with a bounded shutdown deadline.
- Preserve the workspace package manager and scripts. For pnpm workspaces, inspect `pnpm-workspace.yaml` and each package's `name`; target commands with `pnpm --filter <package> --fail-if-no-match run <script>` instead of assuming every package has the same scripts.

Sources: [Express middleware](https://expressjs.com/en/guide/using-middleware.html), [shutdown](https://expressjs.com/en/advanced/healthcheck-graceful-shutdown.html), [Zod](https://zod.dev/basics), [pnpm 10 filtering](https://pnpm.io/10.x/filtering).

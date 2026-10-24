# Express Architecture

- Trace a feature from registered router through middleware, validated input, service, persistence/integration, and response before choosing files to change.
- Keep domain invariants independent of transport/infrastructure at the project's existing seams. Introduce a strategy for real interchangeable behavior, a pipeline for composable steps, a state machine for lifecycle invariants, and a repository only for a genuine data-source/query boundary; explain the need rather than adding pattern scaffolding.
- Keep one application operation focused on one business scenario. Keep data rows/schema objects thin, use explicit validated input and response projections, and isolate complex read queries when they do not own a business workflow.
- Match adjacent feature modules and contract schemas. Keep framework `Request`/`Response` objects out of reusable operations when the project already passes plain typed arguments.
- Validate all external input at runtime, including query strings, path parameters, worker payloads, callbacks, and WebSocket messages. TypeScript types alone do not validate input; use the installed schema library and major, including Zod 4 when present.
- Order middleware deliberately: trust proxy policy, request limits, CORS/cookies, authentication, authorization, routers, missing-route response, then the four-argument error handler. Preserve route-specific raw bodies for signed webhooks.
- Map expected domain errors to stable statuses and safe response bodies. Send one response; delegate errors after streaming headers to the configured close/error path rather than attempting another JSON response.
- Initialize infrastructure and workers through the existing composition root. On termination, stop accepting work, close streams, drain/close workers, then close Redis and database pools with a bounded shutdown deadline.
- Preserve the workspace package manager and scripts. For pnpm workspaces, inspect `pnpm-workspace.yaml` and each package's `name`; target commands with `pnpm --filter <package> --fail-if-no-match run <script>` instead of assuming every package has the same scripts.
- Check N+1 queries, bounded pagination/order, projection cost, and indexes for changed read paths. Document public API/config/CLI/worker/migration contracts and their configured verification commands when they change.

Sources: [Express middleware](https://expressjs.com/en/guide/using-middleware.html), [shutdown](https://expressjs.com/en/advanced/healthcheck-graceful-shutdown.html), [Zod](https://zod.dev/basics), [pnpm 10 filtering](https://pnpm.io/10.x/filtering).

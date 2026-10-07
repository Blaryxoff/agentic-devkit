# Next.js Conduct

Apply these rules to Next.js App Router code. Load the installed version's relevant guides under `node_modules/next/dist/docs/` before changing framework APIs or file conventions; project `AGENTS.md` may require this explicitly. Use the [official App Router documentation](https://nextjs.org/docs/app) when installed guides are unavailable.

## Routing

- New routes, layouts, loading states, or error boundaries: inspect the adjacent route segments and the installed App Router file-convention guide.
- Server/client component boundaries, data fetching, caching, mutations, Proxy, or Route Handlers: read the matching installed guide before editing.
- Shared UI structure, accessibility, and visual behavior: load `plugins/frontend/conduct/overview.md` and its relevant routed document.

## Boundaries

- Keep layouts and pages as Server Components by default. Add `"use client"` only where state, effects, events, or browser APIs require it; place the boundary around the smallest interactive subtree.
- Keep secrets and server-only modules outside client imports and serialized props. Treat data passed to Client Components as browser-visible.
- Follow the project's API ownership. When another service owns business rules, call its API and keep authorization and validation in that service; use Next rewrites or Route Handlers only for the transport behavior the project requires.
- Make loading, empty, error, and retry behavior explicit for asynchronous screens. Check data freshness and caching against the installed version's rules before choosing a cache directive or invalidation path.
- Keep React state local until multiple unrelated consumers need shared state. Derive values during render when possible, and reserve effects for synchronization with external systems.

## Verification

- Run the target project's Next build, lint, and configured tests for changed routes. Check the affected route in a browser when behavior or layout changes.

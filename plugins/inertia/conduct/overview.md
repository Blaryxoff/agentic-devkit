# Inertia Conduct

This section contains Inertia-specific conventions only.

## Scope

- Page props contract design
- Inertia form/navigation conventions
- Deferred or partial data-loading behavior

## Boundaries

- Keep generic frontend and CSS policy in their owning conduct documents.
- Keep Laravel and Vue policy in their owning conduct documents.
- Reference `plugins/core/conduct/ownership-map.md` when in doubt.

## Routing

- Product/dev planning for Inertia page props, navigation, forms, and UI states → [spec/spec-inertia-ui.md](./spec/spec-inertia-ui.md).

## Page props contract

Props passed from a controller to an Inertia page are a **public API**. Changing the prop shape is a breaking change.

- Pass Eloquent Resources or explicit arrays to `Inertia::render()`.
- Keep prop structures explicit and stable; document significant prop changes alongside route/controller changes.

## Deferred props

- Use `Inertia::defer()` (or equivalent lazy/deferred mechanism) for heavy data not needed at first render.
- Show a skeleton or pulse placeholder while deferred props load.

## Navigation

- Use `<Link>` or `router.visit()` for all internal navigation.
- Use `<Link>` or `router.visit()` for internal routes to preserve SPA navigation.

## Mutations and redirects

- Preserve predictable request/response flow: mutations should follow the standard Inertia form submission → redirect → page reload cycle.
- Use Inertia form helpers (`useForm`, `router.post/put/delete`) instead of ad-hoc fetch/axios for mutations that fit the convention.

## Loading, empty, and error states

- Every page or component that displays data must handle three states:
  - **Loading**: skeleton, spinner, or pulse placeholder while data is being fetched.
  - **Empty**: show explicit empty-state UI when a collection has zero items.
  - **Error**: user-facing feedback when the server returns a validation error or a generic failure.

## Error handling

- For Inertia requests, surface domain errors via redirects and session flash or shared props; return safe user-facing errors without raw stack traces or PHP exception output.
- Define validation errors in FormRequests and surface them via Inertia form errors.

## Shared props security

- Share only non-sensitive, user-safe data because shared props are sent to every page.
- Keep secrets, tokens, internal IDs, and server configuration server-side.
- Expose client-accessible values via dedicated mechanisms (e.g. `VITE_*` env vars for build-time config); keep server-only values server-side.

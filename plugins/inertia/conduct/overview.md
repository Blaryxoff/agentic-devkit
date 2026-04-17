# Inertia Conduct

This section contains Inertia-specific conventions only.

## Scope

- Page props contract design
- Inertia form/navigation conventions
- Deferred or partial data-loading behavior

## Boundaries

- Do not place generic frontend or CSS policy here.
- Do not duplicate Laravel or Vue policy that is owned elsewhere.
- Reference `plugins/core/conduct/ownership-map.md` when in doubt.

## Page props contract

Props passed from a controller to an Inertia page are a **public API**. Changing the prop shape is a breaking change.

- Never pass Eloquent model instances directly to `Inertia::render()` — use Eloquent Resources or explicit arrays.
- Keep prop structures explicit and stable; document significant prop changes alongside route/controller changes.

## Deferred props

- Use `Inertia::defer()` (or equivalent lazy/deferred mechanism) for heavy data not needed at first render.
- The frontend **must** show a skeleton or pulse placeholder while deferred props load — never render an empty space silently.

## Navigation

- Use `<Link>` or `router.visit()` for all internal navigation.
- Never use `<a href>` for internal routes — it causes a full page reload and breaks SPA behavior.

## Mutations and redirects

- Preserve predictable request/response flow: mutations should follow the standard Inertia form submission → redirect → page reload cycle.
- Use Inertia form helpers (`useForm`, `router.post/put/delete`) instead of ad-hoc fetch/axios for mutations that fit the convention.

## Loading, empty, and error states

- Every page or component that displays data must handle three states:
  - **Loading**: skeleton, spinner, or pulse placeholder while data is being fetched.
  - **Empty**: explicit empty-state UI when a collection has zero items — never show a blank area.
  - **Error**: user-facing feedback when the server returns a validation error or a generic failure.

## Error handling

- For Inertia requests, surface domain errors via redirects and session flash or shared props — never return raw stack traces or PHP exception output.
- Keep validation errors in FormRequest and surface them via Inertia form errors; do not construct manual error arrays in controllers.

## Shared props security

- Shared props are sent to every page — only include non-sensitive, user-safe data.
- Never place secrets, tokens, internal IDs, or server configuration in shared props.
- Expose client-accessible values via dedicated mechanisms (e.g. `VITE_*` env vars for build-time config); keep server-only values server-side.

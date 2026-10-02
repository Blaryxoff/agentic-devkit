# Vue Conduct

This section contains Vue-specific conventions only.

## Scope

- Component boundaries and responsibilities
- Composable extraction and reuse rules
- State ownership patterns

## Boundaries

- Keep Inertia transport rules in the Inertia conduct documents.
- Keep Tailwind and generic CSS ownership rules in their conduct documents.
- Reference `plugins/core/conduct/ownership-map.md` when in doubt.

## File naming and project structure

- Vue pages and components use `PascalCase` file names matching their component name (`Users/Index.vue`, `Orders/Create.vue`, `UserCard.vue`).
- Organize files under `resources/js/` by role:
  - `Pages/` — top-level Inertia page components (one per route)
  - `Components/` — reusable UI components
  - `Layouts/` — page layout wrappers
- Group components into subdirectories that mirror their domain or feature.

## Component design

- Keep components focused on rendering and interaction wiring. Business logic belongs in composables or services.
- Keep component APIs simple and specialize them for the needs they serve.
- Favor explicit props/events contracts over implicit coupling.
- Vue components must have a **single root element**. Multiple root elements cause issues with attribute inheritance and transitions.

## Composables and state

- Extract reusable behavior into composables when logic repeats across components.
- Keep state ownership clear: prefer local component state first; use shared state only when multiple unrelated components need it.

## Safe rendering

- Render user-controlled content with Vue interpolation; use `v-html` only for sanitized content.

## Form and async error handling

- Handle failed form submissions through `onError` and display `errors` to the user.
- Handle Promise rejections from async operations or let them propagate to a top-level error boundary.
- Disable submit buttons during in-flight requests to prevent duplicate submissions.

## List spacing

- Use `gap-*` on the parent flex or grid container for spacing between list items.
- Apply `gap-*` to the parent flex or grid container instead of spacing each child with individual margins such as `mb-4` or `mt-2`.

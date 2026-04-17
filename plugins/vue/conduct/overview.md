# Vue Conduct

This section contains Vue-specific conventions only.

## Scope

- Component boundaries and responsibilities
- Composable extraction and reuse rules
- State ownership patterns

## Boundaries

- Do not place Inertia transport rules here.
- Do not place Tailwind or generic CSS ownership rules here.
- Reference `plugins/core/conduct/ownership-map.md` when in doubt.

## File naming and project structure

- Vue pages and components use `PascalCase` file names matching their component name (`Users/Index.vue`, `Orders/Create.vue`, `UserCard.vue`).
- Organize files under `resources/js/` by role:
  - `Pages/` — top-level Inertia page components (one per route)
  - `Components/` — reusable UI components
  - `Layouts/` — page layout wrappers
- Do not flatten all components into a single directory — use subdirectories that mirror the domain or feature they belong to.

## Component design

- Keep components focused on rendering and interaction wiring. Business logic belongs in composables or services.
- Keep component APIs simple and avoid over-generalization.
- Favor explicit props/events contracts over implicit coupling.
- Vue components must have a **single root element**. Multiple root elements cause issues with attribute inheritance and transitions.

## Composables and state

- Extract reusable behavior into composables when logic repeats across components.
- Keep state ownership clear: prefer local component state first; use shared state only when multiple unrelated components need it.

## Safe rendering

- Do not use `v-html` with user-controlled content — it introduces XSS vulnerabilities.
- If `v-html` is necessary, sanitize the input before rendering.

## Form and async error handling

- Always handle failed form submissions — wire `onError` and display `errors` to the user; never silently discard validation failures.
- Do not swallow Promise rejections from async operations — either handle the error or let it propagate to a top-level error boundary.
- Disable submit buttons during in-flight requests to prevent duplicate submissions.

## List spacing

- Use `gap-*` on the parent flex or grid container for spacing between list items.
- Do not use individual margins (`mb-4`, `mt-2`, etc.) on each child item — this scatters spacing logic and makes it harder to maintain consistently.

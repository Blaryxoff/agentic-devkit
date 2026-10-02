# Frontend Architecture Rules

Code must be scalable, maintainable, and easy to onboard for new developers.

Primary architecture principles:

- component + composable boundaries - REQUIRED
- strict typing and explicit contracts - REQUIRED
- DRY and SOLID in frontend scope - REQUIRED
- clear folder structure and naming - REQUIRED
- minimal coupling between UI and API transport - REQUIRED

## Layering

- `pages/` own route-level composition and data orchestration.
- `components/` own reusable UI rendering units.
- `composables/` own reusable business/UI logic and async workflows.
- `utils/` own pure helpers with no side effects.
- `stores/` (if used) own cross-page state only.

Keep page templates and large UI components focused on composition; place business logic in composables or services.

## TypeScript contracts

- `any` is forbidden unless explicitly justified.
- define explicit interfaces/types for API responses, component props, emits, and composable returns.
- use narrow unions/enums for finite states (`idle | loading | success | error`).
- validate unknown payloads at boundaries before use.

## Nuxt conventions

- Prefer Nuxt primitives (`useAsyncData`, `useFetch`, `useRoute`, `useRouter`, `useRuntimeConfig`).
- keep route/query synchronization explicit and predictable.
- Make SSR/CSR assumptions explicit and guard browser-only APIs from server execution.

## File and folder conventions

- Vue components/pages: `PascalCase.vue`.
- composables: `useXxx.ts`.
- types: `*.types.ts` or `types.ts` per module.
- tests mirror source location where possible.
- split files that exceed readable size or mix unrelated concerns.

## Example structure

```text
app/
components/
  Catalog/
    Filters.vue
    List.vue
composables/
  useCatalogFilters.ts
  useCatalogData.ts
pages/
  catalog.vue
stores/
  catalog.ts
utils/
  query.ts
```

## State management (Pinia)

Use Pinia stores only for **cross-page or cross-feature state** that cannot be scoped to a single composable.

Rules:
- prefer composable-local state for page/feature-scoped data.
- use a Pinia store when state must survive route changes or be shared across unrelated pages.
- define stores with `defineStore` using the composition API style (`setup` stores).
- keep stores typed: explicit state shape, typed actions, typed getters.
- Delegate API calls from stores to composables or services, then invoke those boundaries from store actions.
- Keep UI state such as loading indicators and modal visibility local unless multiple unrelated pages share it.

See [stores.md](./stores.md) for detailed Pinia store rules and examples.

## Accessibility

- every interactive element must be keyboard-navigable and have a visible focus state.
- use semantic HTML elements (`<button>`, `<nav>`, `<main>`, `<header>`) before reaching for `<div>` with ARIA roles.
- images must have descriptive `alt` text; decorative images use `alt=""`.
- form inputs must have associated `<label>` elements (via `for`/`id` or wrapping).
- dynamic content changes (loading states, modals, alerts) must be announced via `aria-live` or focus management where appropriate.
- color contrast must meet WCAG AA minimum (4.5:1 for normal text, 3:1 for large text).

## Performance and SSR

- Guard browser-only APIs (`window`, `document`, `localStorage`) with `import.meta.client` or `onMounted`.
- Use `useFetch` or `useAsyncData` for server-rendered data, especially SEO-critical content.
- lazy-load heavy components with `defineAsyncComponent` or Nuxt's `<LazyXxx>` auto-import convention.
- use `@nuxt/image` for all user-facing images to get automatic format optimization and lazy loading.
- Centralize shared fetches in composables and cache them with `useAsyncData` keys.
- keep bundle size in check: justify every new dependency by checking its minified+gzipped size impact.

## Apply these practices

- keep rendering concerns in components and logic in composables
- keep types explicit at module boundaries
- reuse existing patterns before creating new abstractions
- use Pinia only for genuinely shared cross-page state

## Replace these patterns

- Route shared API access through composables or services.
- Keep mutable state in explicit component, composable, or store ownership.
- Guard browser-only APIs before server rendering.

# Dependencies

Use existing project dependencies first. Add new packages only with clear technical justification.

## Source of truth

- `package.json` is the single source of truth for installed dependencies.
- Follow current project conventions before proposing new libraries.

## Approved stack

These packages are installed and approved. Use them before reaching for alternatives.

### Core runtime

| Package | Purpose |
|---|---|
| `nuxt` | App framework and SSR runtime |
| `vue` | UI component framework |
| `vue-router` | Client-side routing (via Nuxt) |
| `pinia` + `@pinia/nuxt` | Cross-page state management |

### Forms and validation

| Package | Purpose |
|---|---|
| `vee-validate` + `@vee-validate/zod` | Form state management and field-level validation |
| `zod` | Schema definition and runtime type validation |
| `yup` | Alternative schema validation (legacy forms) |
| `inputmask` + `vue-the-mask` | Input masking for phone/date/numeric fields |

### UI and components

| Package | Purpose |
|---|---|
| `vue-final-modal` | Modal dialogs |
| `swiper` | Carousels and sliders |
| `@vuepic/vue-datepicker` | Date picker |
| `vuedraggable` | Drag-and-drop lists |
| `nuxt-tour` | Onboarding tours |
| `nuxt-svgo` | SVG icon imports as Vue components |
| `vue-yandex-maps` | Map integration |

### Media and assets

| Package | Purpose |
|---|---|
| `@nuxt/image` | Image optimization, lazy loading, format conversion |

### Data and utilities

| Package | Purpose |
|---|---|
| `date-fns` | Date formatting and manipulation |
| `ua-parser-js` | User-agent parsing |
| `nuxt-echarts` | Charts and data visualization |

### Infrastructure

| Package | Purpose |
|---|---|
| `nuxt-bugsnag` | Error monitoring and reporting |
| `nuxt-multi-cache` | SSR response caching |
| `@vite-pwa/nuxt` | PWA manifest and service worker |
| `@nuxtjs/sitemap` | Sitemap generation |

## Adding new dependencies

Before adding a package:

1. Check if an approved package above or native browser/JS APIs solve the task.
2. If not, explain:
   - why current options are insufficient,
   - expected benefit,
   - maintenance risk and security posture.
3. Prefer actively maintained libraries with stable ecosystems.
4. Check bundle size impact (`pnpm build` and compare).

## Forbidden patterns

| Forbidden | Use instead |
|---|---|
| Hardcoding secrets in source | `.env` and Nuxt runtime config |
| Pulling utility libs for trivial helpers | Native JS/TS or `date-fns` |
| Duplicate packages for already-covered concerns | Existing approved packages above |
| Moment.js | `date-fns` |
| Axios | Nuxt's `useFetch` / `$fetch` |
| Lodash for single helpers | Native JS array/object methods |
| jQuery | Vue reactivity and DOM APIs |

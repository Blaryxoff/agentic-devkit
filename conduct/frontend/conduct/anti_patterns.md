# Anti-patterns

This document lists common frontend mistakes for Nuxt + TypeScript + BEM codebases.

## AP-1: Business logic inside large components

Bad:
- page/component mixes fetching, transformation, validation, and rendering.

Good:
- move reusable logic into composables (`useXxx`) and keep component focused on UI.

## AP-2: `any` as default escape hatch

Bad:
- broad `any` usage in API payloads, props, and store state.

Good:
- define explicit interfaces and narrow unknown values at boundaries.

## AP-3: Query state not synced with URL

Bad:
- filters are local-only and break on refresh/share links.

Good:
- sync filter/search/pagination state with route query intentionally.

## AP-4: Missing loading/empty/error states

Bad:
- async pages render blank or broken UI during fetch/failure.

Good:
- always define and test all UI states.

## AP-5: `v-html` with untrusted content

Bad:
- direct rendering of external/user strings as HTML.

Good:
- sanitize trusted content or render as plain text.

## AP-6: BEM inconsistency

Bad:
- random class naming per component, mixed styles, unclear modifiers.

Good:
- stable `block__element--modifier` naming and one primary block per component.

## AP-7: Duplicated network calls in multiple components

Bad:
- each component calls the same endpoint with slight variations.

Good:
- centralize into composable/service with typed contract.

## AP-8: Over-logging and sensitive data leaks

Bad:
- logging full payloads/tokens/PII or noisy per-loop logs.

Good:
- structured, minimal logs with safe metadata only.

## AP-9: Weak error handling

Bad:
- swallowed promise rejections and generic catches with no user feedback.

Good:
- typed error mapping and actionable user-safe error UI.

## AP-10: Unbounded dependencies

Bad:
- adding packages for trivial helpers already covered by framework/native APIs.

Good:
- prefer existing dependencies and justify each new package.

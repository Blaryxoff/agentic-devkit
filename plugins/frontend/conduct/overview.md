# Frontend Conduct

This section contains tool-agnostic frontend architecture and generic CSS best practices.

## Scope

- Frontend layering and separation of concerns
- Reuse and abstraction policy
- Data contract stability
- Generic CSS conventions (non-Tailwind)

## Boundaries

- Do not include tool-specific rules here (Nuxt, Inertia, Vue internals, Tailwind internals).
- Reference `plugins/core/conduct/ownership-map.md` when in doubt.

## Architecture

- Keep rendering concerns in UI layers and business logic in reusable abstractions (composables, services, utils).
- Reuse existing components, composables, and helpers before creating new abstractions.
- Keep data contracts explicit and stable across layers.
- Require clear loading, empty, and error states for every async UI.
- Avoid duplicated logic and duplicated UI patterns when a shared abstraction is appropriate.

## Generic CSS rules

- Avoid duplicated hardcoded values for repeated styles (especially colors, spacing, radius).
- Move repeated values to reusable CSS variables or design tokens.
- Keep class naming consistent with the project convention (BEM, utility-first, etc.).
- Prefer maintainable, composable styles over one-off overrides.
- If a value repeats in multiple places, extract it rather than copy it.

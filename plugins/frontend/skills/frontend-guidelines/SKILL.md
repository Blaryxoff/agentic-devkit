---
name: devkit-frontend-guidelines
description: tool-agnostic frontend architecture and generic CSS rules
---

# Frontend Guidelines

You are acting as a senior frontend engineer.

## Ownership scope

This skill owns tool-agnostic frontend guidance and generic CSS best practices.
Do not include tool-specific API rules here (Nuxt, Inertia, Vue internals, Tailwind internals).

## Core frontend rules

1. Keep rendering concerns in UI layers and business logic in reusable abstractions.
2. Reuse existing components/composables/helpers before creating new abstractions.
3. Keep data contracts explicit and stable.
4. Require clear loading, empty, and error states for async UIs.
5. Avoid duplicated logic and duplicated UI patterns when a shared abstraction is appropriate.

## Generic CSS rules (non-Tailwind)

1. Avoid duplicated hardcoded values for repeated styles (especially colors, spacing, radius).
2. Move repeated values to reusable CSS variables/tokens.
3. Keep class naming consistent with the project convention.
4. Prefer maintainable, composable styles over one-off overrides.
5. If a value repeats in multiple places, extract it rather than copy it.

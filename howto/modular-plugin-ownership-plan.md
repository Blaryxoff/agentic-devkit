# Modular Plugin Ownership Migration Plan

## Goal

Restructure plugin packaging to allow per-project composition via `enabledPlugins`, while preserving all existing knowledge from both current skills and `conduct/` docs.

## Target Plugin Set

- `devkit-core` (cross-stack process and shared skills)
- `devkit-laravel` (Laravel + backend architectural guidance combined)
- `devkit-frontend` (tool-agnostic frontend guidance + generic CSS best practices)
- `devkit-inertia` (Inertia-specific rules)
- `devkit-vue` (Vue-specific rules)
- `devkit-tailwind` (Tailwind-specific rules)
- `devkit-nuxt` (Nuxt-specific rules)

## Strict Ownership Contract

Each rule family has one owner plugin only.

- `devkit-core`: workflow/reporting/spec/test-case process
- `devkit-laravel`: FormRequest, Policy/Gate, Eloquent, service/action boundaries
- `devkit-frontend`: generic frontend architecture and CSS variable/reuse rules
- `devkit-inertia`: Inertia props/forms/navigation/deferred behavior
- `devkit-vue`: component/composable/state management patterns
- `devkit-tailwind`: utility classes, arbitrary values, token mapping in Tailwind config
- `devkit-nuxt`: SSR/runtime/data conventions

Non-owner plugins may reference owner rules briefly, but must not duplicate full rule text.

## Conduct Source-of-Truth Model

- `conduct/` remains canonical policy source after migration.
- One-time migration can extract missing knowledge from existing skills into conduct.
- After cutover: `conduct first -> skill sync second`.

## No-Loss Migration Requirements

1. Build inventory from:
   - current skill files
   - current conduct files
2. Assign policy IDs and owner plugin for each policy.
3. Produce parity reports:
   - no dropped policy (unless explicitly approved)
   - reworded policy must include justification
4. Block deprecation/removal until parity is green for both sources.

## Execution Steps

1. Create plugin folders/manifests for target set.
2. Add/update conduct sections to match ownership boundaries.
3. Migrate skill content into owner plugins.
4. Add `enabledPlugins` presets for common project stacks.
5. Validate supported combinations:
   - Laravel + Inertia + Vue + Tailwind
   - Nuxt + Vue + Tailwind
   - Laravel API only
6. Deprecate old stack plugins after parity gates pass.

## Example `enabledPlugins` Presets

### Laravel + Inertia + Vue

```json
{
  "enabledPlugins": {
    "devkit-core@devkit": true,
    "devkit-laravel@devkit": true,
    "devkit-frontend@devkit": true,
    "devkit-inertia@devkit": true,
    "devkit-vue@devkit": true,
    "devkit-tailwind@devkit": true,
    "devkit-nuxt@devkit": false
  }
}
```

### Nuxt + Vue

```json
{
  "enabledPlugins": {
    "devkit-core@devkit": true,
    "devkit-frontend@devkit": true,
    "devkit-nuxt@devkit": true,
    "devkit-vue@devkit": true,
    "devkit-tailwind@devkit": true,
    "devkit-laravel@devkit": false,
    "devkit-inertia@devkit": false
  }
}
```

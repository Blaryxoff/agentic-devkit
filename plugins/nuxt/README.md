# Nuxt Plugin

Nuxt architecture, state, security, testing, and operational conduct for agent-assisted frontend projects.

## Start here

- Agent routing index: [conduct/overview.md](./conduct/overview.md)
- Plugin manifest: [plugin.json](./plugin.json)
- Skills: [skills/](./skills/)

## Baseline principles

- Keep rendering in pages/components and reusable logic in composables/services.
- Prefer Nuxt primitives for data fetching, routing, and runtime configuration.
- Keep public props, emits, API responses, and composable returns explicitly typed.
- Use Pinia only for genuinely cross-page or cross-feature state.

## Human workflow

1. Start from the relevant specification under `conduct/spec/`.
2. Design test coverage from `conduct/testing/`.
3. Use `conduct/overview.md` to select only rules relevant to the change.
4. Review with `conduct/fast_code_review_checklist.md` when appropriate.
5. Follow `conduct/git.md` and the target project's own verification commands.

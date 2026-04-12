# Migration Guide

## From `claude-code/` marketplace to `plugins/` toolkit (v2.0)

This documents breaking changes from the old Claude-Code-centric structure to the model-agnostic plugin toolkit.

### Directory renames

| Old path | New path |
|----------|----------|
| `claude-code/core/` | `plugins/core/` |
| `claude-code/frontend-base/` | `plugins/frontend/` |
| `claude-code/backend/` | `plugins/laravel/` |
| `claude-code/frontend/` | `plugins/nuxt/` |
| `claude-code/vue/` | `plugins/vue/` |
| `claude-code/inertia/` | `plugins/inertia/` |
| `claude-code/tailwind/` | `plugins/tailwind/` |

### Removed

| Path | Reason |
|------|--------|
| `claude-code/.claude-plugin/marketplace.json` | Replaced by convention-based discovery; Claude adapter generates this per-project |
| `claude-code/shared/` | Canonical files moved to `plugins/core/skills/`; symlinks removed |
| `claude-code/migrations/` | Superseded by this refactor |
| `conduct/` (top-level) | All docs moved into their owning plugins' `conduct/` subdirectory |
| `.claude-plugin/` dirs inside plugins | `plugin.json` moved to plugin root |

### Shared skill symlinks removed

Previously, shared skills (git, spec-creator, test-case-creator, reviewer-logging, plan-reviewer) existed as symlinks in `core/`, `backend/`, and `frontend/` pointing to canonical files in `shared/`.

Now: canonical files live directly in `plugins/core/skills/`. Per-plugin symlinks are gone. The resolver ensures `devkit-core` is always resolved, so its skills are always available.

### Conduct docs moved into plugins

| Old location | New location |
|--------------|--------------|
| `conduct/backend/**` | `plugins/laravel/conduct/` |
| `conduct/frontend/**` | `plugins/nuxt/conduct/` |
| `conduct/vue/overview.md` | `plugins/vue/conduct/overview.md` |
| `conduct/inertia/overview.md` | `plugins/inertia/conduct/overview.md` |
| `conduct/tailwind/overview.md` | `plugins/tailwind/conduct/overview.md` |
| `conduct/ownership-map.md` | `plugins/core/conduct/ownership-map.md` |

Internal cross-references have been updated to reflect new paths.

### Plugin manifest changes

`plugin.json` now lives at the plugin root (not inside `.claude-plugin/`), and has new fields:

```json
{
  "layer": "framework",
  "defaultEnabled": false,
  "dependencies": ["devkit-core"],
  "paths": { "skills": "./skills", "conduct": "./conduct" }
}
```

Old flat keys (`skills`, `mcpServers`, `lspServers`) moved into the `paths` object.

### New project configuration

Projects declare their stack in `.devkit/toolkit.json`:

```json
{
  "version": 1,
  "enabled": ["devkit-laravel", "devkit-vue", "devkit-inertia", "devkit-tailwind"]
}
```

Run `bin/devkit-resolve --adapter=<tool>` to generate tool-specific configs.

### Broken link fixes

- `conduct/backend/CLAUDE.md` referenced `code_review_checklist.md` -- fixed to `fast_code_review_checklist.md`
- `conduct/backend/conduct/overview.md` referenced `spec_template.md` -- fixed to `spec/spec.md`
- Various `conduct/` relative paths updated for new directory structure

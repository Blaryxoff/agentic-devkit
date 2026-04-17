# agentic-devkit

A model-agnostic toolkit of AI-agent plugins for product teams. Add it as a submodule to generate scoped AI context (skills, conduct, hooks, permissions) for Claude Code, Cursor, and Codex.

## Quick Start

```bash
git submodule add https://github.com/Blaryxoff/agentic-devkit.git toolkits/agentic-devkit
toolkits/agentic-devkit/bin/devkit-resolve --init
toolkits/agentic-devkit/bin/devkit-resolve --adapter=claude
toolkits/agentic-devkit/bin/devkit-resolve --adapter=cursor
toolkits/agentic-devkit/bin/devkit-resolve --adapter=codex
node toolkits/agentic-devkit/visual-loop/bootstrap.mjs .
```

## CLI Usage

- List resolved plugin names.

```bash
toolkits/agentic-devkit/bin/devkit-resolve
```

- Create `.devkit/toolkit.json` interactively.

```bash
toolkits/agentic-devkit/bin/devkit-resolve --init
```

- Validate config and show resolved set.

```bash
toolkits/agentic-devkit/bin/devkit-resolve --validate
```

- List resolved plugin directories.

```bash
toolkits/agentic-devkit/bin/devkit-resolve --dirs
```

- Generate tool-specific config.

```bash
toolkits/agentic-devkit/bin/devkit-resolve --adapter=...
```

Supported adapters: `claude`, `cursor`, `codex`.

## Available Plugins

| Plugin | Layer | Description | Dependencies |
|--------|-------|-------------|--------------|
| `devkit-core` | core | Cross-stack shared standards: workflow, git, spec/test-case process, review conventions | *(always enabled)* |
| `devkit-frontend` | stack | Tool-agnostic frontend architecture and generic CSS standards | core |
| `devkit-laravel` | framework | Laravel conventions: architecture, PHP, security, Inertia integration | core |
| `devkit-nuxt` | framework | Nuxt conventions: SSR, data-fetching, TypeScript, BEM/SCSS workflows | core, frontend, vue |
| `devkit-vue` | framework | Vue component, composable, and state organization conventions | core, frontend |
| `devkit-inertia` | framework | Inertia.js transport, page props contracts, and form/navigation behavior | core |
| `devkit-tailwind` | styling | Tailwind CSS utility conventions and tokenization rules | core |
| `devkit-css` | styling | Modern CSS intelligence layer from css.dev | core |

## Example Stacks

### Laravel + Vue + Tailwind

```json
{"version": 1, "enabled": ["devkit-laravel", "devkit-vue", "devkit-inertia", "devkit-tailwind"]}
```

Resolves: `core -> frontend -> vue -> inertia -> laravel -> tailwind`

### Nuxt

```json
{"version": 1, "enabled": ["devkit-nuxt"]}
```

Resolves: `core -> frontend -> vue -> nuxt`

### Laravel API only

```json
{"version": 1, "enabled": ["devkit-laravel"]}
```

Resolves: `core -> laravel`

## How It Works

1. Configure enabled plugins in `.devkit/toolkit.json` (or run `toolkits/agentic-devkit/bin/devkit-resolve --init`).
2. Resolver auto-includes `devkit-core` and transitive dependencies, validates the graph, and sorts by layer.
3. Adapter generation emits tool-specific files for the resolved set only.

| Adapter | Generated files |
|---------|------------------|
| `claude` | `.claude-plugin/marketplace.json`, `.claude/settings.json` (merged permissions + hooks) |
| `cursor` | `.cursor/rules/devkit-*.mdc`, `.cursor/skills/devkit-*--*/` (symlinks), `.cursor/hooks/hooks.json` |
| `codex` | `.codex/skills/devkit-*--*/` (symlinks), managed `devkit-toolkit` section in `AGENTS.md` (conduct + hook instructions) |

Disabled plugins do not enter generated AI context.

## Claude Code Plugin Setup (Local Scope)

1. In terminal, generate Claude config:

```bash
toolkits/agentic-devkit/bin/devkit-resolve --adapter=claude
```

2. In Claude Code chat (not terminal), run:
- `/plugin marketplace add ./`
- `/plugin install <plugin-name>@devkit`
- `/reload-plugins`

3. For each install prompt, choose local scope for this repository.

## Repository Layout

```text
plugins/              Convention-based plugin discovery (plugins/*/plugin.json)
  core/
  frontend/
  laravel/
  nuxt/
  vue/
  inertia/
  tailwind/
  css/
bin/
  devkit-resolve      CLI: init/resolve/validate/adapter generation
adapters/
  _lib/resolve.sh     Shared resolution logic
  _lib/hooks.sh       Shared hook merge/translation helpers
  claude/generate
  cursor/generate
  codex/generate
schemas/              JSON schemas for toolkit and plugin manifests
examples/             Starter .devkit/toolkit.json presets
howto/                Developer guides (Russian)
visual-loop/          Visual screenshot-diff bootstrap tool
```

## Extending the Toolkit

### Add a plugin

1. Create `plugins/<name>/plugin.json`.
2. Add skills at `plugins/<name>/skills/<skill>/SKILL.md`.
3. Add conduct docs at `plugins/<name>/conduct/*.md` (if applicable).
4. Verify in a consuming project with `toolkits/agentic-devkit/bin/devkit-resolve --validate`.

### Add a skill

Add `SKILL.md` under `plugins/<plugin>/skills/<skill-name>/`. Adapters pick it up on next generation.

### Add an adapter

See [adapters/README.md](adapters/README.md).

## Requirements

- `jq`
- `python3`
- `bash` 3.2+

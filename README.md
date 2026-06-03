# agentic-devkit

A model-agnostic toolkit of AI-agent plugins for product teams. One **global clone** generates scoped AI context
(skills, conduct, hooks, permissions) for Claude Code, Cursor, and Codex across all your projects. Edit a skill once;
every project picks it up.

## Quick Start

Install the toolkit once per machine. `devkit-install` clones it to `~/.claude/agentic-devkit` (the global clone,
`DEVKIT_HOME`), symlinks the universal core skills + the `devkit` stack-router into `~/.claude/skills/`, installs the
core subagents, and adds a daily auto-update hook.

```bash
git clone https://github.com/Blaryxoff/agentic-devkit.git ~/.claude/agentic-devkit
~/.claude/agentic-devkit/bin/devkit-install
```

Per project, declare the stack in `.devkit/toolkit.json` and (for Cursor/Codex, or to emit Claude stack subagents/MCP)
run the adapter from the global clone:

```bash
cd my-project
~/.claude/agentic-devkit/bin/devkit-resolve --init          # write .devkit/toolkit.json

~/.claude/agentic-devkit/bin/devkit-install --cursor         # .cursor/ rules + skills + hooks
~/.claude/agentic-devkit/bin/devkit-install --codex          # AGENTS.md + .codex/ skills
~/.claude/agentic-devkit/bin/devkit-install --claude         # .claude/ stack subagents, hooks, .mcp.json

node ~/.claude/agentic-devkit/visual-loop/bootstrap.mjs .
```

For Claude Code, the core skills + `devkit` router are already global after `devkit-install`; the per-project
`--claude` run is only needed when a stack ships subagents, hooks, or MCP servers.

## CLI Usage

- List resolved plugin names.

```bash
~/.claude/agentic-devkit/bin/devkit-resolve
```

- Create `.devkit/toolkit.json` interactively.

```bash
~/.claude/agentic-devkit/bin/devkit-resolve --init
```

- Validate config and show resolved set.

```bash
~/.claude/agentic-devkit/bin/devkit-resolve --validate
```

- List resolved plugin directories.

```bash
~/.claude/agentic-devkit/bin/devkit-resolve --dirs
```

- Generate tool-specific config.

```bash
~/.claude/agentic-devkit/bin/devkit-resolve --adapter=...
```

Supported adapters: `claude`, `cursor`, `codex`.

## Available Plugins

| Plugin            | Layer     | Description                                                                             | Dependencies        |
|-------------------|-----------|-----------------------------------------------------------------------------------------|---------------------|
| `devkit-core`     | core      | Cross-stack shared standards: workflow, git, spec/test-case process, review conventions | *(always enabled)*  |
| `devkit-frontend` | stack     | Tool-agnostic frontend architecture and generic CSS standards                           | core                |
| `devkit-laravel`  | framework | Laravel conventions: architecture, PHP, security, Inertia integration                   | core                |
| `devkit-nuxt`     | framework | Nuxt conventions: SSR, data-fetching, TypeScript, BEM/SCSS workflows                    | core, frontend, vue |
| `devkit-vue`      | framework | Vue component, composable, and state organization conventions                           | core, frontend      |
| `devkit-inertia`  | framework | Inertia.js transport, page props contracts, and form/navigation behavior                | core                |
| `devkit-tailwind` | styling   | Tailwind CSS utility conventions and tokenization rules                                 | core                |
| `devkit-css`      | styling   | Modern CSS intelligence layer from css.dev                                              | core                |

## Example Stacks

### Laravel + Vue + Tailwind

```json
{
  "version": 1,
  "enabled": [
    "devkit-laravel",
    "devkit-vue",
    "devkit-inertia",
    "devkit-tailwind"
  ]
}
```

Resolves: `core -> frontend -> vue -> inertia -> laravel -> tailwind`

### Nuxt

```json
{
  "version": 1,
  "enabled": [
    "devkit-nuxt"
  ]
}
```

Resolves: `core -> frontend -> vue -> nuxt`

### Laravel API only

```json
{
  "version": 1,
  "enabled": [
    "devkit-laravel"
  ]
}
```

Resolves: `core -> laravel`

## How It Works

1. Configure enabled plugins in `.devkit/toolkit.json` (or run `~/.claude/agentic-devkit/bin/devkit-resolve --init`).
2. Resolver auto-includes `devkit-core` and transitive dependencies, validates the graph, and sorts by layer.
3. Adapter generation emits tool-specific files for the resolved set only.

| Adapter  | Generated files                                                                                                        |
|----------|------------------------------------------------------------------------------------------------------------------------|
| `claude` | `.claude/settings.json` (hooks), `.claude/agents/*.md` (stack subagents), `.mcp.json` — core skills + router are global |
| `cursor` | `.cursor/rules/devkit-*.mdc`, `.cursor/skills/devkit-*--*/` (symlinks), `.cursor/hooks/hooks.json`                     |
| `codex`  | `.codex/skills/devkit-*--*/` (symlinks), managed `devkit-toolkit` section in `AGENTS.md` (conduct + hook instructions) |

Generated text (conduct paths in `.mdc` / `AGENTS.md`) references the global clone at `~/.claude/agentic-devkit`, so
output is identical regardless of where the project lives on disk. Disabled plugins do not enter generated AI context.

## Claude Code Setup

Core skills and the `devkit` stack-router are installed globally by `devkit-install` (symlinked into `~/.claude/skills/`),
so Claude Code auto-discovers them in every project — no `/plugin install` step. Core skills auto-match natively; the
`devkit` router reads `.devkit/toolkit.json` and loads the matching stack skill + conduct on demand from the global clone.

Run the per-project Claude adapter only when a stack ships subagents, hooks, or MCP servers:

```bash
~/.claude/agentic-devkit/bin/devkit-install --claude --project=.
```

This emits `.claude/agents/*.md` (stack subagents), `.claude/settings.json` (plugin hooks), and `.mcp.json` — all
referencing the global clone. Re-run only when the enabled-plugin set or infra files change; skill/conduct edits
propagate live through the clone (kept current by the daily auto-update hook).

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
  devkit-install      Global installer: core skills + router + subagents + auto-update hook
  devkit-update       Timestamp-guarded `git pull --ff-only` for the global clone
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
4. Verify in a consuming project with `~/.claude/agentic-devkit/bin/devkit-resolve --validate`.

### Add a skill

Add `SKILL.md` under `plugins/<plugin>/skills/<skill-name>/`. Adapters pick it up on next generation.

### Add an adapter

See [adapters/README.md](adapters/README.md).

## Requirements

- `jq`
- `python3`
- `bash` 3.2+

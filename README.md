# agentic-devkit

A model-agnostic toolkit of AI-agent plugins for product teams. Include as a git submodule to give Claude Code, Cursor, and Codex precisely scoped skills, rules, and coding standards for your project stack.

## Quick Start

```bash
# Add as submodule
git submodule add https://github.com/Blaryxoff/agentic-devkit.git toolkits/agentic-devkit

# Create project config
mkdir -p .devkit
cat > .devkit/toolkit.json << 'EOF'
{
  "version": 1,
  "enabled": ["devkit-laravel", "devkit-vue", "devkit-inertia", "devkit-tailwind"]
}
EOF

# Generate config for your AI tool
toolkits/agentic-devkit/bin/devkit-resolve --adapter=claude
toolkits/agentic-devkit/bin/devkit-resolve --adapter=cursor
toolkits/agentic-devkit/bin/devkit-resolve --adapter=codex
```

## Available Plugins

| Plugin | Layer | Description | Dependencies |
|--------|-------|-------------|--------------|
| `devkit-core` | core | Shared engineering standards: git, spec/test workflow, review conventions | *(always enabled)* |
| `devkit-frontend` | stack | Tool-agnostic frontend architecture and generic CSS | core |
| `devkit-laravel` | framework | Laravel architecture, PHP, security, Inertia integration | core |
| `devkit-nuxt` | framework | Nuxt 3 SSR, data-fetching, TypeScript, BEM/SCSS | core, frontend, vue |
| `devkit-vue` | framework | Vue component, composable, and state conventions | core, frontend |
| `devkit-inertia` | framework | Inertia.js transport and page contract rules | core |
| `devkit-tailwind` | styling | Tailwind CSS utility and tokenization rules | core |

## Example Stacks

### Laravel + Vue + Tailwind
```json
{"version": 1, "enabled": ["devkit-laravel", "devkit-vue", "devkit-inertia", "devkit-tailwind"]}
```
Resolves: `core -> frontend -> vue -> inertia -> laravel -> tailwind`

### Nuxt (standalone)
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

1. **Project config** (`.devkit/toolkit.json`) lists enabled plugins.
2. **Resolver** (`bin/devkit-resolve`) reads the config, auto-includes `devkit-core` and transitive dependencies, detects cycles, and sorts by layer.
3. **Adapters** translate the resolved set into tool-specific configs:

| Adapter | Generates |
|---------|-----------|
| `claude` | `.claude-plugin/marketplace.json` + `.claude/settings.json` with `enabledPlugins` |
| `cursor` | `.cursor/rules/devkit-*.mdc` (conduct) + `.cursor/skills/` (symlinks) |
| `codex` | `.codex/skills/` (symlinks) + `AGENTS.md` conduct section |

Disabled plugins are never generated -- their skills, rules, and conduct do not enter the AI's context.

## Repository Layout

```
plugins/              All plugins (convention-based discovery)
  core/               Shared skills + ownership map
  frontend/           Generic frontend + CSS
  laravel/            Laravel skills + conduct
  nuxt/               Nuxt skills + conduct
  vue/                Vue skills + conduct
  inertia/            Inertia skills + conduct
  tailwind/           Tailwind skills + conduct
bin/
  devkit-resolve        CLI: resolve plugins, validate, run adapters
adapters/
  _lib/resolve.sh     Shared resolution algorithm (bash + jq)
  claude/generate     Claude Code adapter
  cursor/generate     Cursor adapter
  codex/generate      Codex adapter
schemas/              JSON schemas for toolkit.json and plugin.json
examples/             Example .devkit/toolkit.json files
howto/                Developer guides (Russian)
visual-loop/          Reusable visual screenshot-diff bootstrap tool
```

## Adding a Plugin

1. Create `plugins/<name>/plugin.json`:
   ```json
   {
     "name": "devkit-<name>",
     "version": "0.1.0",
     "description": "What this plugin provides",
     "layer": "framework",
     "defaultEnabled": false,
     "dependencies": ["devkit-core"],
     "paths": { "skills": "./skills", "conduct": "./conduct" }
   }
   ```
2. Add skill files at `plugins/<name>/skills/<skill>/SKILL.md`.
3. Add conduct docs at `plugins/<name>/conduct/*.md`.
4. The resolver discovers it automatically -- no registry edits needed.

## Adding a Skill to an Existing Plugin

Drop a directory with `SKILL.md` into the plugin's `skills/` folder. The adapters pick it up on next run.

## Adding an Adapter

See [adapters/README.md](adapters/README.md) for the adapter development guide.

## Requirements

- `jq` (for JSON processing in the resolver)
- `python3` (for relative path computation)
- `bash` 3.2+ (macOS default)

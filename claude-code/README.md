# Claude Code — rubx Marketplace

This directory is a Claude Code plugin marketplace containing rubx's plugins.

## Available Plugins

| Plugin | Stack | Skills |
|--------|-------|--------|
| `rubx-core` | Cross-stack | git, reviewer-logging, spec-creator, test-case-creator |
| `rubx-frontend` | Tool-agnostic frontend + CSS | frontend-guidelines |
| `rubx-inertia` | Inertia transport/page contracts | inertia-guidelines |
| `rubx-vue` | Vue conventions | vue-guidelines |
| `rubx-tailwind` | Tailwind conventions | tailwind-guidelines |
| `rubx-nuxt` | Nuxt 3 + TypeScript + BEM | coder, reviewer-deep, reviewer-fast, reviewer-architecture, reviewer-logging, reviewer-error-handling, reviewer-security, spec-creator, test-case-creator, tester, git |
| `rubx-laravel` | Laravel + Inertia + Vue 3 | coder, reviewer-deep, reviewer-fast, reviewer-architecture, reviewer-logging, reviewer-error-handling, reviewer-security, spec-creator, test-case-creator, tester, git |

## Installation

### 1. Clone the repo

```bash
git clone https://github.com/Blaryxoff/rubx-agentic-tools.git ~/www/rubx-agentic-tools
```

### 2. Register the marketplace

```
/plugin marketplace add ~/www/rubx-agentic-tools/claude-code
```

### 3. Install the plugin for your project

```
/plugin install rubx-nuxt@rubx
```
```
/plugin install rubx-laravel@rubx
```
```
/plugin install rubx-core@rubx
```
```
/plugin install rubx-frontend@rubx
```
```
/plugin install rubx-inertia@rubx
```
```
/plugin install rubx-vue@rubx
```
```
/plugin install rubx-tailwind@rubx
```

### 4. Enable only the plugins your project needs

Example for Laravel + Inertia + Vue projects:

```json
{
  "enabledPlugins": {
    "rubx-core@rubx": true,
    "rubx-laravel@rubx": true,
    "rubx-frontend@rubx": true,
    "rubx-inertia@rubx": true,
    "rubx-vue@rubx": true,
    "rubx-tailwind@rubx": true,
    "rubx-nuxt@rubx": false
  }
}
```

## Updating

```bash
cd ~/www/rubx-agentic-tools
git pull
```

Then reload in any running Claude Code session:

```
/reload-plugins
```

## Plugin Structure

Each plugin under this marketplace follows this layout:

| Path | Purpose |
|------|---------|
| `.claude-plugin/plugin.json` | Plugin manifest (name, version, component paths) |
| `skills/` | Custom skills — each is a directory with `SKILL.md` |
| `agents/` | Custom subagent definitions — `.md` files with YAML frontmatter |
| `hooks/hooks.json` | Hook definitions (PreToolUse, PostToolUse, Stop, etc.) |
| `hooks/scripts/` | Shell scripts referenced by hooks |
| `mcp-servers/` | Custom MCP server source code |
| `.mcp.json` | MCP server configurations |
| `.lsp.json` | LSP server configurations |
| `settings.json` | Claude Code settings (permissions, env) |

## Conduct Standards

Stack-specific coding standards live in `conduct/`:

- `conduct/frontend/` — Nuxt 3 + TypeScript + BEM conventions
- `conduct/backend/` — Laravel + Inertia + Vue 3 conventions
- `conduct/inertia/` — Inertia transport and props contract conventions
- `conduct/vue/` — Vue component/composable/state conventions
- `conduct/tailwind/` — Tailwind-specific style conventions
- `conduct/ownership-map.md` — strict rule ownership map for plugins

## Project Setup: Permission Deny Rules

Each plugin ships a `settings.json` with `permissions.deny` rules that block Claude Code from reading or editing build artifacts, dependency folders, secrets, and environment files.

To apply these rules to your project:

```bash
# For Nuxt projects
cp ~/www/rubx-agentic-tools/claude-code/frontend/settings.json <your-project>/.claude/settings.json

# For Laravel projects
cp ~/www/rubx-agentic-tools/claude-code/backend/settings.json <your-project>/.claude/settings.json
```

If your project already has a `.claude/settings.json`, merge the `permissions.deny` array instead of overwriting.

## Adding a New Plugin

1. Create `claude-code/<plugin-name>/` with the structure above
2. Add an entry to `.claude-plugin/marketplace.json` plugins array
3. Update this README

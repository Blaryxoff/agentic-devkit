# rubx-agentic-tools

A shared toolkit for AI-assisted development across rubx product teams. Contains Claude Code plugins, coding conduct standards, and developer guides.

## What's Inside

| Directory | Purpose |
|-----------|---------|
| `claude-code/` | Claude Code plugin marketplace (`rubx-nuxt`, `rubx-laravel`) |
| `conduct/frontend/` | Coding standards for Nuxt 3 + TypeScript + BEM projects |
| `conduct/backend/` | Coding standards for Laravel + Inertia + Vue 3 projects |
| `howto/` | Guides for Claude Code, AI tooling, and team practices |

## Quick Start

### 1. Clone

```bash
git clone https://github.com/Blaryxoff/rubx-agentic-tools.git ~/www/rubx-agentic-tools
```

### 2. Register the Claude Code marketplace

```
/plugin marketplace add ~/www/rubx-agentic-tools/claude-code
```

### 3. Install the plugin for your project stack

```
/plugin install rubx-nuxt@rubx      # Nuxt 3 projects
/plugin install rubx-laravel@rubx   # Laravel projects
```

## Using as a Submodule

To add to a project:

```bash
git submodule add https://github.com/Blaryxoff/rubx-agentic-tools.git toolkits/rubx-agentic-tools
git submodule update --init --recursive
```

To update:

```bash
git submodule update --remote --merge
```

## Contributing

See [CLAUDE.md](CLAUDE.md) for conventions on adding skills, updating conduct docs, and versioning.

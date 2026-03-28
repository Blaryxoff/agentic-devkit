# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Repo Is

A Claude Code **plugin marketplace** for product teams. It contains plugins that bundle skills, hooks, agents, MCP/LSP configs, and shared coding conduct for AI-assisted web product development.

This is NOT an application project itself. It is a collection of Markdown-based skill definitions, JSON configs, and guidance docs. There is no runtime app in this repository.

## Repository Layout

```
claude-code/                         # Marketplace root
├── .claude-plugin/marketplace.json  # Registry: lists all plugins
├── README.md                        # Installation & usage docs
├── frontend/                        # "rubx-nuxt" plugin (Nuxt 3 + TypeScript + BEM)
│   ├── .claude-plugin/plugin.json   # Plugin manifest
│   ├── skills/                      # Skill definitions (each dir has SKILL.md)
│   ├── .mcp.json / .lsp.json        # Server configs
│   └── settings.json / hooks.json   # Plugin settings and hook defs
└── backend/                         # "rubx-laravel" plugin (Laravel + Inertia + Vue 3)
    ├── .claude-plugin/plugin.json   # Plugin manifest
    ├── skills/                      # Skill definitions (each dir has SKILL.md)
    ├── agents/                      # Subagent definitions
    ├── hooks/                       # Hook scripts
    ├── mcp-servers/                 # MCP server source
    ├── .mcp.json / .lsp.json        # Server configs
    └── settings.json / hooks.json   # Plugin settings and hook defs

conduct/
├── frontend/                        # Nuxt conduct standards
│   ├── CLAUDE.md                    # Stack overview and reading order
│   ├── conduct/*.md                 # Architecture, security, logging, etc.
│   ├── spec/                        # Feature spec template
│   └── testing/                     # Test-case guidelines
└── backend/                         # Laravel conduct standards
    ├── CLAUDE.md                    # Stack overview and reading order
    ├── conduct/*.md                 # Architecture, PHP, security, logging, etc.
    ├── spec/                        # Feature spec template
    └── testing/                     # Test-case guidelines

howto/                               # Developer guides for Claude Code and AI tooling
```

## Key Conventions

### Versioning
When adding, removing, or renaming skills/components, bump the version in **both**:
- `claude-code/<plugin>/.claude-plugin/plugin.json` — the plugin manifest
- `claude-code/.claude-plugin/marketplace.json` — the marketplace registry

### Skills
- Each skill lives in `claude-code/<plugin>/skills/<skill-name>/SKILL.md`
- SKILL.md has YAML frontmatter (`name`, `description`) followed by the prompt body
- Skill names use the `rubx-` prefix in frontmatter (e.g. `rubx-reviewer-fast`)
- Directory names omit the prefix (e.g. `reviewer-fast/`)
- Reviewer skills follow a naming pattern: `reviewer-<focus>` (not `<focus>-reviewer`)
- Skills should be self-sufficient and focused on the active stack

### Conduct
- Frontend (Nuxt) conduct lives in `conduct/frontend/`
- Backend (Laravel) conduct lives in `conduct/backend/`
- Conduct docs are stack-specific and should not be merged across stacks

## Common Commands

```bash
# Clone
git clone https://github.com/Blaryxoff/rubx-agentic-tools.git ~/www/rubx-agentic-tools

# Open plugin docs
open claude-code/README.md
```

## Adding a New Skill

1. Create `claude-code/<plugin>/skills/<skill-name>/SKILL.md` with frontmatter
2. Make guidance explicit for the active project stack and conventions
3. Update `claude-code/README.md` plugin table
4. Bump version in both `plugin.json` and `marketplace.json`

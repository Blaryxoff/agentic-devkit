# CLAUDE.md

This file provides guidance to AI agents working with code in this repository.

## What This Repo Is

A model-agnostic **plugin toolkit** for AI-assisted product development. It ships plugins that bundle skills, conduct
docs, hooks, MCP/LSP configs, and shared coding standards. Included as a git submodule at `toolkits/agentic-devkit` in
consuming projects.

This is NOT an application project. It is a collection of Markdown-based skill definitions, JSON configs, shell scripts,
and standards docs.

## Repository Layout

```
plugins/                 All plugins (convention: plugins/*/plugin.json)
  core/                  Always-on shared standards (git, spec, test-case, review)
  frontend/              Generic frontend architecture + CSS
  laravel/               Laravel framework skills + conduct
  nuxt/                  Nuxt 3 framework skills + conduct
  vue/                   Vue component/state conventions
  inertia/               Inertia.js transport rules
  tailwind/              Tailwind CSS conventions
bin/
  devkit-resolve           CLI entry point for resolution and adapter generation
adapters/
  _lib/resolve.sh        Core resolution algorithm (bash + jq)
  claude/generate        Claude Code adapter
  cursor/generate        Cursor IDE adapter
  codex/generate         OpenAI Codex adapter
schemas/                 JSON schemas for toolkit.json and plugin.json
examples/                Example .devkit/toolkit.json files
howto/                   Developer guides (Russian)
visual-loop/             Reusable visual screenshot-diff bootstrap tool
```

## Key Conventions

### Plugins

- Each plugin is a directory under `plugins/` with a `plugin.json` manifest.
- Discovery is convention-based: any `plugins/*/plugin.json` is a plugin.
- Plugin names use the `devkit-` prefix (e.g. `devkit-laravel`).
- Directory names match the technology (e.g. `laravel/`, not `backend/`).

### Skills

- Each skill lives in `plugins/<plugin>/skills/<skill-name>/SKILL.md`.
- SKILL.md has YAML frontmatter (`name`, `description`) followed by the prompt body.
- Skill names use the `devkit-` prefix in frontmatter.
- Shared skills (git, spec-creator, etc.) live ONLY in `core/` -- never duplicated.
- Stack-specific skills live in their owning plugin.

### Conduct

- Each plugin may have a `conduct/` directory with Markdown standards docs.
- Conduct is the canonical source of truth; skills summarize and enforce conduct.
- Cross-plugin references use relative paths (e.g. `../../vue/conduct/overview.md`).
- **Conduct docs are the extension mechanism for core skills.** Core skills (plan-reviewer, spec-creator, git, etc.)
  automatically discover and enforce conduct rules from all active plugins by reading `.devkit/toolkit.json` and
  scanning each plugin's `conduct/` directory. To add a new rule that core skills should enforce, add a `.md` file to
  the appropriate plugin's `conduct/` directory -- no skill changes needed.

### Plugin Manifests

- `layer` determines loading order: `core` -> `stack` -> `framework` -> `styling`.
- `dependencies` are auto-resolved transitively.
- `defaultEnabled: true` only for `devkit-core`.
- `paths` object groups resource locations.

### Resolution

- Project declares enabled plugins in `.devkit/toolkit.json`.
- `devkit-core` is always included.
- Transitive dependencies are auto-included.
- Disabled plugins are excluded from all generated context.

## Common Commands

```bash
# Resolve plugins for a project
bin/devkit-resolve --validate

# Generate configs
bin/devkit-resolve --adapter=claude
bin/devkit-resolve --adapter=cursor
bin/devkit-resolve --adapter=codex
```

## Adding a New Plugin

1. Create `plugins/<name>/plugin.json` with the standard schema.
2. Add skills at `plugins/<name>/skills/<skill>/SKILL.md`.
3. Add conduct docs at `plugins/<name>/conduct/*.md`.
4. No registry edits needed -- discovery is automatic.

## Adding a New Skill

Create `plugins/<plugin>/skills/<skill-name>/SKILL.md` with frontmatter. The adapters pick it up on next run.

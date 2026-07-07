# CLAUDE.md

This file provides guidance to AI agents working with code in this repository.

## What This Repo Is

A model-agnostic **plugin toolkit** for AI-assisted product development. It ships plugins that bundle skills, conduct
docs, hooks, MCP/LSP configs, and shared coding standards. Installed as a single **global clone** at
`~/.claude/agentic-devkit` (`DEVKIT_HOME`) via `bin/devkit-install`; consuming projects keep only a per-repo
`.devkit/toolkit.json` selecting their stack. Editing a skill in the clone propagates to every project (daily
auto-update via a SessionStart hook).

This is NOT an application project. It is a collection of Markdown-based skill definitions, JSON configs, shell scripts,
and standards docs.

## Repository Layout

```
plugins/                 All plugins (convention: plugins/*/plugin.json)
  core/                  Always-on shared standards (git, plan, test-case, review) + output-styles/
  frontend/              Generic frontend architecture + CSS
  laravel/               Laravel framework skills + conduct
  nuxt/                  Nuxt framework skills + conduct
  vue/                   Vue component/state conventions
  inertia/               Inertia.js transport rules
  tailwind/              Tailwind CSS conventions
bin/
  devkit-install           Global installer: core skills + devkit router + core subagents + output styles + auto-update hook
  devkit-update            Timestamp-guarded `git pull --ff-only` for the global clone (SessionStart hook)
  devkit-resolve           CLI entry point for resolution and adapter generation (repeatable --project for multi-repo)
adapters/
  _lib/resolve.sh        Core resolution algorithm (bash + jq); multi-root union of enabled plugins
  _lib/hooks.sh          Shared hook merging + event translation (DRY adapter pattern)
  _lib/claude_agents.sh  Shared subagent generation (used by claude/generate + devkit-install)
  claude/generate        Claude Code adapter (slim: per-project stack subagents, hooks, MCP — core is global)
  cursor/generate        Cursor IDE adapter
  codex/generate         OpenAI Codex adapter
schemas/                 JSON schemas for toolkit.json and plugin.json
examples/                Example .devkit/toolkit.json files
howto/                   Developer guides (Russian)
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
- Skill names use the `devkit-` or `ralphex-` prefix in frontmatter.
- Shared skills (git, plan-creator, plan-reviewer, etc.) live ONLY in `core/` -- never duplicated.
- Stack-specific skills live in their owning plugin.

### Conduct

- Each plugin may have a `conduct/` directory with Markdown standards docs.
- Conduct is the canonical source of truth; skills summarize and enforce conduct.
- Cross-plugin references use relative paths (e.g. `../../vue/conduct/overview.md`).
- **Conduct docs are the extension mechanism for core skills.** Core skills (plan-reviewer, plan-creator, git, etc.)
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

## Writing Skills, Conduct, and Rules

The audience is an LLM. Optimise for signal density — every line spends context.

### Structure

- **Lead with the directive.** Sentence one of every section/bullet states what to do (or not do). Reasoning follows only when non-obvious.
- **One rule per line.** Use bullets for unordered rules, numbered lists for ordered steps, tables for 3+ structured fields (commands, contracts, mappings).
- **Imperative voice.** `Cite section numbers.` — not `Section numbers should be cited.`
- **Cite, don't restate.** Reference `§7.5` or `path/to/file.md:42`; let the reader scroll. Never paraphrase what another section already says.
- **Code blocks for exact shapes.** File paths, command names, config snippets, recipe names — anything that must match verbatim.
- **No intro paragraphs** that restate the heading. No closing summaries that restate the bullets. Headings are the table of contents.

### Frontmatter (skills)

- `name`: kebab-case, prefixed (`devkit-…` / `ralphex-…`).
- `description`: this is the trigger an LLM matches against — be specific about *when* to invoke. `bootstrap or audit a project's Docker deployment` beats `Docker helper`. Include the inputs/outputs and the situations that skip the skill.

### Skill vs conduct division

- **Conduct = canonical rules.** Long-form, numbered sections, exhaustive. The source of truth.
- **Skill = workflow.** Short, action-oriented. Tells the agent *what to do, in what order, citing which conduct sections.* Never re-encode the rules — link.
- One skill = one workflow. If two skills overlap, one delegates to the other.

### Anti-patterns (don't do this)

- Hedging language (`usually`, `might want to`, `consider`, `it's a good idea to`) when the rule is actually mandatory. State the rule; mark genuine exceptions with `unless …`.
- Vague nouns (`approach`, `strategy`, `framework`, `proper handling`) without concrete content. Replace with the specific verb + object.
- Multi-clause sentences when two short sentences are clearer.
- Examples that restate the rule. Use examples only for ambiguity — and prefer a right/wrong pair over prose.
- Project-specific codenames, hostnames, brand names, or org-specific port numbers. This toolkit is project-agnostic.
- "As mentioned above." Restate the noun or cite the section.
- Duplicating conduct content in a skill, or vice versa.

### When to add vs edit

- A new rule belongs in **conduct** (so core skills auto-discover it via `plugins/*/conduct/`). Skills change only when the *workflow* changes.
- Before adding a new section, grep for the topic — extend the existing section instead of opening a parallel one.

## Common Commands

```bash
# One-time global install (core skills + devkit router + core subagents + auto-update hook)
bin/devkit-install

# Update the global clone now (the SessionStart hook runs `--if-stale` daily)
bin/devkit-update

# Resolve plugins for a project (repeat --project for a multi-repo backend+frontend project)
bin/devkit-resolve --validate
bin/devkit-resolve --dirs --project=<backend> --project=<frontend>

# Per-project adapter generation (stack infra; core/router are already global)
bin/devkit-install --claude --project=.    # or: bin/devkit-resolve --adapter=claude
bin/devkit-install --cursor --project=.
bin/devkit-install --codex --project=.
```

## Adding a New Plugin

1. Create `plugins/<name>/plugin.json` with the standard schema.
2. Add skills at `plugins/<name>/skills/<skill>/SKILL.md`.
3. Add conduct docs at `plugins/<name>/conduct/*.md`.
4. No registry edits needed -- discovery is automatic.

## Adding a New Skill

Create `plugins/<plugin>/skills/<skill-name>/SKILL.md` with frontmatter. The adapters pick it up on next run.

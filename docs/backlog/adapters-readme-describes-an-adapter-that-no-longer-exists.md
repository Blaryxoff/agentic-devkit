---
worth: yes
where: adapters/README.md:9
added: 2026-09-02
---
# `adapters/README.md` is stale in four places at once

1. **Claude adapter output row (`:9`)** — claims `.claude-plugin/marketplace.json` and `.claude/settings.json`
   "(permissions + hooks)". The adapter *deletes* `.claude-plugin/` as a legacy artifact
   (`adapters/claude/generate:51-55`), merges no permissions (`:109`), and additionally emits `.claude/agents/*.md`,
   `.claude/skills/devkit-*--*` symlinks, and `.mcp.json` — none of which the row mentions. `MIGRATION.md:60` repeats
   the same stale `marketplace.json` claim.
2. **"Codex does not support native hooks" (`:66-72`)** — false since the `config.toml` gate landed.
   `bin/devkit-install:338` writes `[[hooks.PreToolUse]]` blocks into `~/.codex/config.toml` (literal TOML at
   `:470-481`) and `README.md:151-153` documents exactly that. The same stale comment sits in
   `adapters/codex/generate:20` and `:124`. A contributor following this doc would re-implement instruction-based hooks
   the installer already supersedes.
3. **Usage block (`:16-19`)** — invokes `toolkits/agentic-devkit/bin/devkit-resolve` and is captioned "toolkit submodule
   at toolkits/agentic-devkit". `MIGRATION.md:3-8` records that layout as replaced by the single global clone.
4. **Shared-library docs (`:28-32`, `:39-56`)** — "Adding a New Adapter" names only `_lib/resolve.sh` and
   `_lib/hooks.sh`. `_lib/claude_agents.sh` and `_lib/mcp.sh` are undocumented, yet subagent emission and MCP merging
   are the bulk of what the Claude adapter does. The `_lib/resolve.sh` export table also omits `toolkit_abspath`,
   `toolkit_home_ref`, `_project_roots`, `_collect_enabled`, `ensure_gitignore_entry`. The environment table (`:74-78`)
   omits `DEVKIT_HOME_DIR` and does not note that `--project` is repeatable.

The `.claude/skills/devkit-*--*` output channel is undocumented in `README.md:136` and `CLAUDE.md:35` too, so a user
cleaning up or gitignoring will not expect it.

Related: [[plugin-paths-settings-and-lsp-never-read]].

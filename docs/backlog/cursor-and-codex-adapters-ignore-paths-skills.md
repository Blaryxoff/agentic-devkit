---
worth: yes
where: adapters/cursor/generate:58
added: 2026-09-02
---
# Cursor and Codex adapters ignore `paths.skills` and link skill dirs with no SKILL.md

Both hardcode `$plugin_dir/skills` (`adapters/cursor/generate:58`, `:102`; `adapters/codex/generate:53`, `:82`) and link
every subdirectory unconditionally, while `adapters/claude/generate:81-88` and `adapters/_lib/claude_agents.sh:112-118`
honour `.paths.skills` and require a `SKILL.md`. `schemas/plugin.schema.json:44-47` defines `paths.skills` as
"Directory containing skill subdirectories, each with SKILL.md".

Consequence today: an empty `plugins/frontend/skills/pixel-loop/` on disk is linked as `devkit-frontend--pixel-loop` by
both adapters and counted in the resolved-skill total. (The directory is untracked — git cannot hold empty dirs — so it
affects working checkouts, not fresh clones.) A plugin declaring `paths.skills` under a different directory name would
be skipped entirely by Cursor and Codex.

Fix: read `.paths.skills` in both and add `[ -f "$skill_dir/SKILL.md" ] || continue`.

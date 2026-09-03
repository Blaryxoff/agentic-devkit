---
worth: yes
where: bin/devkit-install:220
added: 2026-09-02
---
# `settings.json` writes truncate the target before the producing process runs

`printf '%s\n' "$updated" | jq '.' > "$SETTINGS"` opens and truncates the user's global `~/.claude/settings.json` at
redirection setup; only then does `jq` run. Any interruption or `jq` fault between those two events leaves an empty
settings file with no backup. The same file is rewritten this way five times in one install run
(`:220`, `:289`, `:306`, `:323`, `:335`, `:560`), and the adapters repeat it for project files
(`adapters/claude/generate:119`, `:143`; `adapters/cursor/generate:210`, `:231`).

The Codex config block in the same script already does it correctly (`:490-497`): write to `config.toml.devkit.tmp`,
`chmod`, then `Path.replace()`.

Fix: one `write_json <dest> <json>` helper doing tmp-then-`mv -f`, routed through all sites.

Related: [[install-resets-malformed-cursor-hooks]].

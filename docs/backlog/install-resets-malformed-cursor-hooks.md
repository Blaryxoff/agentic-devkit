---
worth: yes
where: bin/devkit-install:332
added: 2026-09-02
---
# An unparseable global `~/.cursor/hooks/hooks.json` is silently reset to `{}` and overwritten

`jq … 2>/dev/null || echo '{}'` swallows every parse error, and the resulting `{}` is written straight back over the
file at `:335`. The user's hooks are gone with no message, under their real `$HOME`, from the primary install command,
with no backup.

The same swallow exists for plugin hook files at `adapters/_lib/hooks.sh:53` — a malformed plugin `hooks.json` is
silently treated as empty.

Fix: abort with `ERROR: <file> is not valid JSON — fix or move it, then re-run.` rather than clobber. Make the plugin
one at least warn.

Related: [[json-writes-truncate-before-producing-output]]. The Cursor adapter's own overwrite-without-reading defect
(the same class, in project-level `.cursor/hooks/hooks.json`) was fixed 2026-09-03.

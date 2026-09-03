---
worth: yes
where: bin/devkit-install:72
added: 2026-09-02
---
# A dangling devkit-owned symlink is misreported as the user's own file and never repaired

The no-clobber guarantee (`CLAUDE.md:76-77`) distinguishes devkit files two ways: symlinks resolving inside
`DEVKIT_HOME`, and regular files carrying `COMMAND_SENTINEL`. `links_into_devkit` resolves the target with
`cd … || return 1`, so once the old clone directory is gone — relocation, re-clone under `DEVKIT_HOME_DIR` — its
symlinks fail the check and are not reaped (`:573-581`). The generation guard then sees `[ -L "$dest" ]` as true, skips
writing (`:590-593`), and reports the name under "kept your own `~/.claude/commands` file(s)" (`:644-646`).

Result: a broken command persists indefinitely and the installer blames the user for it. Same hole guards
`~/.claude/output-styles` (`:529-533`). `~/.claude/skills` is immune — it deletes all `devkit-core--*` symlinks
unconditionally at `:110-114`.

Fix: treat an unresolvable symlink whose raw target matches `*/agentic-devkit/plugins/core/{commands,output-styles}/*`
as devkit-owned, or reap any dangling symlink in these managed dirs and report it as repaired.

The rest of the guarantee holds as documented: sentinel-bearing files are reaped before regeneration, authored files in
`plugins/core/commands/` correctly suppress generation for the same name, and `SHORT_COMMAND_DENY` (`:571`) contains
exactly the thirteen names `CLAUDE.md:72-75` lists.

Related: [[untested-no-clobber-guard]].

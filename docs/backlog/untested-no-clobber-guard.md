---
worth: yes
where: tests/codex-adapter.sh:42
added: 2026-09-02
---
# The guard protecting a developer's own `~/.claude` files from deletion is never exercised

`bin/devkit-install` unconditionally `rm -f`s entries in the real `~/.claude/output-styles` (`:529-533`) and
`~/.claude/commands` (`:573-581`). The only thing between a regression and deleting hand-authored slash commands is
`links_into_devkit()` plus the `COMMAND_SENTINEL` grep.

The test fixture creates only `$claude_home` itself, `CLAUDE.md` and `settings.json` — it seeds nothing into either
directory, so both reap loops run against empty dirs and every assertion about them
(`tests/codex-adapter.sh:113-115`) concerns devkit-owned files. A regression making `links_into_devkit` return true for
a user file, or dropping the sentinel check, would delete real user content with the suite green.
`bin/devkit-install:645` even advertises a "kept your own file(s)" notice path that no test reaches.

Fix: seed a plain `output-styles/mystyle.md`, a plain `commands/mycmd.md`, and a symlink pointing outside `$ROOT`; assert
all three survive byte-identical, assert the NOTICE lines appear, and assert a sentinel-bearing file in `commands/` *was*
removed and regenerated.

Related: [[dangling-devkit-symlink-reported-as-user-file]]. A runner now exists (`tests/run-all.sh`, added 2026-09-03) —
this item is about a coverage gap inside one of the six scripts it runs, not about the missing runner.

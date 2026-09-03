---
worth: yes
where: bin/devkit-install:614
added: 2026-09-03
---
# `bin/devkit-install` crashes on any fresh install because of a Cyrillic skill description

Discovered while adding `tests/run-all.sh` and running the suite for the first time: `tests/codex-adapter.sh` failed
with

```
awk: towc: multibyte conversion failure on: '�'
 input record number 6, file …/plugins/core/skills/nontech//SKILL.md
 source line number 12
```

Root cause: the short-slash-command generator (`bin/devkit-install:614-629`) reads every core skill's `description:`
frontmatter through a plain POSIX `awk` script with no locale/encoding handling. `plugins/core/skills/nontech/SKILL.md`'s
description contains Cyrillic text (`для менеджера`, `для нетехнических сотрудников`, …), and macOS's system `awk`
(`/usr/bin/awk`, one-true-awk 20200816) cannot multibyte-decode it and dies. `bin/devkit-install:27` sets
`set -euo pipefail`, so this is not a warning — it aborts the entire install script.

Reproduced against a completely fresh `$HOME` (no prior devkit state):

```
$ HOME=<fresh-dir> bash bin/devkit-install
    Style:   ~/.claude/settings.json (default outputStyle → Senior)
awk: towc: multibyte conversion failure on: '�'
 input record number 6, file …/plugins/core/skills/nontech//SKILL.md
 source line number 12
```

The script dies before writing `~/.claude/commands/*.md`, before the final "Done" summary, and before anything after
that point in the file — a real user on a fresh Mac gets a half-finished install with no clear error message pointing at
the cause.

This machine's install has been silently protected from the crash by an accident of history: `~/.claude/commands/nontech.md`
already exists from a previous install, so the `[ -e "$dest" ] || [ -L "$dest" ]` short-circuit at `bin/devkit-install:609`
routes it into `foreign_names` before the awk call is ever reached. Any other core skill whose description gains
non-ASCII content, or any environment without a pre-existing `nontech.md`, hits the crash.

Not caught by the earlier portability sweep in this review round — that check grepped for GNU/BSD flag differences
(`sed -i`, `readlink -f`, etc.), not encoding-sensitive `awk` usage. `emit_subagent`'s awk
(`adapters/_lib/claude_agents.sh:44`) has the same shape (an unguarded `awk` reading arbitrary SKILL.md body text) but
is not affected today only because no `claudeSubagent: true` skill currently has multibyte content — it carries the
same latent risk.

Fix options, in order of robustness:
- Switch the description-extraction awk to `gawk` if available (GNU awk handles UTF-8 correctly by default), falling
  back to the current POSIX awk only when `gawk` is absent.
- Or set `LC_ALL=en_US.UTF-8` / `LC_ALL=C.UTF-8` explicitly before invoking `awk`, if that resolves BSD awk's `towc`
  behavior on this input (verify — BSD awk's multibyte support is locale-dependent and inconsistent across macOS
  versions).
- Or replace the awk-based YAML frontmatter parsing with `python3` (already a hard dependency elsewhere in this script,
  e.g. the Codex `config.toml` writer) for guaranteed UTF-8 handling.

Verify the fix against `plugins/core/skills/nontech/SKILL.md` specifically, plus a fresh-`$HOME` full install run.

---
worth: yes
where: adapters/cursor/generate:190
added: 2026-09-02
---
# Cursor adapter hardcodes `$HOME/.claude/agentic-devkit` instead of the active clone

`adapters/_lib/resolve.sh:22-26` establishes `DEVKIT_HOME_REF` / `toolkit_home_ref()` precisely so a relocated clone
still generates correct output, and `bin/devkit-install:31` honours `DEVKIT_HOME_DIR`. The Cursor adapter ignores both
for the auto-update hook (`:190`) and the two edit gates (`:202`), writing a literal `${HOME}/.claude/agentic-devkit`.

Reproduced: running the adapter from `/Users/blaryx/www/agentic-devkit` produced `.cursor/hooks/hooks.json` pointing at
`/Users/blaryx/.claude/agentic-devkit/bin/devkit-update` — a different checkout. Where the clone lives elsewhere, all
three hook commands are dead.

Fix: build all three from `$(toolkit_abspath)` (or `toolkit_home_ref` if the string must stay portable), matching
`bin/devkit-install:271-273`.

---
worth: yes
where: adapters/claude/generate:91
added: 2026-09-02
---
# The resolution core, the Claude adapter, and three CLI entry points have no test coverage at all

Coverage map for the ~3250 lines of executable code:

| Production file | Covering test |
|---|---|
| `bin/devkit-install` (664) | partial — `tests/codex-adapter.sh:74-153`; `commands/` and `agents/` generation execute unasserted |
| `bin/devkit-resolve` (227) | none |
| `bin/devkit-update` (110) | none |
| `bin/devkit-cleanup-visual-loop.mjs` (89) | none |
| `update.sh` (61) | none |
| `adapters/_lib/resolve.sh` (200) | happy path only, indirectly |
| `adapters/_lib/hooks.sh` (136) | executes unasserted |
| `adapters/_lib/claude_agents.sh` (125) | executes unasserted |
| `adapters/_lib/mcp.sh` (56) | executes unasserted |
| `adapters/claude/generate` (174) | **never invoked by any test** |
| `adapters/cursor/generate` (243) | skills + `.mdc` only; `mcp.json` and `hooks.json` unasserted |
| `adapters/codex/generate` (194) | good |
| `plugins/core/hooks/comment-gate.sh` (153) | good |
| `plugins/core/hooks/coder-gate.sh` (129) | partial |
| `plugins/core/hooks/skill-eval.sh` (43) | one branch (empty `session_id`) |

Highest-value gaps, in order:

- `adapters/claude/generate` — the frontmatter-name collision guard (`:91-104`), the `.mcp.json` upsert that preserves
  user servers (`:136-148`), and an unconditional `rm -f` of legacy `.claude-plugin/` artifacts in the user's project
  (`:51-55`).
- `adapters/_lib/resolve.sh` — the version guard (`:81-84`), the multi-root union with de-duplication (`:85-86`), the
  `Plugin not found` / `Dependency cycle` errors (`:114-117`), the `$layer_order` sort (`:138`), and
  `ensure_gitignore_entry`'s normalization awk (`:178-188`).
- `bin/devkit-update` — always `exit 0`, so a regression that stops every dev container updating fails silently.
- `bin/devkit-cleanup-visual-loop.mjs` — rewrites a consumer's `package.json` and `fs.unlink`s a file, no dry-run.
- Generated subagents and slash commands — `emit_subagent`'s hand-rolled YAML frontmatter awk
  (`adapters/_lib/claude_agents.sh:41-95`) has a recorded past bug in its own comment (`:14-16`) that a test would have
  caught; nothing asserts on `$claude_home/agents` or `$claude_home/commands`.
- `skill-eval.sh`'s debounce (`:30-43`) — the entire point of `a49dae5` — is unreached, because the one invocation
  passes empty stdin and returns at `:25-28`.
- `inject_cursor_edit_gates` (`adapters/_lib/hooks.sh:105-120`) runs three times inside the test; a regression
  duplicating gate entries on every install would go unnoticed.

Related: [[no-test-seams-on-high-blast-radius-scripts]]. A runner now exists (`tests/run-all.sh`, added 2026-09-03) —
this item is about what the six scripts don't assert, not about the missing runner.

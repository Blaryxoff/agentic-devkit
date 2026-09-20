# Project profile — agentic-devkit

## System and blast radius

- A model-agnostic plugin toolkit for AI agents: Markdown skill/conduct definitions, POSIX-sh hooks, bash+jq
  resolution and adapter scripts, JSON schemas. There is no application runtime, no server, no database, and no
  user-facing UI. Reviewing it against web-application conventions is a category error.
- It installs as **one global clone** at `~/.claude/agentic-devkit`. Skills and conduct are symlinked, not copied,
  so an edit on `master` reaches every project and every agent session on every machine that pulls — within a day
  through the auto-update hook, immediately for anyone already on the clone. There is no staging environment and no
  release gate between a commit and every consumer.
- `plugins/core/hooks/*.sh` run inside other people's sessions. `skill-eval.sh` is installed only as Claude
  Code's `UserPromptSubmit` hook — Codex and Cursor get the instruction text in `skill-eval.txt` instead — while
  `coder-gate.sh` and `comment-gate.sh` run as `PreToolUse` gates on edits in all three harnesses. A hook that
  blocks, exits non-zero when it should not, or emits malformed output degrades or halts unrelated work in every
  repository at once.
- The adapters and `bin/devkit-install` write into user-owned configuration: `~/.claude/settings.json`,
  `~/.codex/config.toml`, `~/.cursor/hooks/hooks.json`, project `.gitignore`, `.claude/`, `.cursor/`, `.codex/`.
  Those files hold state devkit did not create and cannot reconstruct.
- Skill and command metadata is injected into **every** request under a hard platform cap. The budget enforced by
  `tests/context-efficiency.sh` is a real ceiling, not a style preference: overrunning it silently truncates the
  catalog, and skills stop being selectable with no error anywhere.

## What a real failure looks like here

- A generated write truncates, empties, or replaces a user-owned file — a failed producer emptying
  `settings.json`, `mv` replacing a symlink a dotfile repo depends on, a mode dropped, an unrelated key lost in a
  merge, or a malformed existing file reset to `{}` instead of aborting. The bash installer and adapters route
  every JSON write through `write_json` in `adapters/_lib/resolve.sh` for exactly this reason, and a new raw
  redirect there is a defect. The invariant is not repo-wide: `bin/devkit-cleanup-visual-loop.mjs` rewrites a
  project's `package.json` with a plain `fs.writeFile`, which is a real gap rather than a convention to respect.
- A hook hangs or misfires: blocking on stdin, a coder-gate that blocks an edit it should exempt or exempts one it
  should gate, a debounce marker that never expires, or a fail-open path that now fails closed. These do not fail
  visibly — the session simply stops working.
- A skill's `description` breaks catalog selection: over the per-skill cap, missing its trigger clause, carrying a
  conduct path, or folded across a hyphenated token (`devkit- reviewer-deep`) so a sibling redirect resolves to
  nothing. Write long descriptions as `>-` and wrap on whitespace only.
- A skill's frontmatter `name` or directory slug is renamed. Hooks, `plugins/core/hooks/skill-eval.txt`, generated
  subagents, generated slash commands and conduct cross-references all key on it; a rename is a breaking migration,
  never a cleanup.
- Resolution silently drops or mis-orders plugins: a missing transitive dependency, a configless extra
  `--project` root skipped without a word, `exit 1` inside a sourced helper killing the caller, or a path
  interpolated into a Python or jq literal.
- A bash 3.2 incompatibility. macOS ships 3.2 and it is a supported target: no associative arrays, no `read -d` in
  `/bin/sh` under dash, and `local a="$1" b="$TMP/$a"` is unsafe under `set -u`. `set -o pipefail` with `grep -q`
  kills the producer with SIGPIPE on a **matching** line. `timeout` does not exist on stock macOS.
- A script prompts with no terminal attached. An agent harness detaches a blocked call rather than killing it, so
  the shell outlives the session holding whatever it took — see `plugins/core/conduct/shell-invocation.md`.
- A conduct document is added but not routed from its plugin `overview.md`, so nothing can discover it.

## Deliberate project conventions

- Conduct is the canonical rulebook; a skill is a workflow that cites it. Duplicated rules in both places are the
  defect, not the missing copy. Conduct is loaded progressively per `plugins/core/conduct/conduct-loading.md` —
  never wholesale.
- Core subagent skills are registered **twice**, as `~/.claude/skills/devkit-core--<name>` and as
  `~/.claude/agents/<name>.md`. This is deliberate and documented in `CLAUDE.md`; the two entry points are an
  isolated tool-restricted run and an inline run with the caller's turns. Do not file it as duplication.
- The nine `css-*` skills are vendored wholesale from css.dev and keep their unprefixed upstream names, and
  `wrapup` drops the `devkit-` prefix so Codex reaches it as `$wrapup`. Both are named exceptions, not drift.
- `SHORT_COMMAND_DENY` in `bin/devkit-install` keeps generic names long-form on purpose: they collide with harness
  built-ins or are token-gated. `ralphex` is a trigger token in prompt text, never a name prefix.
- Hooks are authored once in Claude Code event format and translated per adapter. Duplicating a hook definition
  per tool is the anti-pattern the shared `_lib/hooks.sh` exists to prevent.
- Prose comments in shell and script code are forbidden by `plugins/core/conduct/code-comments.md`. A comment that
  states a non-obvious constraint is allowed; narration of what the next line does is not.
- Tests are shell scripts under `tests/`, run by `tests/run-all.sh`. A new regression test is expected to be
  mutation-verified — patch the line it guards, assert the test fails — but that is not established for the whole
  suite, so a vacuous assertion anywhere in `tests/` is a live finding, not settled ground.

## Reporting bar

- Report a defect with the concrete path through it: which harness, which command, which existing user file,
  which plugin set, which shell. "This could be fragile" is not a finding; "`--enable=` with an empty value falls
  through to `read -rp` and blocks forever with no terminal" is.
- Treat as gating: any write that can destroy user-owned configuration, any hook that can hang or wrongly block
  edits, any catalog-budget or description-contract breach, a skill rename without its migration, and resolution
  that silently produces the wrong plugin set.
- `howto/` is mostly Russian and written for humans; `plugins/css/` is vendored upstream and refreshed by hand.
  Neither follows this repository's writing rules, and neither is in scope unless the change touches it directly.
- Out of scope: wording and tone preferences in Markdown, hypothetical portability to shells the project does not
  target, `.devkit/`, `.revmux/tasks/`, and test scratch directories.
- The languages under review are bash 3.2, POSIX sh, jq, JSON Schema and Markdown, with small amounts of python3
  and node. Conventions from the frameworks this toolkit *describes* — Laravel, Vue, Nuxt, Tailwind — are content,
  not the bar for the code that ships them.

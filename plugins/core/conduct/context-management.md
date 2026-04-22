# Context Management

Adapted from the strategic compaction pattern. Applies to all AI-assisted coding sessions.

## Compact at logical breakpoints

Trigger a context compaction (`/compact`, `/clear`, or equivalent) at natural transition points rather than waiting for automatic compaction at high context usage.

Good breakpoints:

- After research/exploration, before implementation begins.
- After completing a milestone, before starting the next task.
- After debugging, before continuing feature work.
- After a failed approach, before trying a different one.
- After a long planning discussion, before writing code.

Bad breakpoints:

- Mid-implementation — variable names, file paths, partial state, and decision rationale are lost.
- During a multi-step refactor with uncommitted intermediate changes.
- While iterating on a failing test — the error context is still needed.

## Minimize context consumption

- Do not load entire large files when only a section is needed — use line ranges or search.
- Prefer targeted reads (specific functions, specific line ranges) over full-file reads.
- When multiple files are needed, read only the relevant sections of each.
- Close or stop referencing files that are no longer relevant to the current task.

## MCP and tool discipline

- Each enabled MCP tool description consumes context tokens even if never invoked.
- Disable unused MCP servers per project rather than running all servers globally.
- Keep active tool count reasonable — prefer fewer, well-chosen tools over a large surface.

## Session boundaries

- Treat unrelated tasks as separate sessions — clear context between them.
- When a session becomes long and unfocused, summarize progress and start fresh.
- Before compacting, ensure any critical decisions or findings are recorded outside the session (commit messages, plan files, comments).

## CLI loop session state

When running an **iterated CLI workflow** (see `plugins/core/skills/cli-loop/SKILL.md`), restate a compact **State** block in full before any `/compact` or context trim, and when resuming after a long break. Include:

- **Task** — one-liner and acceptance criteria.
- **Env fingerprint** — OS, shell, and key tool versions as **observed** in the session (not assumed).
- **Secrets metadata** — names of env vars and paths of temp files that hold secrets; **not** the secret values. Note pending cleanup (`unset`, `rm`, `trap`).
- **Identifiers** — hostnames, cluster/role IDs, generated resource names, and where a generated password was **stored** (never the password itself in chat).
- **Progress** — last completed step, next step goal.

Losing this block after compaction without restating it risks wrong commands, repeated probes, or leaked secret handling. Prefer logical breakpoints (after a batch completes, before a new trust boundary) over mid-batch compaction.

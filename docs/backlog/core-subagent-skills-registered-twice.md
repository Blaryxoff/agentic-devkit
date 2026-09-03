---
worth: later
where: bin/devkit-install:131
added: 2026-09-02
---
# Core `claudeSubagent` skills are registered as both a global skill and a subagent

`adapters/claude/generate:89-90` states isolation skills "must NOT also be registered as skills" and filters them out of
`.claude/skills`. `bin/devkit-install` applies no such filter to core skills: it symlinks every core skill into
`~/.claude/skills/devkit-core--*` (`:131-141`) and separately emits the `claudeSubagent: true` ones into
`~/.claude/agents/` (`:199-203`). On this machine `babysit`, `plan-reviewer`, `reviewer-logging`, `test-case-creator`
and `verify` each exist as both.

The short-command generator compounds it: `/reviewer-logging` and `/test-case-creator` are generated (neither is in
`SHORT_COMMAND_DENY`) and route to `Skill(devkit-core--<n>)` — the inline path, bypassing the isolation the subagent
exists to provide.

`worth: later` because the value decision is unresolved: dual registration may be deliberate for core, giving the user
both an inline and an isolated entry point. Settle that first. If deliberate, document it at `adapters/claude/generate:89`
and in `CLAUDE.md`; if not, apply the same `claudeSubagent` filter to the link loop and the short-command loop.

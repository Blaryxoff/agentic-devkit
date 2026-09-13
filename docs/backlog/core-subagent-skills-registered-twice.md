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

2026-09-13, cross-checked with Codex: **`plan-reviewer` cannot become subagent-only.** Its two registrations are not
duplicates of one capability. `claudeSubagentTools: Read, Glob, Grep, Bash, WebFetch` (`plan-reviewer/SKILL.md:10`)
gives the subagent no write tool, and the workflow requires user turns a subagent cannot take — "If type cannot be
determined, ask the user" (`:44`), Step 6 "Clarify ambiguities interactively" (`:195`), and "Do not write to the file
until the user confirms" (`:346`). The subagent delivers findings; only the skill can run the review-and-apply loop.
Any resolution of this item must keep the skill registration for `plan-reviewer`, or first give the subagent a write
tool and a parent relay protocol for its questions.

`test-case-creator` has neither constraint and could be made subagent-only for 304 chars, but that deletes
`/test-case-creator` (`~/.claude/commands/test-case-creator.md` routes through `Skill(devkit-core--test-case-creator)`)
with no replacement entry point. Not worth it at the current budget.

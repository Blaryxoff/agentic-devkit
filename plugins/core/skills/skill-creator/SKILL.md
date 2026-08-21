---
name: devkit-skill-creator
description: create or improve agentic-devkit skills so they stay small, specific, discoverable, and useful. Use when adding a new devkit skill, porting external Claude/Codex skills, reviewing existing skills for bloat, or deciding whether an idea belongs in a skill, conduct doc, script, or should be rejected.
---

# Skill Creator

Use this skill to create or refactor **agentic-devkit** skills. The goal is not to collect instructions like a digital hoarder. The goal is to make Claude/Codex reliably do a specific kind of work with less prompt steering.

## What belongs in a skill

A skill is justified when it provides at least one of:

- a repeatable workflow the agent gets wrong or forgets;
- domain/project conventions not obvious from code;
- exact commands/tools with pitfalls;
- bundled scripts for deterministic work;
- a decision tree that prevents expensive mistakes.

Do **not** create a skill for:

- one-off task notes;
- raw copied documentation;
- vague “best practices”;
- long reference dumps better kept in `conduct/` or `references/`;
- tools that require background daemons/containers unless the user explicitly accepts that tradeoff.

## Devkit layout

Skills live under a plugin:

```text
plugins/<plugin>/skills/<skill-name>/SKILL.md
plugins/<plugin>/skills/<skill-name>/references/   # optional detailed docs
plugins/<plugin>/skills/<skill-name>/scripts/      # optional deterministic helpers
plugins/<plugin>/skills/<skill-name>/assets/       # optional output assets/templates
```

Core, cross-project skills belong in `plugins/core/skills/`. Stack-specific skills belong in their plugin (`laravel`, `vue`, `nuxt`, etc.). If the skill only expresses team-wide conduct, prefer `plugins/<plugin>/conduct/*.md` and cite it from a skill.

## Frontmatter

Minimum:

```yaml
---
name: devkit-short-name
description: clear trigger and behavior in one paragraph
---
```

Optional Claude subagent fields for isolated heavy work:

```yaml
claudeSubagent: true
claudeSubagentTools: Read, Glob, Grep, Bash, WebFetch
```

Descriptions are routing metadata. They must say **when to use** the skill, not just what it is called.

Codex uses a strict YAML frontmatter parser. If `description` contains `:` followed by a space (e.g. `Routing policy:`, `misaligned:`), use a folded block scalar — not a bare inline string:

```yaml
description: >-
  …text with Routing policy: plugins/core/conduct/foo.md.
```

Bad:

```yaml
description: helps with testing
```

Good:

```yaml
description: run an immediate browser QA pass on a scoped feature or route set using chrome-devtools MCP, append-only seed data, role/viewport/entity lifecycle coverage, and inline findings. Does not fix code.
```

## Progressive disclosure

Keep `SKILL.md` lean:

- put the core workflow and hard rules in `SKILL.md`;
- put long examples, APIs, schema notes, and project-specific quirks in `references/`;
- put deterministic repeated code in `scripts/`;
- cite shared rules from `plugins/*/conduct/*.md` instead of duplicating them.

Target size: enough to guide the agent, not enough to sedate it. If `SKILL.md` grows past ~200–300 lines, split it.

## Creation workflow

1. **Define the trigger.** Write the exact user intents that should load the skill.
2. **Check for duplicates.** Search existing `plugins/*/skills/*/SKILL.md` and `conduct/` first.
3. **Choose placement.** Core vs stack plugin. Prefer existing plugins.
4. **Write the smallest useful workflow.** Include commands, prerequisites, verification, and hard stops.
5. **Add references/scripts only when needed.** Do not vendor random docs unless they are actually used.
6. **Validate locally.** Frontmatter parses, files exist, links resolve.
7. **Regenerate adapters** in target projects if new global/core skills should appear for Claude/Codex.
8. **Test routing.** Ask the agent a realistic prompt and verify the skill is visible/selected or explicitly invokable.

## Refactor workflow for existing skills

When improving an existing skill:

1. Read the current skill fully.
2. Identify its actual job in one sentence.
3. Remove stale, duplicate, or generic advice.
4. Move long references out of `SKILL.md`.
5. Make hard rules concrete and testable.
6. Add missing prerequisites and verification steps.
7. Preserve useful project-specific conventions.
8. Avoid changing semantics just to make prose prettier. Pretty wrong instructions are still wrong, just with perfume.

## Quality checklist

A good devkit skill:

- has a specific trigger;
- names when **not** to use it;
- is on-demand and compatible with the user's current tooling;
- includes exact commands or tool names where relevant;
- has verification steps;
- states destructive actions that need approval;
- avoids raw documentation dumps;
- references shared conduct instead of duplicating it;
- can be understood in a fresh session.

## Porting external skills

> Portability guidance informed by `umputun/revmux` (MIT): Claude Code and Codex can need different instructions for
> native tools, but devkit defaults to one shared Agent Skills leaf (`SKILL.md` plus referenced resources).

When importing from external skill repositories:

1. Treat external content as inspiration, not gospel. Record its license and preserve attribution when material text or
   workflow design survives.
2. Read the source `SKILL.md` and only its referenced resources. Separate the portable workflow from discovery paths,
   plugin manifests, hooks, permissions, install commands, and other host-shell concerns.
3. Keep one canonical devkit skill directory and one shared `SKILL.md` by default. Do not add adapter or installer
   machinery for hypothetical portability differences.
4. Express small harness differences inside the shared body. Use a compact Claude/Codex table when ordering, commands,
   or native primitives differ; name the concrete tools when that makes the instruction more reliable.
5. Describe the common capability when the distinction does not affect execution, such as "use the available structured
   question tool" or "use the available subagent mechanism."
6. Consider separate harness bodies only after a real skill repeatedly fails in one harness and a short inline branch
   cannot express the difference clearly. Treat that as an explicit architecture change, not routine skill porting.
7. Keep discovery, plugin manifests, hooks, permissions, and other unavoidable host behavior in the owning adapter.
8. Resolve bundled resources relative to the loaded skill directory or `DEVKIT_HOME`. Do not introduce
   `${CLAUDE_PLUGIN_ROOT}` into a cross-host skill; Codex has no equivalent.
9. Reject anything requiring hidden SaaS, daemon, container, proprietary runtime, or a new dependency unless explicitly
   approved.
10. Rename and rewrite for devkit conventions (`devkit-*` names where appropriate). Remove unsupported source metadata
   instead of inventing an equivalent.
11. Validate the shared skill in both Claude Code and Codex with a realistic prompt. Confirm both catalogs discover it
    and each harness follows the intended native path.

## Output format for skill reviews

```markdown
## Skill review: <name>

Verdict: keep / revise / split / delete / reject
Reason: <short>
Changes needed:
- ...
Verification:
- ...
```

## Hard rules

- Do not create a skill if a two-line note in the current task would do.
- Do not hide project-specific secrets or credentials inside skills.
- Do not add background services as “skills”. Skills describe workflows; they are not an excuse to build a zoo.
- Do not build harness-specific adapter machinery for an unobserved skill problem. Prefer one shared body with a compact
  harness branch when necessary.
- Do not rewrite all skills mechanically. Improve only what has a clear quality problem.

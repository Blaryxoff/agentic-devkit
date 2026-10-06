---
name: devkit-skill-creator
description: >-
  create or improve agentic-devkit skills so they stay small, specific, discoverable, and useful. Use when
  adding a new devkit skill, porting external Claude/Codex/Cursor skills, reviewing existing skills for bloat, or
  deciding whether an idea belongs in a skill, conduct doc, script, or should be rejected.
---

# Skill Creator

Use this skill to create or refactor **agentic-devkit** skills.

## What belongs in a skill

A skill is justified when it provides at least one of:

- a repeatable workflow the agent gets wrong or forgets;
- domain/project conventions not obvious from code;
- exact commands/tools with pitfalls;
- bundled scripts for deterministic work;
- a decision tree that prevents expensive mistakes.

Keep the following outside skills:

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

Optional subagent fields for isolated heavy work (emitted by the Claude and Cursor adapters):

```yaml
claudeSubagent: true
claudeSubagentTools: Read, Glob, Grep, Bash, WebFetch
```

A tool list without write tools makes the Cursor subagent `readonly: true`, which also blocks state-changing shell
commands. Add `cursorReadonly: false` when the workflow runs lint, tests or builds through Bash.

Descriptions are routing metadata. They must say **when to use** the skill, not just what it is called.
Cursor also requires `name:` to match the installed skill folder; its adapter links each skill under that name.

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
5. **Add references/scripts only when needed.** Bundle only documentation the workflow actually consumes.
6. **Validate locally.** Frontmatter parses, files exist, links resolve.
7. **Regenerate adapters** in target projects when project-scoped skills or subagents change; rerun `devkit-install` for new global/core skills in Claude, Codex, or Cursor.
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
8. Preserve triggers, obligations, exceptions and safety boundaries when improving wording. Lead workflow rules with a concrete action; retain explicit prohibitions where a safety boundary needs them.

## Quality checklist

A good devkit skill:

- has a specific trigger;
- gives concrete routing for out-of-scope requests;
- is on-demand and compatible with the user's current tooling;
- includes exact commands or tool names where relevant;
- has verification steps;
- states destructive actions that need approval;
- avoids raw documentation dumps;
- references shared conduct instead of duplicating it;
- can be understood in a fresh session.

## Porting external skills

> Portability guidance informed by `umputun/revmux` (MIT): Claude Code, Codex, and Cursor can need different instructions for
> native tools, but devkit defaults to one shared Agent Skills leaf (`SKILL.md` plus referenced resources).

When importing from external skill repositories:

1. Treat external content as inspiration, not gospel. Record its license and preserve attribution when material text or
   workflow design survives.
2. Read the source `SKILL.md` and only its referenced resources. Separate the portable workflow from discovery paths,
   plugin manifests, hooks, permissions, install commands, and other host-shell concerns.
3. Keep one canonical devkit skill directory and one shared `SKILL.md` by default. Add adapter or installer machinery
   only for an observed portability requirement.
4. Express small harness differences inside the shared body. Use a compact harness table when ordering, commands,
   or native primitives differ; name the concrete tools when that makes the instruction more reliable.
5. Describe the common capability when the distinction does not affect execution, such as "use the available structured
   question tool" or "use the available subagent mechanism."
6. Consider separate harness bodies only after a real skill repeatedly fails in one harness and a short inline branch
   cannot express the difference clearly. Treat that as an explicit architecture change, not routine skill porting.
7. Keep discovery, plugin manifests, hooks, permissions, and other unavoidable host behavior in the owning adapter.
8. Resolve bundled resources relative to the loaded skill directory or `DEVKIT_HOME`, which works across hosts.
   Keep `${CLAUDE_PLUGIN_ROOT}` limited to Claude-specific adapter behavior; Codex and Cursor do not use it.
9. Reject anything requiring hidden SaaS, daemon, container, proprietary runtime, or a new dependency unless explicitly
   approved.
10. Rename and rewrite for devkit conventions (`devkit-*` names where appropriate). Remove unsupported source metadata
   instead of inventing an equivalent.
11. Validate the shared skill in each target harness with a realistic prompt. Confirm its catalogs discover it
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

- Use a task note when two lines in the current task resolve the need; create a skill for a reusable workflow.
- Do not hide project-specific secrets or credentials inside skills.
- Describe executable workflows in skills. Treat any proposed background service as a separate dependency requiring explicit approval.
- Use one shared skill body with a compact harness branch. Add harness-specific adapter machinery only for an observed
  skill problem that the shared body cannot express.
- Make each wording change resolve a specific clarity problem and preserve the rule’s behavior.

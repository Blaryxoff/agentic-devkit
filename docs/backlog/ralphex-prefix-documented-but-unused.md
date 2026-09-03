---
worth: yes
where: CLAUDE.md:56
added: 2026-09-02
---
# The `ralphex-` skill-name prefix is documented as live but has no instance

`CLAUDE.md:56` presents `ralphex-` as a live naming convention alongside `devkit-`. No SKILL.md uses it. Three places
propagate the error:

- `MIGRATION.md:68` asserts the plan skills were renamed to `ralphex-plan-creator` / `ralphex-plan-reviewer`. Their
  actual frontmatter is `devkit-plan-creator` / `devkit-plan-reviewer`, and `plugins/core/hooks/skill-eval.txt:9` gates
  on the `devkit-` names.
- `plugins/core/skills/plan-reviewer/SKILL.md:49` cites the nonexistent "`ralphex-plan-creator` skill".
- `CLAUDE.md:56` itself.

Note the distinction being blurred: `ralphex` is a *trigger token* in the prompt (`skill-eval.txt:9`), not a skill-name
prefix. Fix: drop "or `ralphex-`" from `CLAUDE.md:56`, correct `MIGRATION.md:68`, and change
`plan-reviewer/SKILL.md:49` to `devkit-plan-creator`.

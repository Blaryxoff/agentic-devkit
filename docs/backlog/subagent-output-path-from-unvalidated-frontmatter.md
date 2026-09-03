---
worth: yes
where: adapters/_lib/claude_agents.sh:82
added: 2026-09-02
---
# Subagent output path is built from unvalidated SKILL.md frontmatter

`out = out_dir "/" name ".md"` where `name` is whatever follows `name:` in the frontmatter, trimmed of whitespace only.
A frontmatter `name: ../../evil` writes outside `$agents_dir` — for the global install that directory is
`~/.claude/agents`. Input is repo-controlled today, but this runs against every plugin skill in whatever clone
`devkit-install` resolves, including a bootstrapped one (`bin/devkit-install:65`).

Fix: reject non-slug names in the awk `END` block — `if (name !~ /^[A-Za-z0-9_-]+$/) exit 0`.

`generate_subagents` gained a same-name collision guard on 2026-09-03 (`adapters/_lib/claude_agents.sh`) — a different
defect from this one: that guard rejects a *repeated* name, it does not validate that a name is a safe path segment.
This item is still open.

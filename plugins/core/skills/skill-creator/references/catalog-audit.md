# Skill catalog audit

Save an explicitly authorized discovery snapshot somewhere private, then inspect only the helper's bounded JSON report:

```sh
grok inspect --json > <private-snapshot.json>
python3 "${DEVKIT_HOME}/plugins/core/skills/skill-creator/scripts/catalog.py" \
  --snapshot <private-snapshot.json>
```

The helper treats snapshot text as inert data. It does not invoke Grok or another CLI, inspect session history, or make
changes. Its inventory retains skill names, catalog descriptions, and source type/path; MCP servers retain names and
types; plugins retain names and enabled state. Other snapshot fields, including MCP targets, commands, credentials,
environment values, and plugin configuration, are omitted.

Findings cover source paths under `.trash`, missing sources, empty catalog descriptions, malformed or mismatching
`SKILL.md` frontmatter, and one effective name resolving to distinct physical `SKILL.md` files. Symlinks and other
references resolving to the same physical file count once. The helper reads at most 16 KiB while locating and parsing
frontmatter; it does not read skill bodies into the report.

Use the report to locate relevant files, then compare the full, relevant `SKILL.md` files manually. The helper does not
infer semantic overlap or stale instructions from names. The report explicitly has no usage evidence: zero matches or
an absent usage history does not establish disuse and is not a retirement recommendation. User-provided counts are
context for human review only and never authorize deletion or other changes.

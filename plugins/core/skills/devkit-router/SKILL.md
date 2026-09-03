---
name: devkit
description: dispatch to the project's stack-specific devkit skills and conduct (Laravel, Vue, Nuxt, Inertia, Tailwind, CSS, frontend architecture). Use when a request needs framework/stack conventions, backend or frontend architecture/design, or stack-specific implementation and the stack skills are not globally registered. Reads each accessible repo's .devkit/toolkit.json, resolves the enabled plugins from the global devkit clone, and loads the matching child skill + conduct on demand. Skip for pure git/plan/review/verify work — those core skills are globally registered and auto-match on their own.
---

# devkit (stack router)

Single entrypoint for **stack-specific** devkit capabilities. Stack skills are not globally registered (they would
wrongly offer themselves in unrelated projects), so this skill matches the request against them and loads the right one.

**When the router is needed (vs. native registration):** the Claude adapter already registers single-root stack skills
natively — isolation skills become subagents (`.claude/agents/`) and inline skills become per-project symlinks
(`.claude/skills/devkit-<plugin>--<skill>`). Prefer those native entries. Fall back to this router only when native
registration cannot cover the request: (a) a **multi-repo** project whose plugin set is the union of several
`.devkit/toolkit.json` roots, or (b) a skill **skipped due to a frontmatter-name collision** (two enabled plugins
declaring the same `name:` — only the first is linked or emitted, the rest route through here).

`DEVKIT_HOME` = the global clone, default `~/.claude/agentic-devkit`. All `plugins/...` paths below resolve under it. If
`$DEVKIT_HOME/bin/devkit-resolve` is missing, resolve this skill's own symlink (`~/.claude/skills/devkit-core--devkit-router`)
to find the clone root.

## Workflow

1. **Enumerate accessible repo roots.** Take the current working directory plus any additional directories you have access
   to (a logical project may span a backend repo and a frontend repo). Keep every root that contains `.devkit/toolkit.json`.
   If none exists, tell the user to create one (`$DEVKIT_HOME/bin/devkit-resolve --init`) and stop.

2. **Resolve the union of enabled plugins.** Run, with one `--project` per root:

   ```
   "$DEVKIT_HOME/bin/devkit-resolve" --dirs --project=<root1> --project=<root2> ...
   ```

   The output is the ordered, de-duplicated, dependency-resolved list of **absolute** plugin directories.

3. **Build the dispatch menu.** For each enabled **non-core** plugin dir that has a `skills/` subdir, read every
   `skills/*/SKILL.md` frontmatter (`name` + `description`). This is the candidate set — the stack equivalent of Claude's
   native skill menu.

4. **Match the request** against those descriptions. Pick the best-fitting child skill. If several fit, prefer the most
   specific; if none fit, fall back to handling the request directly with the active plugins' conduct.

5. **Load and apply the child.** Read the matched child skill's full `SKILL.md` body and follow it. Apply
   `plugins/core/conduct/conduct-loading.md`: load only conduct cited by the child or required by a concrete touched
   layer or risk; never scan a conduct directory wholesale. Skill and conduct content always come from `$DEVKIT_HOME`,
   never from the repos, so cross-plugin references resolve regardless of which repo triggered the request.

## Notes

- A child skill marked `claudeSubagent: true` is also generated as a real subagent per project (`.claude/agents/`) by the
  Claude adapter — prefer invoking that subagent when it exists; only inline-load when it does not.
- Do not re-resolve on every turn within one task; resolve once and reuse the menu.

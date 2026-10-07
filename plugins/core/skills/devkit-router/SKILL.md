---
name: devkit
description: >-
  dispatch to the project's stack-specific devkit skills and conduct (Laravel, NestJS, Next.js, Vue, Nuxt,
  Inertia, Tailwind, CSS, frontend architecture). Use when a request needs framework/stack conventions or stack-specific
  architecture, design, or implementation and the stack skills are not globally registered. Skip pure
  git/plan/review/ verify work — those core skills auto-match on their own.
---

# devkit (stack router)

Single entrypoint for **stack-specific** devkit capabilities. Stack skills are not globally registered (they would
wrongly offer themselves in unrelated projects), so this skill matches the request against them and loads the right one.

**When the router is needed (vs. native registration):** the Claude and Cursor adapters register single-root stack skills
natively — isolation skills become subagents (`.claude/agents/` or `.cursor/agents/`) and skills become per-project symlinks
(`.claude/skills/devkit-<plugin>--<skill>` or `.cursor/skills/<frontmatter-name>`). Prefer those native entries. Fall back to this router only when native
registration cannot cover the request: (a) a **multi-repo** project whose plugin set is the union of several
`.devkit/toolkit.json` roots, or (b) a skill **skipped due to a frontmatter-name collision** (two enabled plugins
declaring the same `name:` — only the first is linked or emitted, the rest route through here).

`DEVKIT_HOME` = the global clone, default `~/.claude/agentic-devkit`. All `plugins/...` paths below resolve under it. If
`$DEVKIT_HOME/bin/devkit-resolve` is missing, resolve this skill's own symlink under the active harness's global skills
directory (`~/.claude/skills/`, `~/.cursor/skills/`, or `~/.codex/skills/`) to find the clone root.

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
   `skills/*/SKILL.md` frontmatter (`name` + `description`). This is the candidate set — the stack equivalent of native
   native skill menu.

4. **Match the request** against those descriptions. Pick the best-fitting child skill. If several fit, prefer the most
   specific; if none fit, fall back to handling the request directly with the active plugins' conduct.

5. **Load and apply the child.** Read the matched child skill's full `SKILL.md` body and follow it. Apply
   `plugins/core/conduct/conduct-loading.md`: load only conduct cited by the child or required by a concrete touched
   layer or risk; open only conduct files cited by the child or required by that concrete layer or risk. Load skill and conduct content from `$DEVKIT_HOME` so cross-plugin
   references resolve regardless of which repo triggered the request.

## Notes

- A child skill marked `claudeSubagent: true` is generated as a real subagent per project by the Claude and Cursor
  adapters (`.claude/agents/` or `.cursor/agents/`). Prefer invoking that subagent when it exists; only inline-load
  when it does not.
- Resolve the plugin menu once per task and reuse it on later turns.

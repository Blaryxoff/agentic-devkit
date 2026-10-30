---
name: devkit
description: >-
  dispatch to the project's stack-specific devkit skills and conduct (Laravel, NestJS, Express, Drizzle, React,
  Next.js, React Native/Expo, Electron, Vue, Nuxt, Inertia, Tailwind, CSS). Use for stack architecture, design,
  or implementation when stack skills are not registered. Skip pure git, plan, review, or verify work; core skills handle it.
---

# devkit (stack router)

Single entrypoint for **stack-specific** devkit capabilities. Stack skills are not globally registered (they would
wrongly offer themselves in unrelated projects), so this skill matches the request against them and loads the right one.

**When the router is needed (vs. native registration):** the Claude, Cursor, and Codex adapters register single-root stack skills
natively — isolation skills become subagents (`.claude/agents/` or `.cursor/agents/`) and skills become per-project symlinks
(`.claude/skills/devkit-<plugin>--<skill>`, `.cursor/skills/<frontmatter-name>`, or `.codex/skills/devkit-<plugin>--<skill>`). Prefer those native entries. Fall back to this router only when native
registration cannot cover the request: (a) a **multi-repo** project whose plugin set is the union of several
`.devkit/toolkit.json` roots, (b) a skill **skipped due to a frontmatter-name collision** (two enabled plugins
declaring the same `name:` — only the first is linked or emitted, the rest route through here), or (c) a project
without generated project-scoped skill links for the active stack.

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

3. **Build the dispatch menu.** For enabled **non-core** plugins, inspect skill frontmatter names and invocation flags,
   plus native invocation policy from `agents/openai.yaml` when present.
   Use only automatically invocable skills' descriptions for ordinary matching. Exclude `disable-model-invocation: true`
   skills (and Codex `policy.allow_implicit_invocation: false`) unless the user explicitly names that skill. For CSS,
   use `css-expert` as the automatic entry instead of reading all specialist descriptions. A selected entry skill may
   load its task-matched child body as an on-demand resource when its workflow instructs it to do so.

4. **Match the request** against those descriptions. Pick the best-fitting child skill. If several fit, prefer the most
   specific; if none fit, fall back to handling the request directly with the active plugins' conduct. Do not select
   CSS for backend or behavior-only frontend work. An explicit specialist request selects only that specialist;
   do not also load its general entry skill.

5. **Load and apply the child.** Read the matched child skill's full `SKILL.md` body and follow it. Apply
   `plugins/core/conduct/conduct-loading.md`: load only conduct cited by the child or required by a concrete touched
   layer or risk; open only conduct files cited by the child or required by that concrete layer or risk. Load skill and conduct content from `$DEVKIT_HOME` so cross-plugin
   references resolve regardless of which repo triggered the request.

## Notes

- A child skill marked `claudeSubagent: true` is generated as a real subagent per project by the Claude and Cursor
  adapters (`.claude/agents/` or `.cursor/agents/`). Prefer invoking that subagent when it exists; only inline-load
  when it does not.
- Resolve the plugin menu once per task and reuse it on later turns.

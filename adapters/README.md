# Adapters

Adapters translate the resolved plugin set into tool-specific configuration. Each adapter reads the same `.devkit/toolkit.json` project config and generates output appropriate for its target AI tool.

## Available Adapters

| Adapter | Target Tool | Output |
|---------|-------------|--------|
| `claude` | Claude Code | `.claude/agents/*.md` (stack subagents), `.claude/skills/devkit-*--*` symlinks (inline stack skills), `.claude/settings.json` (hooks only — plugin `permissions` are not merged), `.mcp.json` |
| `cursor` | Cursor IDE and CLI | `.cursor/skills/<frontmatter-name>/`, `.cursor/agents/*.md` (stack subagents), `.cursor/rules/devkit-*.mdc`, `.cursor/mcp.json`, `.cursor/hooks.json` |
| `codex` | OpenAI Codex | `.codex/skills/devkit-*--*/`, `AGENTS.md` section (conduct + hook instructions), `.codex/config.toml` MCP servers |
| `grok` | Grok Build | Claude-compatible project stack, `.grok/config.toml` MCP servers, native global payload gates and Grok activation guidance; see [Grok adapter](grok/README.md) |
| `agy` | Google Antigravity (AGY) | `.agents/skills/<frontmatter-name>/` symlinks (stack skills), `.agents/rules/devkit-*.md`, `.agents/mcp_config.json`, `.agents/hooks.json` |

The Claude adapter also removes `.claude-plugin/`, a marketplace manifest earlier versions generated.

Every adapter synchronizes the same project MCP catalogue into `.mcp.json`, `.cursor/mcp.json`,
`.codex/config.toml`, and `.grok/config.toml`. Project MCP generation requires Python 3.11+.
The canonical `.mcp.json` server definition wins conflicts; Cursor-only project entries are imported, and plugin
defaults fill missing server names. Whole server definitions win, so HTTP and stdio settings cannot mix accidentally.
Unrelated JSON keys, native TOML settings, native-only servers, and native authentication/tool policies are preserved.
Cursor HTTP headers stay client-local when importing servers; they are never copied into the canonical catalogue.
For matching URLs, Cursor keeps its private headers and supplies them to the ignored native Codex/Grok files.
Explicit canonical headers apply to every generated client, overriding matching local header names. Keep private
credentials in client-local configuration. Changing a shared URL drops the previous endpoint's local headers and
native HTTP authentication fields; tool policies remain intact.

The shared catalogue contains enabled servers. Native project entries get `enabled = true`, including when a global
entry with the same name is disabled. Grok's project `[compat.claude]` and `[compat.cursor]` set `mcps = false` so it
uses its native synchronized catalogue. Client-specific disabling belongs in that client's own controls; JSON
`disabled: true` entries are rejected rather than accidentally enabling them in another client.

Supported shared transports are stdio (`command`, `args`, `env`, `cwd`) and Streamable HTTP (`type: "http"`, `url`,
`headers`). Missing stdio `cwd` defaults to the project root. HTTP headers map to Codex `http_headers` and Grok
`headers`; existing native auth helpers and tool restrictions remain intact. Native-only servers stay native.
Legacy SSE and inline/dotted TOML definitions for tables being synchronized need explicit migration; generation
fails before changing MCP files when it cannot preserve them safely. Generated native files are ignored by git.
Add or edit shared entries in `.mcp.json`, then rerun any adapter. Standard plugin Chrome launchers get isolation
flags; custom Chrome launchers and browser arguments are preserved.
The Laravel Boost default is emitted only when `vendor/laravel/boost` is installed in that checkout.

Legacy local Nuxt SSE runtimes can use the stdio bridge
`node adapters/_lib/mcp-sse.mjs PROJECT_ROOT LOOPBACK_SSE_URL`. It resolves the MCP SDK from that project's
existing `nuxt-mcp-dev` dependency, accepts only loopback endpoints, and installs no packages. Configure this command
as a shared stdio server; the JSON catalogue still rejects direct SSE entries. To verify the bridge against a local
mock SSE server with an existing Nuxt installation, run
`DEVKIT_MCP_SSE_PROJECT=/path/to/nuxt-project bash tests/mcp-parity.sh`.

## Usage

Devkit is one global clone at `~/.claude/agentic-devkit`; the per-repo `toolkits/agentic-devkit` submodule layout is
gone (`MIGRATION.md`).

```bash
# From the project root
~/.claude/agentic-devkit/bin/devkit-resolve --adapter=claude
~/.claude/agentic-devkit/bin/devkit-resolve --adapter=cursor
~/.claude/agentic-devkit/bin/devkit-resolve --adapter=codex
~/.claude/agentic-devkit/bin/devkit-resolve --adapter=grok
~/.claude/agentic-devkit/bin/devkit-resolve --adapter=agy
```

`--project=DIR` overrides the project root and is repeatable, unioning the enabled plugins of several repos
(backend + frontend).

Cursor core skills and subagents are installed globally. Stack skills and subagents are project-scoped; after upgrading from an older global-skill
installation, rerun the Cursor adapter in each project to create its resolved frontmatter-named `.cursor/skills/` links.
Cursor prompt feedback uses the native `beforeSubmitPrompt` hook. As of Cursor CLI 2026.10, `cursor-agent -p`
does not emit that event, so headless print-mode prompts are not captured; interactive Cursor and the IDE use the hook.
See [Cursor's acknowledged print-mode issue](https://forum.cursor.com/t/cursor-cli-does-not-run-enterprise-or-team-beforesubmitprompt-hooks/173219).

## Adding a New Adapter

1. Create `adapters/<name>/generate` (executable shell script).
2. Source the shared libraries at the top:
   ```bash
   source "$ADAPTER_DIR/../_lib/resolve.sh"
   source "$ADAPTER_DIR/../_lib/hooks.sh"
   source "$ADAPTER_DIR/../_lib/mcp.sh"          # only if the target consumes MCP servers
   source "$ADAPTER_DIR/../_lib/claude_agents.sh" # only if the target has subagents
   ```
3. Call `resolve_plugins` to get the ordered list of resolved plugin names.
4. Call `resolve_plugin_dirs` if you need absolute directory paths.
5. Use `toolkit_relpath` to get the relative path from project root to toolkit root.
6. Use `_build_plugin_index` + `jq` to read individual plugin manifests.
7. Generate whatever files your target tool expects.

### Shared library exports (`_lib/resolve.sh`)

| Function | Returns |
|----------|---------|
| `resolve_plugins` | Newline-separated plugin names, layer-sorted |
| `resolve_plugin_dirs` | Newline-separated absolute plugin directory paths |
| `toolkit_relpath` | Relative path from `$PROJECT_ROOT` to `$TOOLKIT_ROOT` |
| `toolkit_abspath` | Absolute path of the clone being run — use this for any command written into generated config |
| `toolkit_home_ref` | Portable clone reference (`~/.claude/agentic-devkit`) — use this for text embedded in committed files |
| `validate_schemas` | Checks every project `toolkit.json` and every `plugins/*/plugin.json` against `schemas/` |
| `write_json` | Writes JSON to a destination through a temp file, so a failure cannot truncate it |
| `ensure_gitignore_entry` | Appends an entry to the project `.gitignore` unless an equivalent line is already there |
| `_project_roots` | Newline-separated project roots (`DEVKIT_PROJECT_ROOTS`, else `$PROJECT_ROOT`) |
| `_collect_enabled` | JSON array of enabled plugin names, unioned across roots and de-duplicated |
| `_build_plugin_index` | JSON object keyed by plugin name with full manifest + `_dir` |
| `_check_jq` | Returns non-zero with an error if `jq` is not installed |

### Shared library exports (`_lib/mcp.sh`)

| Function | Returns |
|----------|---------|
| `merge_plugin_mcp_servers` | Merged JSON of `mcpServers` declared by the resolved plugins |
| `apply_chrome_devtools_profile` | Normalizes standard npx Chrome launcher isolation flags, preserving custom launchers and arguments |
| `sync_project_mcp_servers` | Synchronizes plugin defaults and project servers into Claude, Cursor, Codex, and Grok project files |

### Shared library exports (`_lib/claude_agents.sh`)

| Function | Returns |
|----------|---------|
| `devkit_frontmatter` | The YAML frontmatter block of a `SKILL.md` |
| `devkit_is_subagent` | True when the skill declares `claudeSubagent: true` |
| `reap_devkit_agents` | Deletes previously generated devkit subagents, leaving user-authored ones |
| `emit_subagent` | Writes one subagent file from a `SKILL.md` |
| `generate_subagents` | Emits the full subagent set for a resolved plugin list |

### Shared library exports (`_lib/hooks.sh`)

| Function | Returns |
|----------|---------|
| `merge_plugin_hooks` | Merged JSON of all hooks from resolved plugins (Claude Code format) |
| `translate_hooks_to_cursor` | Hooks translated from Claude Code event names to Cursor event names |
| `inject_cursor_edit_gates` | Adds coder, comment and canonical dev-server gates to Cursor `preToolUse` hooks JSON |
| `dev_server_gate_command` | Shell command for the canonical dev-server guard, pinning an explicit/shared config's real path |
| `flatten_hooks_for_text` | Pipe-delimited lines (`event|matcher|command`) for text-based adapters |

### DRY hook adapter pattern

Plugins define hooks once in Claude Code format (the common denominator). Each adapter is responsible for translating event names to its target tool's format. This avoids duplicating hook definitions per tool.

Event name mapping:

| Claude Code | Cursor | Codex |
|-------------|--------|-------|
| `PreToolUse` | `preToolUse` | `[[hooks.PreToolUse]]` in `~/.codex/config.toml` |
| `PostToolUse` | `postToolUse` | instruction-based |
| `Stop` | `stop` | instruction-based |
| `UserPromptSubmit` | `beforeSubmitPrompt` | `[[hooks.UserPromptSubmit]]` in `~/.codex/config.toml` |
| `Notification` | _(no equivalent)_ | instruction-based |
| `SubagentStop` | _(no equivalent)_ | _(no equivalent)_ |

Codex supports native `PreToolUse` hooks: `bin/devkit-install` writes the coder, comment and canonical dev-server gates into
`~/.codex/config.toml` as part of the global install. Everything else the Codex adapter still embeds as instructions in
the project's `AGENTS.md`.

### Environment variables

| Variable | Default | Description |
|----------|---------|-------------|
| `DEVKIT_PROJECT_ROOT` | CWD | Override the project root directory (`--project=DIR` on the CLI, repeatable) |
| `DEVKIT_PROJECT_ROOTS` | _(unset)_ | `:`-separated project roots, unioned |
| `DEVKIT_HOME_DIR` | `~/.claude/agentic-devkit` | Where `bin/devkit-install` expects (or creates) the global clone |
| `DEVKIT_HOME_REF` | `~/.claude/agentic-devkit` | The clone reference embedded in generated text |

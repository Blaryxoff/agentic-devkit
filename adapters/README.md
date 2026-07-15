# Adapters

Adapters translate the resolved plugin set into tool-specific configuration. Each adapter reads the same `.devkit/toolkit.json` project config and generates output appropriate for its target AI tool.

## Available Adapters

| Adapter | Target Tool | Output |
|---------|-------------|--------|
| `claude` | Claude Code | `.claude-plugin/marketplace.json`, `.claude/settings.json` (permissions + hooks) |
| `cursor` | Cursor IDE | `.cursor/skills/devkit-*--*/`, `.cursor/rules/devkit-*.mdc`, `.cursor/mcp.json`, `.cursor/hooks/hooks.json` |
| `codex` | OpenAI Codex | `.codex/skills/devkit-*--*/`, `AGENTS.md` section (conduct + hook instructions) |

## Usage

```bash
# From project root (toolkit submodule at toolkits/agentic-devkit)
toolkits/agentic-devkit/bin/devkit-resolve --adapter=claude
toolkits/agentic-devkit/bin/devkit-resolve --adapter=cursor
toolkits/agentic-devkit/bin/devkit-resolve --adapter=codex
```

Cursor core skills are installed globally. Stack skills are project-scoped; after upgrading from an older global-skill
installation, rerun the Cursor adapter in each project to create its resolved `.cursor/skills/devkit-*--*` links.

## Adding a New Adapter

1. Create `adapters/<name>/generate` (executable shell script).
2. Source the shared libraries at the top:
   ```bash
   source "$ADAPTER_DIR/../_lib/resolve.sh"
   source "$ADAPTER_DIR/../_lib/hooks.sh"
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
| `_build_plugin_index` | JSON object keyed by plugin name with full manifest + `_dir` |
| `_check_jq` | Exits with error if `jq` is not installed |

### Shared library exports (`_lib/hooks.sh`)

| Function | Returns |
|----------|---------|
| `merge_plugin_hooks` | Merged JSON of all hooks from resolved plugins (Claude Code format) |
| `translate_hooks_to_cursor` | Hooks translated from Claude Code event names to Cursor event names |
| `flatten_hooks_for_text` | Pipe-delimited lines (`event|matcher|command`) for text-based adapters |

### DRY hook adapter pattern

Plugins define hooks once in Claude Code format (the common denominator). Each adapter is responsible for translating event names to its target tool's format. This avoids duplicating hook definitions per tool.

Event name mapping:

| Claude Code | Cursor | Codex |
|-------------|--------|-------|
| `PreToolUse` | `beforeShellExecution` | instruction-based |
| `PostToolUse` | `afterFileEdit` | instruction-based |
| `Stop` | `afterResponse` | instruction-based |
| `Notification` | _(no equivalent)_ | instruction-based |
| `SubagentStop` | _(no equivalent)_ | _(no equivalent)_ |

Codex does not support native hooks; the Codex adapter embeds hook commands as instructions in `AGENTS.md`.

### Environment variables

| Variable | Default | Description |
|----------|---------|-------------|
| `DEVKIT_PROJECT_ROOT` | CWD | Override the project root directory |

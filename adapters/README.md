# Adapters

Adapters translate the resolved plugin set into tool-specific configuration. Each adapter reads the same `.devkit/toolkit.json` project config and generates output appropriate for its target AI tool.

## Available Adapters

| Adapter | Target Tool | Output |
|---------|-------------|--------|
| `claude` | Claude Code | `.claude-plugin/marketplace.json`, `.claude/settings.json` |
| `cursor` | Cursor IDE | `.cursor/rules/devkit-*.mdc`, `.cursor/skills/devkit-*--*/` |
| `codex` | OpenAI Codex | `.codex/skills/devkit-*--*/`, `AGENTS.md` section |

## Usage

```bash
# From project root (toolkit submodule at toolkits/agentic-devkit)
toolkits/agentic-devkit/bin/devkit-resolve --adapter=claude
toolkits/agentic-devkit/bin/devkit-resolve --adapter=cursor
toolkits/agentic-devkit/bin/devkit-resolve --adapter=codex
```

## Adding a New Adapter

1. Create `adapters/<name>/generate` (executable shell script).
2. Source the shared resolution library at the top:
   ```bash
   source "$ADAPTER_DIR/../_lib/resolve.sh"
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

### Environment variables

| Variable | Default | Description |
|----------|---------|-------------|
| `DEVKIT_PROJECT_ROOT` | CWD | Override the project root directory |

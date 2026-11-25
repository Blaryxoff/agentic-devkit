# Antigravity (agy) Adapter

The Antigravity adapter translates the resolved devkit plugin set into native Google Antigravity (AGY) configuration.

## Output (in PROJECT_ROOT)

| Path | Description |
|------|-------------|
| `.agents/skills/<skill-name>/` | Symlinks to resolved stack (non-core) skills, discovered natively by Antigravity |
| `.agents/rules/devkit-<plugin>.md` | Compact conduct-index rules per resolved plugin (`alwaysApply: true`) |
| `.agents/mcp_config.json` | Project MCP servers with per-project isolation |
| `.agents/hooks.json` | Merged lifecycle hooks translated to Antigravity format (gates + feedback) |

Core skills are installed globally into `~/.agents/skills/<skill-name>` by `bin/devkit-install`.

## Usage

```bash
# From the project root
~/.claude/agentic-devkit/bin/devkit-resolve --adapter=agy

# Or via devkit-install
~/.claude/agentic-devkit/bin/devkit-install --agy
```

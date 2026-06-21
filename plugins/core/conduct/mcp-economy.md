# MCP Economy

Keep the MCP tool surface small. Every enabled MCP server loads its full tool definitions into context on every turn, even when no tool is called. Extends `context-management.md` §MCP and tool discipline and `token-optimization.md` §Anti-patterns.

## Enable only what the task needs

- Enable an MCP server per project, not globally, when only a few projects use it.
- Disable servers whose tools the current task will not call.
- When a stack ships an MCP server (adapter `.mcp.json`), include only the servers that stack actually uses.

## Prefer a direct endpoint over a full server for a single operation

- When the task needs one specific operation (read one table, fetch one document, post one message), call the API endpoint directly via a script or skill instead of mounting the whole MCP server.
- A whole server exposes every operation it supports; loading all of them to use one wastes context on definitions that are never invoked.
- Keep the credential handling for direct calls inside config/env per `security.md`-equivalent rules — never inline a token.

## Audit when context feels bloated

- When a session feels heavy, inspect the token breakdown (`/context` in Claude Code, or the equivalent) to see how much MCP definitions consume.
- If MCP tool definitions dominate the breakdown, disable the unused servers and re-measure before continuing.
- Treat a large active tool count as a smell: prefer fewer, well-chosen tools over a broad surface.

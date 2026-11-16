# MCP Economy

Keep the model-visible MCP tool surface small. Hosts with deferred discovery load schemas on demand; eager hosts load every exposed schema upfront. Measure the active client's behavior before changing configuration. Extends `context-management.md` §MCP and tool discipline and `token-optimization.md` §Anti-patterns.

## Enable only what the task needs

- Enable an MCP server per project, not globally, when only a few projects use it.
- Keep occasional integrations discoverable through native tool search; disable servers outside the project's scope.
- When a stack ships an MCP server (adapter `.mcp.json`), include only the servers that stack actually uses.
- Generate the same project MCP catalogue for Claude, Grok, Cursor, and Codex; preserve client-specific built-in tools separately.

## Prefer a direct endpoint over a full server for a single operation

- Use an existing CLI or focused skill for a single operation when it avoids additional discovery and setup. Retain MCP when it supplies authentication, validation, or controlled access the alternative lacks.
- Filter and aggregate tool results before returning them to the model; use pagination and bounded queries instead of full dumps.
- Use native code execution to compose calls and keep intermediate results outside model context when the host supports it.
- Keep credentials for direct calls in config or environment variables as specified by `security.md`; pass tokens through those mechanisms.

## Audit when context feels bloated

- When a session feels heavy, inspect the token breakdown (`/context` in Claude Code, or the equivalent) to see how much MCP definitions consume.
- If MCP tool definitions dominate the breakdown, disable the unused servers and re-measure before continuing.
- Compare total tokens, elapsed time, tool discovery, and task success on the same workload. Cached schemas still occupy context; keep tool exposure stable within a conversation.

Sources: [MCP client best practices](https://modelcontextprotocol.io/docs/develop/clients/client-best-practices), [Claude tool search](https://code.claude.com/docs/en/mcp#scale-with-mcp-tool-search), [Cursor dynamic discovery](https://cursor.com/blog/dynamic-context-discovery).

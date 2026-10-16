# Local projects

`bin/devkit-projects` runs configured development services and exposes the same actions through a local dashboard and an optional MCP server. It uses Python 3.9+ and the standard library. Each developer keeps their own config at the repository root as `projects.json`, which Git ignores. Copy `examples/projects.example.json` there to start. `DEVKIT_PROJECTS_CONFIG` or `--config` selects another file. Only the generic example belongs in Git.

Restart the dashboard and MCP server after editing `projects.json`; the Refresh button updates status, not project definitions.

```bash
~/.claude/agentic-devkit/bin/devkit-projects status
~/.claude/agentic-devkit/bin/devkit-projects start my-app
~/.claude/agentic-devkit/bin/devkit-projects logs my-app web
~/.claude/agentic-devkit/bin/devkit-projects stop my-app
~/.claude/agentic-devkit/bin/devkit-projects ui
```

The dashboard binds to `127.0.0.1:41790`. Open `http://127.0.0.1:41790` on the same machine. Do not forward it to a public address. Firebat agents can use the CLI or MCP without running the dashboard; installation and container-specific project config are separate steps.

On macOS with Herd, `herd proxy agentic-devkit http://127.0.0.1:41790` gives the dashboard `http://agentic-devkit.test` without editing `/etc/hosts`. Start the dashboard with `bin/devkit-projects ui --origin http://agentic-devkit.test` so its host and origin checks accept that address. Herd's proxy does not start the dashboard; a user LaunchAgent can run that command at login if desired. Set a stable Node path in that agent's `PATH` when project commands use `pnpm` or `fnm`; launchd does not inherit the shell's `PATH`. The dashboard still listens only on loopback. Remove the proxy with `herd unproxy agentic-devkit`.

Each `projects` entry has an `id`, `name`, checkout `root`, and one or more `services`. A service has an `id`, an argument array `argv`, optional relative `cwd`, optional environment overrides `env`, reserved `ports`, and readiness `checks`. Checks support `{"type":"tcp","host":"127.0.0.1","port":3000}` and `{"type":"http","url":"http://example.test"}`; an optional `id` names the status chip. HTTP checks accept 2xx and 3xx responses by default. For an application that deliberately returns another status at the checked URL, add `"allow_statuses":[404]` to that check. `external` uses the same check shape for services supplied by Herd or another manager. `links` maps button labels to URLs. Commands run directly from argument arrays without a shell. Store secrets in each application's existing `.env`, not in this config.

Commands inherit the dashboard or MCP process's runtime environment. A version file such as `.nvmrc` does not select Node by itself for background launches. On a machine with fnm, use an `argv` such as `["fnm", "exec", "--", "corepack", "pnpm", "dev"]` to follow the project's version file.

Starting a project launches its configured service group and waits up to 60 seconds for both managed and external checks. If an external check stays unavailable, the error names the failed check and leaves the managed services available for debugging. The dashboard shows an indeterminate progress indicator during the wait. The tool records process identity in `~/.local/state/agentic-devkit/projects` and stops only matching processes it launched. Existing listeners are shown as ports occupied outside the dashboard; stop them in their original terminal before starting the project here. They are never adopted or stopped. Logs redact common credential patterns before display; applications should still avoid printing secrets.

For applications with selectable variants, add `profile_env_file`, `profiles`, and optional `profile_hooks`:

```json
{
  "profile_env_file": ".env",
  "profile_hooks": [["php", "artisan", "config:clear"]],
  "profiles": {
    "Platforma": {"set": {"APP_NAME": "Platforma", "TENANCY_ENABLED": "true"}},
    "Kochfit": {"set": {"APP_NAME": "Kochfit", "TENANCY_ENABLED": "false"}}
  }
}
```

`profile <project> <name>` edits only the listed keys in the checkout's local environment file, runs the hooks, and restarts managed services if they were running. The choice persists in that file. Profiles do not import data or change databases. The dashboard shows an unmatched profile as unselected, so manual `.env` edits remain visible.

To opt an agent into MCP, register a **stdio** server whose command is the absolute path to `bin/devkit-projects` and whose argument is `mcp`. For Codex and Claude Code:

```bash
codex mcp add devkit-projects -- /absolute/path/to/agentic-devkit/bin/devkit-projects mcp
claude mcp add --scope user devkit-projects -- /absolute/path/to/agentic-devkit/bin/devkit-projects mcp
```

For Cursor, merge the server into the user-level `~/.cursor/mcp.json` so it is available in every workspace without adding a project file to Git:

```json
{
  "mcpServers": {
    "devkit-projects": {
      "command": "/absolute/path/to/agentic-devkit/bin/devkit-projects",
      "args": ["mcp"]
    }
  }
}
```

Adjust the path to that machine's devkit clone, preserving any other entries already in `mcpServers`. Restart Cursor after editing the file, then check `cursor-agent mcp list-tools devkit-projects`. The MCP server offers `projects_status`, `project_start`, `project_stop`, `project_logs`, and `project_select_profile`. It never accepts a shell command from the model; project IDs and commands come from the local config.

MCP registration makes the tools available but does not force agents to use them. Put a preference in each agent's global instructions to check `projects_status`, start a stopped configured project, and use its configured link before local browser QA. The CLI offers the same flow when MCP is unavailable.

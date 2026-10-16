# Local projects

`bin/devkit-projects` runs configured development services and exposes the same actions through a local dashboard and an optional MCP server. It uses Python 3.9+ and the standard library. Each developer keeps their own config at the repository root as `projects.json`, which Git ignores. Copy `examples/projects.example.json` there to start. `DEVKIT_PROJECTS_CONFIG` or `--config` selects another file. Only the generic example belongs in Git.

The dashboard and MCP server reread `projects.json` and discover Git worktrees on each request. Refreshing the dashboard shows new worktrees without restarting it.

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

Starting a project launches its configured service group and waits up to 60 seconds for both managed and external checks. If an external check stays unavailable, the error names the failed check and leaves the managed services available for debugging. The dashboard shows an indeterminate progress indicator during the wait. The tool records process identity in `~/.local/state/agentic-devkit/projects` and stops only matching processes it launched. For a port conflict, the dashboard uses `lsof` to show the listening process. After confirmation, it can send `SIGTERM` to a same-user process outside devkit, rechecking its PID, start time, and port first. It never force-kills the process; when `lsof` cannot identify an eligible owner, stop it through its original terminal or manager. Logs redact common credential patterns before display; applications should still avoid printing secrets.

To manage Git worktrees, add one `worktrees` template to the parent project in the ignored `projects.json`. Individual worktrees need no config entry. Discovery uses `git worktree list`, so registered worktrees under `~/www`, `<project>/.claude/worktrees`, and other paths appear in the same expandable list. Each row can start, stop, open, inspect logs, or remove its checkout. The row shows an approximate creation date from the oldest local HEAD reflog entry or the worktree's `.git` file birth time; it omits the date when neither is available. Git does not store an authoritative worktree creation date, and copied or pruned metadata can affect the estimate. `status <project>` and MCP `projects_status` with a project ID show the worktree IDs for CLI and agent actions.

```json
"worktrees": {
  "port_base": 3200,
  "slot_size": 1,
  "slots": 10,
  "services": [{
    "id": "web",
    "argv": ["pnpm", "dev", "--port", "{port0}"],
    "ports": ["{port0}"],
    "checks": [{"type": "tcp", "host": "127.0.0.1", "port": "{port0}"}]
  }],
  "links": {"Фронт": "http://127.0.0.1:{port0}"}
}
```

`port_base` begins a project-specific range. A slot has `slot_size` ports, addressed as `{port0}`, `{port1}`, and so on in commands, environment values, checks, and links. By default the range has room for up to ten ports: ten one-port slots or five two-port slots. All discovered worktrees appear in the list even when there are more worktrees than slots; stopped worktrees give up their slot when another needs it. Slots are assigned on first start, kept across restarts, and recycled from stopped worktrees when needed. Configure distinct ranges for projects and keep them clear of base project ports. Worktrees run in their own checkout and use that checkout's dependencies and `.env`; prepare those files before starting. Use commands that accept a port override rather than a script that hardcodes the base project's port.

The row icons mark modified tracked files (✎), untracked files (＋), and a HEAD commit not found in any locally known remote branch (↑). Hover or focus an icon for its meaning. The manager reads remote-tracking refs without fetching, so fetch the repository to update this indicator after a push elsewhere. Git status is fetched when the list is expanded. The start/stop button also shows each worktree's state. Delete removes a stopped worktree and its local files while leaving its branch in Git. Select worktrees with their checkboxes, or use **Select available**, then **Delete selected** to remove several checkouts in one confirmed operation. The confirmation lists every selected path and warns about modified, untracked, or ignored files such as `.env` that will be lost. Each deletion runs through the same safeguards as the row's trash button; if one fails, the others continue and the failed row shows its error. MCP callers must pass the worktree branch name as confirmation when any of those files exist. The manager uses one `git worktree remove --force` for modified or untracked files, so locked worktrees remain protected. A detached worktree whose HEAD is absent from locally known remote branches cannot be deleted from the dashboard. The manager does not delete branches.

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

Adjust the path to that machine's devkit clone, preserving any other entries already in `mcpServers`. Restart Cursor after editing the file, then check `cursor-agent mcp list-tools devkit-projects`. The MCP server offers `projects_status`, `project_start`, `project_stop`, `project_logs`, `worktree_flags`, `worktree_remove`, and `project_select_profile`. The project start, stop, and log tools accept discovered worktree IDs. `worktree_remove` keeps the branch and applies the same safeguards as the dashboard. The server never accepts a shell command from the model; project IDs and commands come from the local config.

MCP registration makes the tools available but does not force agents to use them. Put a preference in each agent's global instructions to check `projects_status`, start a stopped configured project, and use its configured link before local browser QA. The CLI offers the same flow when MCP is unavailable.

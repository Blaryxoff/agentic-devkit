# Grok adapter

Grok Build imports Claude-compatible skills, agents, project instructions, hooks, and MCP configuration. The project
adapter delegates to `adapters/claude/generate` so plugin resolution, stack isolation and user MCP entries retain the
existing implementation. Grok's normal folder-trust gate still applies; the adapter does not trust folders or grant
tool permissions. No Claude CLI process is required.

The global adapter supplies the missing runtime pieces:

- `install` writes a managed section in `$GROK_HOME/AGENTS.md` and a native `hooks/devkit-toolkit.json` registration.
  `GROK_HOME` defaults to `~/.grok`. Other guidance, native hooks, and `config.toml` are preserved.
- `hook.py` translates Grok `read_file`, `search_replace`, and `run_terminal_command` payloads into the existing devkit
  gate input. It reuses coder, comment, peer-stdin and canonical dev-server checks from the generating clone.
- The native `UserPromptSubmit` hook sends workflow feedback to Jev without requiring imported Claude hooks.
  Jev records the Grok session's canonical `updates.jsonl` address when the event omits its transcript path.
- A code edit requires reading the coder skill in the same Grok session. The native adapter returns an explicit Grok
  denial when a check fails or cannot run. Shell access is still shell access; these hooks are not a sandbox.

Use `bin/devkit-install --grok --project=/path/to/project` for the global integration and project generation. The
global install's existing Claude core skills and router provide Grok's shared catalog. For a project-only refresh,
use `bin/devkit-resolve --adapter=grok --project=/path/to/project` after the global install. Direct entry points are
`adapters/grok/install` and `adapters/grok/generate` with `DEVKIT_PROJECT_ROOT`.

The canonical runtime config is pinned using the same resolver as the other harnesses. A previously required config
remains required during reinstall if the selected file temporarily disappears or becomes unreadable.

Grok may import both Claude and Cursor hooks. Keep the intended status publisher and avoid duplicate imports through
Grok's `[compat.cursor] hooks = false` setting when using the existing Claude lifecycle/status hooks. The adapter leaves
that user setting intact. Machine-specific guards in Claude settings remain active through Claude compatibility.
There is no copy of those guards or of agterm's installed status scripts in this adapter.

Refresh the running Grok hook catalog with `/hooks` → `r`, or start a new session. The `inspect --json` output in Grok
1.0.77 omitted native and imported settings hooks even when its live Hooks screen showed them, so inspect alone is not
runtime hook evidence. Test with `bash tests/grok-adapter.sh`.

For catalog maintenance, use devkit-skill-creator's catalog audit mode. Grok recursively discovers skills inside vendor
roots, including archived `.trash` directories. Exclude a retired root with `[skills] ignore` in the user config,
preserving existing exclusions; `.gitignore` does not control discovery. Audit effective paths again after cleanup.
The managed guidance gives devkit ownership of its workflows while keeping other bundled Grok capabilities available.

References: [Grok skills and compatibility](https://docs.x.ai/build/features/skills-plugins-marketplaces),
[Grok hooks](https://docs.x.ai/build/features/hooks).

# Codex CLI launch for Luna QA

Load this recipe only when native workers cannot provide the required model, effort or isolated chrome-devtools
binding. Apply the browser workflow and the Luna preset before launching.

## Resolve the model and effort arguments

Use the model resolved for this pass; the snippet below resolves it at pass startup. Retain these arguments for
every launch and recheck in the pass. Set `luna_effort` only for an explicitly requested effort.
Set it from the caller's request even when that value equals the runtime default. Before launch, verify that
`luna_cli_args` contains that explicit effort; an inherited default does not satisfy a requested setting.

```bash
luna_catalog_args=()
luna_cli_args=()
if [ -n "${luna_effort:-}" ]; then
  luna_catalog_args=(--effort "$luna_effort")
  luna_cli_args=(-c "model_reasoning_effort=\"$luna_effort\"")
fi
luna_model=$(python3 "$DEVKIT_HOME/bin/devkit-model" luna "${luna_catalog_args[@]}" < /dev/null) || exit 1
```

## Launch isolated lanes

Write each self-contained browser lane brief to a pass-owned temporary directory outside the repository. Give the executor
its ledger slice, exact environment, fixtures, canonical conduct paths, evidence requirements, ownership/cleanup
instructions and result path under `browser-qa-rules.md` §12. Instruct it to execute its assigned lane, preserve application
source and return its evidence in the final message, which `-o` writes to that result path. State explicitly that the
executor is a leaf: it must not invoke `lunaqa` or `browser` as an orchestrator, start another agent, or dispatch a CLI
lane. The lead alone owns further dispatch.

Give each CLI lane an invocation-only MCP name for its browser server. Copy the resolved chrome-devtools stdio entry's
command, arguments and environment under that unique name, retaining `--headless --isolated`; disable the inherited
stdio entry only for that worker. Populate `qa_mcp_config` with those `-c` overrides and `qa_mcp_name` with the new name.
Preserve the executable and each argument verbatim: `command="node"` with `args=["server.js", "--headless", "--isolated"]`
must still launch `node`, with `server.js` as its first argument. Compare the copied entry with the resolved source
before starting the worker; only the binding name, inherited-entry disable and approval setting change.
Require the executor to use that exact tool binding: a similarly named shared connector is not a fallback. Keep the
§10.7 ownership checkpoint closed until the lead verifies ancestry and writes its release record; do not put application
actions before that gate. This changes no global MCP configuration or HTTP connector availability.
Include the lead's verified project-discovery receipt and runtime pin in the startup brief. An ownership-only executor
does not repeat project-registry discovery or start servers; it reports missing pins to the lead and checks only its
assigned browser binding. Preserve the project's required discovery step in the lead's preflight.

```bash
: "${qa_mcp_name:?resolve a unique worker MCP binding}"
: "${qa_mcp_config:?populate invocation-only server overrides}"
DEVKIT_FEEDBACK_WORKER=1 codex exec -C "$project_root" --skip-git-repo-check --sandbox danger-full-access \
  -m "$luna_model" "${luna_cli_args[@]}" -c 'approval_policy="never"' \
  "${qa_mcp_config[@]}" -c "mcp_servers.${qa_mcp_name}.default_tools_approval_mode=\"approve\"" \
  -o "$lane_result" "$(cat "$lane_brief")" < /dev/null > "$lane_log" 2>&1
```

Resolve these paths before launch; use unique result/log paths per attempt. Apply §2.10 MCP selection and §12.7–§12.10
full-access permissions, progress supervision, provider recovery and isolation to every wave and resume. Apply §12.6
for incremental evidence and §11.6 for a replaced browser within a verified dedicated executor; preserve proven
subchecks when redispatching a gap. Follow `shell-invocation.md` for stdin and shell portability.
Workers return missing fixture IDs/states or setup denials to
the lead, which prepares them through authorised tools or a Luna fixture lane and redispatches the affected cells.
An explicitly restricted worker sandbox affects the worker, not the QA lead’s fixture-preparation responsibility under §3.1.
Report a blocker only after those setup paths fail; include attempted commands, exact denial/error and uncovered cell
IDs. Browser test-data mutations still obey the lane's canonical mutation policy. CLI flag reference:
[official Codex documentation](https://developers.openai.com/codex/cli/reference).

#!/usr/bin/env bash
# devkit-toolkit: shared MCP server merge library
# Sourced by adapters that emit MCP config (Claude .mcp.json, Cursor .cursor/mcp.json).
#
# Requires: jq, resolve.sh already sourced (for _build_plugin_index)
#
# Exports:
#   merge_plugin_mcp_servers — merge resolved plugins' mcpServers into one JSON object
#   apply_chrome_devtools_profile — inject per-project Chrome isolation flags

merge_plugin_mcp_servers() {
  local plugin_index="$1"
  local resolved_names="$2"
  local plugin_mcp="{}"

  while IFS= read -r name; do
    [ -z "$name" ] && continue
    local pdata mcp_rel pdir mcp_path servers
    pdata=$(echo "$plugin_index" | jq --arg name "$name" '.[$name]')
    mcp_rel=$(echo "$pdata" | jq -r '.paths.mcpServers // empty')
    [ -n "$mcp_rel" ] || continue
    pdir=$(echo "$pdata" | jq -r '._dir')
    mcp_path="$pdir/${mcp_rel#./}"
    [ -f "$mcp_path" ] || continue
    servers=$(jq '.mcpServers // {}' "$mcp_path")
    plugin_mcp=$(echo "$plugin_mcp" | jq --argjson s "$servers" '. * $s')
  done <<< "$resolved_names"

  echo "$plugin_mcp"
}

# Patch chrome-devtools args so each project/session gets its own Chrome profile.
# $1 — mcpServers JSON object; $2 — profile directory (absolute or ${workspaceFolder}/…).
apply_chrome_devtools_profile() {
  local servers_json="$1"
  local profile_dir="$2"

  echo "$servers_json" | jq --arg dir "$profile_dir" '
    if .["chrome-devtools"] then
      .["chrome-devtools"].args = [
        "-y",
        "chrome-devtools-mcp@latest",
        "--experimentalPageIdRouting",
        "--userDataDir",
        $dir
      ]
    else
      .
    end
  '
}

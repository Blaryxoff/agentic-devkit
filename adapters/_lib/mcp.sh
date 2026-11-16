#!/usr/bin/env bash
# devkit-toolkit: shared MCP server merge library
# Sourced by adapters that emit project MCP configuration.
#
# Requires: jq, Python 3.11+, resolve.sh already sourced
#
# Exports:
#   merge_plugin_mcp_servers — merge resolved plugins' mcpServers into one JSON object
#   apply_chrome_devtools_profile — inject per-project Chrome isolation flags
#   sync_project_mcp_servers — synchronize project MCP catalogues for every client

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
    if [ ! -d "$PROJECT_ROOT/vendor/laravel/boost" ]; then
      servers=$(echo "$servers" | jq 'del(.["laravel-boost"])')
    fi
    plugin_mcp=$(echo "$plugin_mcp" | jq --argjson s "$servers" '. * $s')
  done <<< "$resolved_names"

  echo "$plugin_mcp"
}

apply_chrome_devtools_profile() {
  local servers_json="$1"

  echo "$servers_json" | jq '
    if .["chrome-devtools"].command == "npx"
      and ((.["chrome-devtools"].args // []) | index("chrome-devtools-mcp@latest"))
      and ((.["chrome-devtools"].args // []) | all(. == "-y" or . == "chrome-devtools-mcp@latest"
        or . == "--headless" or . == "--pageIdRouting" or . == "--experimentalPageIdRouting" or . == "--isolated"))
    then
      .["chrome-devtools"].args = [
        "-y",
        "chrome-devtools-mcp@latest",
        "--headless",
        "--pageIdRouting",
        "--isolated"
      ]
    else
      .
    end
  '
}

sync_project_mcp_servers() {
  local plugin_mcp
  plugin_mcp=$(merge_plugin_mcp_servers "$1" "$2")
  plugin_mcp=$(apply_chrome_devtools_profile "$plugin_mcp")
  python3 "$(dirname "${BASH_SOURCE[0]}")/mcp.py" "$PROJECT_ROOT" <<< "$plugin_mcp"
  ensure_gitignore_entry ".cursor/chrome-profile/"
  ensure_gitignore_entry ".codex/"
  ensure_gitignore_entry ".grok/"
}

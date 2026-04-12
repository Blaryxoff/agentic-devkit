#!/usr/bin/env bash
# devkit-toolkit: core resolution library
# Sourced by bin/devkit-resolve and individual adapters.
# Requires: jq, python3 (for relative path computation)
#
# Exports:
#   TOOLKIT_ROOT     — absolute path to the toolkit repo root
#   PROJECT_ROOT     — absolute path to the consuming project root (CWD)
#   resolve_plugins  — outputs ordered list of resolved plugin names
#   resolve_plugin_dirs — outputs ordered list of resolved plugin directories
#   toolkit_relpath  — relative path from project root to toolkit root

set -euo pipefail

TOOLKIT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PROJECT_ROOT="${DEVKIT_PROJECT_ROOT:-$(pwd)}"

_check_jq() {
  if ! command -v jq &>/dev/null; then
    echo "ERROR: jq is required but not found. Install it: https://jqlang.github.io/jq/download/" >&2
    exit 1
  fi
}

_build_plugin_index() {
  local index="{}"
  for manifest in "$TOOLKIT_ROOT"/plugins/*/plugin.json; do
    [ -f "$manifest" ] || continue
    local dir
    dir=$(dirname "$manifest")
    local content
    content=$(jq --arg dir "$dir" '. + {_dir: $dir}' "$manifest")
    local name
    name=$(echo "$content" | jq -r '.name')
    index=$(echo "$index" | jq --arg name "$name" --argjson plugin "$content" '.[$name] = $plugin')
  done
  echo "$index"
}

resolve_plugins() {
  _check_jq

  local config="$PROJECT_ROOT/.devkit/toolkit.json"
  if [ ! -f "$config" ]; then
    echo "ERROR: No .devkit/toolkit.json found at $PROJECT_ROOT" >&2
    echo "Create one with: {\"version\": 1, \"enabled\": [\"devkit-laravel\"]}" >&2
    exit 1
  fi

  local version
  version=$(jq -r '.version' "$config")
  if [ "$version" != "1" ]; then
    echo "ERROR: Unsupported toolkit.json version: $version (expected 1)" >&2
    exit 1
  fi

  local enabled
  enabled=$(jq -r '.enabled[]' "$config")
  local plugin_index
  plugin_index=$(_build_plugin_index)

  local layer_order='{"core":0,"stack":1,"framework":2,"styling":3}'

  echo "$plugin_index" | jq -r --arg enabled_raw "$enabled" --argjson layer_order "$layer_order" '
    def resolve(name; visited; resolved):
      if (resolved | has(name)) then [visited, resolved]
      elif (visited | has(name)) then
        "CYCLE:\(name)" | halt_error(1)
      elif (has(name) | not) then
        "MISSING:\(name)" | halt_error(1)
      else
        (visited + {(name): true}) as $v |
        reduce (.[name].dependencies[]? // empty) as $dep (
          [$v, resolved];
          resolve($dep; .[0]; .[1])
        ) |
        [.[0] | del(.[name]), .[1] + {(name): true}]
      end;

    ($enabled_raw | split("\n") | map(select(. != ""))) as $enabled_list |

    [keys[] | select(.[$layer_order] != null) | select(.[. as $k | $k] | .defaultEnabled == true)] as $defaults |

    reduce (($defaults + $enabled_list)[] | select(. != "")) as $plugin (
      [{}, {}];
      resolve($plugin; .[0]; .[1])
    ) |
    .[1] | keys[] |
    . as $name |
    {name: $name, layer_idx: ($layer_order[input_line_number - 1] // 99)} |
    .name
  ' 2>&1

  local exit_code=$?
  if [ $exit_code -ne 0 ]; then
    return $exit_code
  fi
}

resolve_plugins() {
  _check_jq

  local config="$PROJECT_ROOT/.devkit/toolkit.json"
  if [ ! -f "$config" ]; then
    echo "ERROR: No .devkit/toolkit.json found at $PROJECT_ROOT" >&2
    exit 1
  fi

  local version
  version=$(jq -r '.version' "$config")
  if [ "$version" != "1" ]; then
    echo "ERROR: Unsupported toolkit.json version: $version (expected 1)" >&2
    exit 1
  fi

  local plugin_index
  plugin_index=$(_build_plugin_index)

  local enabled_json
  enabled_json=$(jq '.enabled' "$config")

  echo "$plugin_index" | jq -r --argjson enabled "$enabled_json" '
    . as $plugins |

    {"core":0, "stack":1, "framework":2, "styling":3} as $layer_order |

    def resolve_one(name; stack):
      if ($plugins | has(name) | not) then
        error("Plugin not found: \(name)")
      elif (stack | index(name)) then
        error("Dependency cycle: \(stack + [name] | join(" -> "))")
      else . end |
      if (.resolved | has(name)) then .
      else
        (stack + [name]) as $new_stack |
        reduce ($plugins[name].dependencies[]? // empty) as $dep (
          .;
          resolve_one($dep; $new_stack)
        ) |
        .resolved[name] = true
      end;

    # Collect default-enabled plugins
    [$plugins | to_entries[] | select(.value.defaultEnabled == true) | .key] as $defaults |

    # Resolve all
    reduce (($defaults + $enabled)[] | select(. != null and . != "")) as $p (
      {resolved: {}};
      resolve_one($p; [])
    ) |

    .resolved | keys | sort_by($layer_order[$plugins[.].layer] // 99) |
    .[]
  '
}

resolve_plugin_dirs() {
  _check_jq
  local plugin_index
  plugin_index=$(_build_plugin_index)
  local names
  names=$(resolve_plugins)
  echo "$names" | while IFS= read -r name; do
    [ -n "$name" ] && echo "$plugin_index" | jq -r --arg name "$name" '.[$name]._dir // empty'
  done
}

toolkit_relpath() {
  python3 -c "import os.path; print(os.path.relpath('$TOOLKIT_ROOT', '$PROJECT_ROOT'))"
}

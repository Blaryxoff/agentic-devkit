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
    local _hint
    _hint=$(python3 -c "import os.path; print(os.path.relpath('$TOOLKIT_ROOT', '$PROJECT_ROOT'))")
    echo "ERROR: No .devkit/toolkit.json found at $PROJECT_ROOT" >&2
    echo "Run:   $_hint/bin/devkit-resolve --init" >&2
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

# Ensure a path entry is present in PROJECT_ROOT/.gitignore.
# Only applies when PROJECT_ROOT is inside a git working tree.
# Matches existing entries exactly (ignoring leading/trailing whitespace and
# an optional leading "/"), so "/.claude" and ".claude" are treated the same.
ensure_gitignore_entry() {
  local entry="$1"
  [ -n "$entry" ] || return 0

  # Only act inside a git repo
  if ! git -C "$PROJECT_ROOT" rev-parse --is-inside-work-tree &>/dev/null; then
    return 0
  fi

  local gitignore="$PROJECT_ROOT/.gitignore"
  local needle="${entry#/}"
  needle="${needle%/}"

  if [ -f "$gitignore" ]; then
    # Check existing lines; normalise by stripping comments, whitespace,
    # and leading/trailing slashes before comparing.
    if awk -v n="$needle" '
      {
        line = $0
        sub(/#.*/, "", line)
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", line)
        sub(/^\//, "", line)
        sub(/\/$/, "", line)
        if (line == n) found = 1
      }
      END { exit found ? 0 : 1 }
    ' "$gitignore"; then
      return 0
    fi
    # Ensure file ends with newline before appending
    if [ -s "$gitignore" ] && [ "$(tail -c1 "$gitignore" | wc -l | tr -d ' ')" = "0" ]; then
      printf '\n' >> "$gitignore"
    fi
    printf '%s\n' "$entry" >> "$gitignore"
  else
    printf '%s\n' "$entry" > "$gitignore"
  fi
  echo "    Updated: .gitignore (added $entry)"
}

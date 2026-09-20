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

# Absolute path to the active toolkit checkout (filesystem ops, symlink targets).
toolkit_abspath() { printf '%s\n' "$TOOLKIT_ROOT"; }

# Portable display root embedded in generated text (Cursor .mdc, Codex AGENTS.md).
# Defaults to the conventional global clone location; the leading ~ is left
# unexpanded so the same string works for every developer's $HOME. Override with
# DEVKIT_HOME_REF when the clone lives elsewhere.
DEVKIT_HOME_REF="${DEVKIT_HOME_REF:-~/.claude/agentic-devkit}"
toolkit_home_ref() { printf '%s\n' "$DEVKIT_HOME_REF"; }

# Write JSON to a destination atomically. A plain `producer > dest` truncates the
# target when the redirection is set up, before the producer runs, so an
# interruption or a jq fault leaves an empty file with no backup.
# Usage: write_json <dest> <json-text>
write_json() {
  local dest="$1" json="$2" tmp mode
  # Resolve a symlinked destination: `mv` onto a symlink replaces the link, while
  # the redirection this replaced wrote through it. Dotfile repos rely on that.
  if [ -L "$dest" ]; then
    dest=$(python3 -c 'import os,sys; print(os.path.realpath(sys.argv[1]))' "$dest") || return 1
  fi
  tmp="$dest.devkit.tmp.$$"
  if ! printf '%s\n' "$json" | jq '.' > "$tmp"; then
    rm -f "$tmp"
    echo "ERROR: refusing to write invalid JSON to $dest" >&2
    return 1
  fi
  # An empty producer passes jq with exit 0 and no output, which would still truncate
  # the destination. `{}` and `null` are non-empty, so no real payload is rejected here.
  if [ ! -s "$tmp" ]; then
    rm -f "$tmp"
    echo "ERROR: refusing to write empty JSON to $dest" >&2
    return 1
  fi
  # `mv` also carries the temp file's umask mode over; keep the target's own.
  if [ -f "$dest" ]; then
    mode=$(python3 -c 'import os,stat,sys; print(format(stat.S_IMODE(os.stat(sys.argv[1]).st_mode), "04o"))' "$dest" 2>/dev/null) \
      && chmod "$mode" "$tmp" 2>/dev/null || true
  fi
  mv -f "$tmp" "$dest"
}

_check_jq() {
  if ! command -v jq &>/dev/null; then
    echo "ERROR: jq is required but not found. Install it: https://jqlang.github.io/jq/download/" >&2
    return 1
  fi
}

# Fail fast at source-time — _build_plugin_index and other helpers call jq
# unconditionally, so leaving the check inside resolve_plugins() lets the
# adapter spew a wall of "jq: command not found" before the real error fires.
_check_jq

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

# Project roots to resolve. Multiple roots support a single logical project
# split across repos (e.g. backend + frontend), each with its own
# .devkit/toolkit.json. DEVKIT_PROJECT_ROOTS is a ':'-separated list; when unset
# the single PROJECT_ROOT is used.
_project_roots() {
  if [ -n "${DEVKIT_PROJECT_ROOTS:-}" ]; then
    printf '%s\n' "$DEVKIT_PROJECT_ROOTS" | tr ':' '\n' | while IFS= read -r r; do
      [ -n "$r" ] && printf '%s\n' "$r"
    done
  else
    printf '%s\n' "$PROJECT_ROOT"
  fi
}

# Union the .enabled arrays from every project root's toolkit.json, de-duplicated
# in discovery order. Errors only when NO root carries a config.
_collect_enabled() {
  local merged='[]'
  local found=0
  local root_count
  root_count=$(_project_roots | grep -c .)
  while IFS= read -r root; do
    [ -n "$root" ] || continue
    local config="$root/.devkit/toolkit.json"
    if [ ! -f "$config" ]; then
      if [ "$root_count" -gt 1 ]; then
        echo "WARN: no .devkit/toolkit.json at $root — skipped" >&2
      fi
      continue
    fi
    found=1
    local version
    version=$(jq -r '.version' "$config")
    if [ "$version" != "1" ]; then
      echo "ERROR: Unsupported toolkit.json version: $version (expected 1) at $config" >&2
      return 1
    fi
    merged=$(jq -n --argjson a "$merged" --slurpfile c "$config" \
      '($a + ($c[0].enabled // [])) | reduce .[] as $x ([]; if index($x) then . else . + [$x] end)')
  done < <(_project_roots)

  if [ "$found" -eq 0 ]; then
    local _hint
    _hint=$(python3 -c 'import os.path,sys; print(os.path.relpath(sys.argv[1], sys.argv[2]))' "$TOOLKIT_ROOT" "$PROJECT_ROOT")
    echo "ERROR: No .devkit/toolkit.json found at $PROJECT_ROOT" >&2
    echo "Run:   $_hint/bin/devkit-resolve --init" >&2
    return 1
  fi
  echo "$merged"
}

resolve_plugins() {
  _check_jq || return 1

  local plugin_index
  plugin_index=$(_build_plugin_index)

  local enabled_json
  enabled_json=$(_collect_enabled) || return 1

  local resolved_out resolved_err rc=0
  resolved_err=$(mktemp)
  resolved_out=$(echo "$plugin_index" | jq -r --argjson enabled "$enabled_json" '
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
  ' 2>"$resolved_err") || rc=$?
  if [ "$rc" -ne 0 ]; then
    # jq prints `jq: error (at <stdin>:129): Plugin not found: devkit-nope`; the
    # location is an artifact of how the index is piped in, not something a user acts on.
    sed -e 's/^jq: error[^)]*): /ERROR: /' -e 's/^jq: error: /ERROR: /' "$resolved_err" >&2
    rm -f "$resolved_err"
    return 1
  fi
  rm -f "$resolved_err"
  printf '%s\n' "$resolved_out"
}

# Validate a single JSON document against one of the shipped schemas.
_validate_one() {
  local schema="$1" doc="$2" label="$3" out
  if ! jq -e . "$doc" >/dev/null 2>&1; then
    echo "ERROR: $label is not valid JSON" >&2
    return 1
  fi
  if ! out=$(jq -n -r --argjson schema "$(cat "$schema")" --argjson doc "$(cat "$doc")" \
      --arg label "$label" -f "$TOOLKIT_ROOT/adapters/_lib/schema-validate.jq"); then
    echo "ERROR: could not validate $label" >&2
    return 1
  fi
  if [ -z "$out" ]; then
    return 0
  fi
  printf '%s\n' "$out" | while IFS= read -r line; do echo "ERROR: $line" >&2; done
  return 1
}

# Check every project's toolkit.json and every shipped plugin.json against
# schemas/. Targeted validation over the draft-07 subset those schemas use, not
# full JSON Schema conformance — see adapters/_lib/schema-validate.jq.
# Prints the number of manifests checked on success.
validate_schemas() {
  _check_jq || return 1
  local rc=0 manifest count=0
  if [ ! -f "$TOOLKIT_ROOT/adapters/_lib/schema-validate.jq" ]; then
    echo "ERROR: missing $TOOLKIT_ROOT/adapters/_lib/schema-validate.jq" >&2
    return 1
  fi
  while IFS= read -r root; do
    [ -n "$root" ] || continue
    if [ -f "$root/.devkit/toolkit.json" ]; then
      _validate_one "$TOOLKIT_ROOT/schemas/toolkit.schema.json" \
        "$root/.devkit/toolkit.json" "$root/.devkit/toolkit.json" || rc=1
    fi
  done < <(_project_roots)
  for manifest in "$TOOLKIT_ROOT"/plugins/*/plugin.json; do
    [ -f "$manifest" ] || continue
    count=$((count + 1))
    _validate_one "$TOOLKIT_ROOT/schemas/plugin.schema.json" "$manifest" \
      "${manifest#"$TOOLKIT_ROOT/"}" || rc=1
  done
  printf '%s\n' "$count"
  return $rc
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
  python3 -c 'import os.path,sys; print(os.path.relpath(sys.argv[1], sys.argv[2]))' "$TOOLKIT_ROOT" "$PROJECT_ROOT"
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

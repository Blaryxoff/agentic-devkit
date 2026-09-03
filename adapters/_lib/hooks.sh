#!/usr/bin/env bash
# devkit-toolkit: shared hook merging library
# Sourced by adapters that need to merge hooks from resolved plugins.
#
# Requires: jq, resolve.sh already sourced (for _build_plugin_index)
#
# Exports:
#   merge_plugin_hooks  — merge all resolved plugins' hooks into a single JSON object
#   merge_hooks_preserving_existing — merge new hooks into an existing hooks-by-event object
#
# Plugin hooks format (Claude Code canonical):
#   {
#     "hooks": {
#       "EventName": [
#         {
#           "matcher": "regex",
#           "hooks": [
#             { "type": "command", "command": "...", "timeout": 60000 }
#           ]
#         }
#       ]
#     }
#   }
#
# Each event contains an array of matcher objects.
# Each matcher object has a "matcher" regex and a "hooks" array of command objects.
# The merged output has the same shape, with matcher entries concatenated per event type.
# Each adapter is responsible for translating event names to its target tool's format.

merge_plugin_hooks() {
  local plugin_index="$1"
  local resolved_names="$2"
  local merged='{}'

  while IFS= read -r name; do
    [ -z "$name" ] && continue
    local plugin_data
    plugin_data=$(echo "$plugin_index" | jq --arg name "$name" '.[$name]')
    local plugin_dir
    plugin_dir=$(echo "$plugin_data" | jq -r '._dir')
    local hooks_path
    hooks_path=$(echo "$plugin_data" | jq -r '.paths.hooks // empty')

    if [ -z "$hooks_path" ]; then
      continue
    fi

    local hooks_file="$plugin_dir/$hooks_path"
    if [ ! -f "$hooks_file" ]; then
      continue
    fi

    local plugin_hooks
    plugin_hooks=$(jq '.hooks // {}' "$hooks_file" 2>/dev/null || echo '{}')

    if [ "$plugin_hooks" = '{}' ]; then
      continue
    fi

    merged=$(echo "$merged" | jq --argjson new "$plugin_hooks" '
      reduce ($new | to_entries[]) as $entry (
        .;
        .[$entry.key] = ((.[$entry.key] // []) + $entry.value)
      )
    ')
  done <<< "$resolved_names"

  echo "$merged"
}

# merge_hooks_preserving_existing <existing_hooks_json> <new_hooks_json> — per event, drops existing matcher entries whose command also appears in <new_hooks_json> for that event, then appends <new_hooks_json>'s entries; both args and the result are hooks-by-event objects
merge_hooks_preserving_existing() {
  local existing="$1"
  local new="$2"

  jq -n --argjson existing "$existing" --argjson new "$new" '
    $existing as $base |
    reduce ($new | to_entries[]) as $entry (
      $base;
      ($entry.value | map(.hooks[]?.command)) as $new_cmds |
      .[$entry.key] = (
        ((.[$entry.key] // [])
          | map(.hooks = ((.hooks // []) | map(select(.command as $c | ($new_cmds | index($c)) | not))))
          | map(select((.hooks // []) | length > 0))
        ) + $entry.value
      )
    )
  '
}

# Event name mapping: Claude Code → Cursor
# Claude Code events: PreToolUse, PostToolUse, Notification, Stop, SubagentStop
# Cursor events:      preToolUse, afterFileEdit, beforeShellExecution, etc.
#
# PreToolUse maps to preToolUse (edit/tool gates), not beforeShellExecution.
# Not all events map 1:1. This function translates where possible
# and drops events that have no Cursor equivalent.
translate_hooks_to_cursor() {
  local merged_hooks="$1"

  echo "$merged_hooks" | jq '
    {
      "PreToolUse":    "preToolUse",
      "PostToolUse":   "afterFileEdit",
      "Stop":          "afterResponse"
    } as $event_map |

    reduce (to_entries[]) as $entry (
      {};
      if ($event_map[$entry.key] != null) then
        .[$event_map[$entry.key]] = (
          (.[$event_map[$entry.key]] // []) + $entry.value
        )
      else . end
    )
  '
}

# Inject devkit core edit gates into Cursor preToolUse hooks JSON.
# $1 — hooks object; $2 — coder-gate command; $3 — comment-gate command.
inject_cursor_edit_gates() {
  local hooks_json="$1"
  local coder_cmd="$2"
  local comment_cmd="$3"

  echo "$hooks_json" | jq --arg coder "$coder_cmd" --arg comment "$comment_cmd" '
    def ensure_gate($matcher; $cmd):
      .preToolUse = (
        (.preToolUse // [])
        | map(select(
            ((.hooks // []) | any(.command == $cmd)) and ((.matcher // "") == $matcher)
            | not
          ))
      ) + [{
        matcher: $matcher,
        hooks: [{ type: "command", command: $cmd, timeout: 60000 }]
      }];
    ensure_gate("Read|ReadFile"; $coder)
    | ensure_gate("Write|StrReplace|Edit|MultiEdit|Delete|EditNotebook|apply_patch"; $coder)
    | ensure_gate("Write|StrReplace|Edit|MultiEdit|Delete|EditNotebook|apply_patch"; $comment)
  '
}

# Flatten hooks into a simple list of {event, matcher, command} for text-based adapters (Codex AGENTS.md).
# Extracts the command strings from the nested structure.
flatten_hooks_for_text() {
  local merged_hooks="$1"

  echo "$merged_hooks" | jq -r '
    to_entries[] |
    .key as $event |
    .value[] |
    .matcher as $matcher |
    .hooks[] |
    "\($event)|\($matcher)|\(.command)"
  '
}

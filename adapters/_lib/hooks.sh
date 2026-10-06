#!/usr/bin/env bash
# devkit-toolkit: shared hook merging library
# Sourced by adapters that need to merge hooks from resolved plugins.
#
# Requires: jq, resolve.sh already sourced (for _build_plugin_index)
#
# Exports:
#   merge_plugin_hooks  — merge all resolved plugins' hooks into a single JSON object
#   merge_hooks_preserving_existing — merge new hooks into an existing hooks-by-event object
#   translate_hooks_to_claude — convert manifest timeouts to the seconds Claude Code reads
#
# Plugin hooks format (Claude Code shape; `timeout` is in milliseconds and each adapter converts it):
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
    if ! plugin_hooks=$(jq '.hooks // {}' "$hooks_file" 2>/dev/null); then
      echo "WARN: $hooks_file is not valid JSON — its hooks were skipped." >&2
      plugin_hooks='{}'
    fi

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

translate_hooks_to_claude() {
  printf '%s\n' "$1" | jq '
    map_values(map(.hooks = [(.hooks // [])[] |
      if (.timeout | type) == "number" then .timeout = ((.timeout / 1000) | ceil) else . end
    ]))
  '
}

normalize_cursor_hooks() {
  printf '%s\n' "$1" | jq '
    def flatten:
      if (.hooks? | type) == "array" then
        . as $group | [.hooks[] |
          . + (if $group.matcher? then {matcher: $group.matcher} else {} end) |
          if (.timeout | type) == "number" and .timeout >= 1000
          then .timeout = ((.timeout / 1000) | ceil) else . end
        ]
      else [.] end;
    (.hooks // .) | with_entries(.value |= [.[] | flatten[]])
  '
}

merge_cursor_hooks_preserving_existing() {
  jq -n --argjson existing "$1" --argjson new "$2" '
    reduce ($new | to_entries[]) as $entry ($existing;
      ($entry.value | map(.command // empty)) as $commands |
      .[$entry.key] = ([ (.[$entry.key] // [])[] |
        select((.command // "") as $command | ($commands | index($command)) | not)
      ] + $entry.value)
    )
  '
}

translate_hooks_to_cursor() {
  local merged_hooks="$1"

  echo "$merged_hooks" | jq '
    {
      "PreToolUse":    "preToolUse",
      "PostToolUse":   "postToolUse",
      "UserPromptSubmit": "beforeSubmitPrompt",
      "Stop":          "stop",
      "SessionStart":  "sessionStart",
      "SessionEnd":    "sessionEnd",
      "SubagentStop":   "subagentStop",
      "PreCompact":    "preCompact"
    } as $event_map |

    reduce (to_entries[]) as $entry (
      {};
      if ($event_map[$entry.key] != null) then
        .[$event_map[$entry.key]] = (
          (.[$event_map[$entry.key]] // []) +
          [$entry.value[] as $group | $group.hooks[] |
            . + (if $group.matcher? then {matcher: $group.matcher} else {} end) |
            if (.timeout | type) == "number"
            then .timeout = ((.timeout / 1000) | ceil) else . end
          ]
        )
      else . end
    )
  '
}

inject_cursor_edit_gates() {
  local hooks_json="$1"
  local coder_cmd="$2"
  local comment_cmd="$3"

  echo "$hooks_json" | jq --arg coder "$coder_cmd" --arg comment "$comment_cmd" '
    .preToolUse = (
      [(.preToolUse // [])[] |
        select((.command // "" | contains("plugins/core/hooks/coder-gate.sh")) | not) |
        select((.command // "" | contains("plugins/core/hooks/comment-gate.sh")) | not)
      ] + [
        {command: $coder, matcher: "Read|ReadFile", timeout: 60},
        {command: $coder, matcher: "Write|StrReplace|Edit|MultiEdit|Delete|EditNotebook|apply_patch", timeout: 60},
        {command: $comment, matcher: "Write|StrReplace|Edit|MultiEdit|Delete|EditNotebook|apply_patch", timeout: 60}
      ]
    )
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

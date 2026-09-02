#!/bin/sh
# coder-gate.sh — PreToolUse hook for Claude Code, Codex, and Cursor code edits.
#
# Hard-gates code edits until devkit-coder was activated in the session. Cursor
# flushes transcript lines only after a turn batch completes, so activation is
# recorded from Read/ReadFile preToolUse payload as well as transcript scan.
# Once detected, a marker keyed on session_id avoids rescanning on every edit.
# A canonicalized tmp/scratch path outside any git work tree is exempt; payloads with no path field (Codex apply_patch, EditNotebook) still gate.
# Payload text lives in coder-gate.txt.
#
# Fail-open by design: if jq is missing or the input is unparseable, allow the edit
# rather than block every write. Adapted alongside skill-eval.sh.

input=$(cat)

command -v jq >/dev/null 2>&1 || exit 0

tool=$(printf '%s' "$input" | jq -r '.tool_name // .toolName // empty' 2>/dev/null)
sid=$(printf '%s' "$input" | jq -r '.session_id // .sessionId // .conversation_id // empty' 2>/dev/null)
safe_sid=$(printf '%s' "$sid" | tr -c 'A-Za-z0-9._-' '_')
marker="${TMPDIR:-/tmp}/devkit-coder-active-$safe_sid"

is_coder_skill_path() {
  case "$1" in
    *devkit-core--coder/SKILL.md | *devkit-coder/SKILL.md | *plugins/core/skills/coder/SKILL.md) return 0 ;;
    *) return 1 ;;
  esac
}

tmpdir=$(CDPATH='' cd -- "${TMPDIR:-/tmp}" 2>/dev/null && pwd -P) || tmpdir=/tmp
case "$tmpdir" in '' | /) tmpdir=/tmp ;; esac

is_scratch_path() {
  case "$1" in
    /*) ;;
    *) return 1 ;;
  esac
  [ -L "$1" ] && return 1
  dir=$(dirname -- "$1")
  real_dir=$(CDPATH='' cd -- "$dir" 2>/dev/null && pwd -P) || return 1
  case "$real_dir/" in
    "$tmpdir"/* | /tmp/* | /private/tmp/*) ;;
    *) return 1 ;;
  esac
  d="$real_dir"
  while [ "$d" != / ]; do
    case "$d/" in
      "$tmpdir"/* | /tmp/* | /private/tmp/*) ;;
      *) break ;;
    esac
    [ -e "$d/.git" ] && return 1
    d=$(dirname -- "$d")
  done
  return 0
}

target=$(printf '%s' "$input" | jq -r '
  .tool_input.path // .tool_input.file_path
  // .toolInput.path // .toolInput.filePath
  // .input.path // empty
' 2>/dev/null)

case "$tool" in
  Read | ReadFile)
    if [ -n "$sid" ] && is_coder_skill_path "$target"; then
      : > "$marker"
    fi
    exit 0
    ;;
  Edit | Write | MultiEdit | apply_patch | StrReplace | Delete | EditNotebook)
    is_scratch_path "$target" && exit 0
    ;;
  *) exit 0 ;;
esac

[ -n "$sid" ] || exit 0
[ -f "$marker" ] && exit 0

transcript=$(printf '%s' "$input" | jq -r '.transcript_path // .transcriptPath // empty' 2>/dev/null)
[ -r "$transcript" ] || exit 0

if jq -e '
  def coder_skill_path: "(devkit-core--coder|devkit-coder|plugins/core/skills/coder)/SKILL\\.md";
  select(
    (
      .message.content? != null
      and any(
        .message.content[]?;
        .type == "tool_use"
        and .name == "Skill"
        and (
          .input.skill == "devkit-core--coder"
          or .input.skill == "devkit-coder"
        )
      )
    )
    or
    (
      .type == "response_item"
      and .payload.type == "custom_tool_call"
      and (
        (.payload.input // "")
        | test(coder_skill_path)
      )
    )
    or
    (
      .role == "assistant"
      and .message.content? != null
      and any(
        .message.content[]?;
        .type == "tool_use"
        and (.name == "Read" or .name == "ReadFile")
        and (
          (.input.path // "")
          | test(coder_skill_path)
        )
      )
    )
  )
  | true
' "$transcript" 2>/dev/null | grep -q '^true$'; then
  : > "$marker"
  exit 0
fi

dir=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
cat "$dir/coder-gate.txt" >&2
exit 2

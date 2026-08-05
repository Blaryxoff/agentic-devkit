#!/bin/sh
# coder-gate.sh — PreToolUse hook for Claude Code, Codex, and Cursor code edits.
#
# Hard-gates code edits until the session transcript shows that devkit-coder was
# activated. Once detected, a marker keyed on session_id avoids rescanning the
# transcript on every subsequent edit. Payload text lives in coder-gate.txt.
#
# Fail-open by design: if jq is missing or the input is unparseable, allow the edit
# rather than block every write. Adapted alongside skill-eval.sh.

input=$(cat)

# Without jq we cannot reliably inspect the hook payload or transcript.
command -v jq >/dev/null 2>&1 || exit 0

tool=$(printf '%s' "$input" | jq -r '.tool_name // .toolName // empty' 2>/dev/null)
case "$tool" in
  Edit | Write | MultiEdit | apply_patch | StrReplace | Delete | EditNotebook) ;;
  *) exit 0 ;;
esac

sid=$(printf '%s' "$input" | jq -r '.session_id // .sessionId // .conversation_id // empty' 2>/dev/null)
transcript=$(printf '%s' "$input" | jq -r '.transcript_path // .transcriptPath // empty' 2>/dev/null)
[ -n "$sid" ] && [ -r "$transcript" ] || exit 0

safe_sid=$(printf '%s' "$sid" | tr -c 'A-Za-z0-9._-' '_')
marker="${TMPDIR:-/tmp}/devkit-coder-active-$safe_sid"
[ -f "$marker" ] && exit 0

# Claude records successful Skill tool calls. Codex records the tool call that
# reads the selected SKILL.md. Cursor records Read(path=…/devkit-core--coder/SKILL.md).
# Match only outer transcript events so quoted log output or the initial skill
# catalog cannot create a false positive.
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
        and .name == "Read"
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

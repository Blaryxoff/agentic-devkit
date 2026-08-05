#!/bin/sh
# comment-gate.sh — PreToolUse hook for Claude Code, Codex, and Cursor code edits.
#
# Blocks edits that introduce change-narrating comments (`// раньше было X`,
# `// now we use Y`, `// added`), which code-comments.md forbids outright. Only
# comment text this edit actually adds is inspected: patch context lines, the
# replaced text, and the file's current contents are all subtracted first, and
# prose targets (.md/.txt/…) are skipped entirely. Payload text lives in
# comment-gate.txt.
#
# Fail-open by design: if jq is missing or the input is unparseable, allow the edit
# rather than block every write. Runs alongside coder-gate.sh.

input=$(cat)

command -v jq >/dev/null 2>&1 || exit 0

tool=$(printf '%s' "$input" | jq -r '.tool_name // .toolName // empty' 2>/dev/null)
case "$tool" in
  Edit | Write | MultiEdit | apply_patch | StrReplace | Delete | EditNotebook) ;;
  *) exit 0 ;;
esac

is_prose() {
  case "$1" in
    *.md | *.mdx | *.markdown | *.txt | *.rst) return 0 ;;
    *) return 1 ;;
  esac
}

target=$(printf '%s' "$input" | jq -r '.tool_input.file_path // .tool_input.path // empty' 2>/dev/null)

if [ "$tool" = apply_patch ]; then
  patch=$(printf '%s' "$input" | jq -r '
    [ .tool_input.patch?, .tool_input.input?, (.tool_input | strings) ]
    | map(select(type == "string")) | first // empty
  ' 2>/dev/null)
  # Per-file sections: prose targets inside a mixed patch must not be judged as code.
  added=$(printf '%s\n' "$patch" | awk '
    /^\*\*\* [A-Za-z]+ File: / { f = substr($0, index($0, "File: ") + 6); next }
    /^\+/ {
      if (f ~ /\.(md|mdx|markdown|txt|rst)$/) next
      print substr($0, 2)
    }')
  baseline=
else
  is_prose "$target" && exit 0
  added=$(printf '%s' "$input" | jq -r '
    [ .tool_input.new_string?, .tool_input.content?, (.tool_input.edits[]?.new_string) ]
    | map(select(type == "string")) | join("\n")
  ' 2>/dev/null)
  baseline=$(printf '%s' "$input" | jq -r '
    [ .tool_input.old_string?, (.tool_input.edits[]?.old_string) ]
    | map(select(type == "string")) | join("\n")
  ' 2>/dev/null)
  # Write replaces a whole file: everything already on disk is pre-existing, not added.
  if [ "$tool" = Write ] && [ -r "$target" ]; then
    baseline="$baseline
$(cat "$target" 2>/dev/null)"
  fi
fi

[ -n "$added" ] || exit 0

tmp=$(mktemp "${TMPDIR:-/tmp}/devkit-comment-gate.XXXXXX") || exit 0
trap 'rm -f "$tmp"' EXIT HUP INT TERM
printf '%s\n' "$baseline" | grep -v '^[[:space:]]*$' > "$tmp" 2>/dev/null

fresh=$(printf '%s\n' "$added" | grep -Fxv -f "$tmp" 2>/dev/null)
[ -n "$fresh" ] || exit 0

# Comment text only. An inline marker counts when it follows a code boundary
# (whitespace, `;`, `)`, `,`, `}`), which `https://` and `a//b` inside a string never
# do. `#` is a comment marker in scripting languages but a selector in CSS and a
# directive in C, so it is line-anchored and filtered.
markers='(^[[:space:]]*(//|/\*|\*[^/]|#|<!--|--[[:space:]]))|([[:space:];,)}](//|/\*|<!--|--[[:space:]]))'
case "$target" in
  *.css | *.scss | *.less | *.sass) markers='(^[[:space:]]*(/\*|\*[^/]))|([[:space:];,)}]/\*)' ;;
  *.sh | *.bash | *.zsh | *.py | *.rb | *.pl | *.yml | *.yaml | *.tf | *.toml) markers="$markers"'|([[:space:]]#[[:space:]])' ;;
esac
comments=$(printf '%s\n' "$fresh" \
  | grep -E "$markers" \
  | grep -Eiv '^[[:space:]]*#[[:space:]]*(include|define|if|ifdef|ifndef|endif|else|elif|pragma|import|error|undef|!)')
[ -n "$comments" ] || exit 0

word='(^|[^[:alnum:]_])'
ru="${word}(раньше|Раньше|ранее|Ранее|теперь|Теперь|прежде|Прежде|до этого|До этого|было|Было|стало|Стало|добавил|Добавил|удалил|Удалил|убрал|Убрал|заменил|Заменил|переименова|Переименова|отрефактор|Отрефактор)"
en="${word}(previously|formerly|used to be|now we|now it|renamed from|migrated from|moved from|temporary fix|refactored)([^[:alnum:]_]|$)"
en_leading='^[[:space:]]*(//+|#|--|/\*+|\*|<!--)[[:space:]]*(added|updated|changed|removed|renamed|new (function|method|file|helper))([^[:alnum:]_]|$)'

offenders=$(printf '%s\n' "$comments" | grep -E "$ru" | head -n 3)
[ -n "$offenders" ] || offenders=$(printf '%s\n' "$comments" | grep -Ei "$en" | head -n 3)
[ -n "$offenders" ] || offenders=$(printf '%s\n' "$comments" | grep -Ei "$en_leading" | head -n 3)
[ -n "$offenders" ] || exit 0

dir=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd 2>/dev/null)
cat "$dir/comment-gate.txt" 2>/dev/null >&2 \
  || printf '[devkit comment-gate] Comments must not narrate change history — see plugins/core/conduct/code-comments.md.\n' >&2
printf '\nOffending added line(s):\n%s\n' "$offenders" >&2
exit 2

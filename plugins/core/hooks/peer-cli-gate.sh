#!/bin/sh
# peer-cli-gate.sh — PreToolUse hook for peer CLI launches from shell tools.
#
# Refuses `codex exec` / `claude -p` launched without `< /dev/null`. Both read stdin
# for extra input even when the prompt is a positional argument, and a Bash call's
# stdin is a harness socket that never sends a byte and never closes, so the peer
# blocks on "Reading additional input from stdin…" while the tool timeout detaches
# the process instead of killing it.
#
# The gate asks one question — is stdin redirected from /dev/null — rather than
# modelling shell redirection. Adding `< /dev/null` to a peer launch is never
# wrong, so an over-strict refusal costs one harmless token; a shell grammar would cost far more.
#
# Fail-open by design: a missing tool, an oversized command, or anything unparseable
# allows the call. This runs on every Bash call; a false block is worse than a miss.
#
# `codex exec "p" <&-` is refused even though it is safe: the repair the message
# names is equivalent, so the cost is one token. A heredoc-fed launch is exempt
# instead of refused, because there `< /dev/null` would silently eat the prompt.

if [ -t 0 ]; then
  echo "devkit: $(basename "$0") got a terminal on stdin, not a hook payload — not gating this call" >&2
  exit 0
fi

input=$(cat)

command -v jq >/dev/null 2>&1 || exit 0

# One jq pass for both fields. The payload cannot be prefiltered in the shell: it
# carries transcript_path, which lives under ~/.claude, so every Bash call matches
# "claude". Prefilter the extracted command instead — that keeps awk off the calls
# that cannot match, which is the expensive half.
cmd=$(printf '%s' "$input" | jq -r '
  if ((.tool_name // .toolName) as $tool | ["Bash", "Shell", "exec_command", "shell_command"] | index($tool)) != null
  then (.tool_input.command // .toolInput.command // .tool_input.cmd // .toolInput.cmd // .input.command // .input.cmd // "")
  else "" end
' 2>/dev/null)
[ -n "$cmd" ] || exit 0

offender=$(printf '%s\n' "$cmd" | awk '
function trim(s) { sub(/^[ \t\r]+/, "", s); sub(/[ \t\r]+$/, "", s); return s }

function check(t, piped,   w1, w2, base) {
  while (t ~ /^([A-Za-z_][A-Za-z0-9_]*=|(env|nohup|time|command|exec|sudo)[ \t])/) {
    if (!sub(/^[^ \t]+[ \t]+/, "", t)) break
  }
  if (t ~ /(^|[ \t])(-h|--help|--version)([ \t]|$)/) return
  w1 = t; sub(/[ \t].*$/, "", w1)
  base = w1; sub(/^.*\//, "", base)
  if (base == "codex") {
    w2 = t; sub(/^[^ \t]+[ \t]+/, "", w2); sub(/[ \t].*$/, "", w2)
    if (w2 != "exec" && w2 != "e") return       # `codex mcp get exec`, `codex help exec`
  } else if (base == "claude") {
    if (t !~ /(^|[ \t])(-p|--print)([ \t]|$)/) return
  } else if (base == "cursor-agent" || base == "agent" || base == "gemini" || base == "grok") {
    if (t !~ /(^|[ \t])(-p|--print|--prompt|--headless)([= \t]|$)/) return
  } else if (!(base in configured)) return
  if (piped) return                             # stdin comes from the pipeline
  if (t ~ /<</) return                          # a heredoc is the prompt; /dev/null would eat it
  if (found == "") found = base
}

BEGIN {
  MARK = sprintf("%c", 2); hq = 0; hi = 0
  count = split(ENVIRON["DEVKIT_PEER_COMMANDS"], names, ",")
  for (i = 1; i <= count; i++) {
    name = trim(names[i])
    if (name ~ /^[A-Za-z0-9_][A-Za-z0-9_.-]*$/) configured[name] = 1
  }
}

# Drop heredoc bodies: documentation that quotes a peer launch is not a launch.
# Openers are read before quote masking, because the delimiter of the common
# `<<EOF` form would itself be masked away. A `<<EOF` inside a string therefore
# opens a phantom body — that only ever hides a launch, never invents one.
{
  if (hq > hi) {
    t = $0
    if (htab[hi + 1]) sub(/^\t+/, "", t)
    if (t == hd[hi + 1]) hi++
    next
  }
  rest = $0
  gsub(/<<</, "   ", rest)
  while (match(rest, /<<-?[ \t]*[^ \t<>|;&()]+/)) {
    tok = substr(rest, RSTART, RLENGTH)
    rest = substr(rest, RSTART + RLENGTH)
    dash = (tok ~ /^<<-/)
    sub(/^<<-?[ \t]*/, "", tok)
    gsub(/['\''"\\]/, "", tok)
    if (tok != "") { hq++; hd[hq] = tok; htab[hq] = dash }
  }
  buf = buf $0 "\n"
}

END {
  if (index(buf, MARK) > 0) exit                # a literal marker byte: give up rather than misparse

  # Blank out quoted spans in one left-to-right pass, so a separator, a "#" or a
  # "/dev/null" inside a prompt string is not read as shell syntax.
  s = buf
  # A literal regex, not a computed one: backslash handling inside a dynamic
  # regex string is where BWK, mawk and gawk diverge, and a silent divergence
  # here brings back the false-positive class this masking exists to prevent.
  gsub(/'\''[^'\'']*'\''|"(\\.|[^"\\])*"/, " Q ", s)
  gsub(/[ \t\n]#[^\n]*/, " ", s)
  sub(/^#[^\n]*/, "", s)

  if (s ~ /<[ \t]*\/dev\/null/) exit           # stdin is accounted for; nothing to say

  gsub(/\|\|/, "\n", s)
  gsub(/\|&/, "\n" MARK " ", s)
  gsub(/\|/, "\n" MARK " ", s)
  gsub(/[;&(){}]/, "\n", s)

  n = split(s, chunk, "\n")
  piped = 0
  for (j = 1; j <= n; j++) {
    t = trim(chunk[j])
    if (substr(t, 1, 1) == MARK) { piped = 1; t = trim(substr(t, 2)) }
    if (t == "") continue                       # a blank chunk keeps the pipeline state
    check(t, piped)
    piped = 0
  }
  if (found != "") print found
}
')

[ -n "$offender" ] || exit 0

case "$offender" in
  claude) fix='claude -p "$(cat /path/to/prompt.md)" < /dev/null' ;;
  codex) fix='codex exec -m <model> "$(cat /path/to/prompt.md)" < /dev/null' ;;
  *) fix="$offender <existing arguments> < /dev/null" ;;
esac

cat >&2 <<EOF
devkit: this \`$offender\` launch would inherit the harness stdin socket and hang.

Give a non-interactive peer either explicit prompt input or closed stdin. An agent
shell tool can keep inherited stdin open after its timeout, leaving the peer waiting.

Re-run with stdin closed:

  $fix

Write the prompt file in a separate Bash call first. A heredoc in the same compound
command as the launch is the usual cause.
EOF
exit 2

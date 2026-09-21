#!/usr/bin/env bash
# Covers plugins/core/hooks/peer-cli-gate.sh. The gate runs on every Bash call, so
# the allow cases matter more than the block cases — a false positive costs the user
# a working command, a false negative costs one detached process. Every case below
# that is marked (codex) was a reproduced defect in the first implementation.

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOOK="$ROOT/plugins/core/hooks/peer-cli-gate.sh"
failures=0

fail() {
  echo "FAIL: $*" >&2
  failures=$((failures + 1))
}

# want=2 blocks, want=0 allows.
probe() {
  local want="$1" desc="$2" cmd="$3" tool="${4:-Bash}"
  local payload rc
  payload=$(jq -Rn --arg c "$cmd" --arg t "$tool" '{tool_name:$t,tool_input:{command:$c}}')
  printf '%s' "$payload" | sh "$HOOK" >/dev/null 2>&1
  rc=$?
  [ "$rc" = "$want" ] || fail "$desc: exit $rc, wanted $want"
}

# --- launches that would hang -------------------------------------------------
probe 2 'bare codex exec'               'codex exec -m gpt-5.6-sol "review this"'
probe 2 'after cd &&'                   'cd /tmp && codex exec "prompt here"'
probe 2 'prompt is a command subst'     'codex exec "$(cat /tmp/p.md)"'
probe 2 'semicolon inside the prompt'   'codex exec "do A; then B"'
probe 2 'angle bracket inside prompt'   'codex exec "fix <Foo> in bar"'
probe 2 'backgrounded with 2>&1'        'codex exec "p" > /tmp/o 2>&1 &'
probe 2 'absolute path to codex'        '/opt/homebrew/bin/codex exec "p"'
probe 2 'env assignment prefix'         'RUST_LOG=info codex exec "p"'
probe 2 'claude -p'                     'claude -p "summarize"'
probe 2 'claude --print'                'claude --print "summarize"'
probe 2 'claude, extra spaces'          'claude   -p "p"'                    # (codex)
probe 2 'claude, option before -p'      'claude --model sonnet -p "p"'       # (codex)
probe 2 'codex e alias'                 'codex e "p"'                        # (codex)
probe 2 'redirect on fd 3, not fd 0'    'codex exec "p" 3</tmp/context'      # (codex)
probe 2 'inside command substitution'   'reply=$(codex exec "p")'            # (codex)
probe 2 'after || is not a pipe'        'false || codex exec "p"'            # (codex)
probe 2 'codex head of a pipeline'      'codex exec "p" | tee /tmp/log'
probe 2 '/dev/null inside the prompt'   'codex exec "send the log to /dev/null"'
probe 2 'output, not stdin, to null'    'codex exec "p" > /dev/null 2>&1 &'
probe 2 'prompt quotes the redirect'   'codex exec "always add < /dev/null"'

# --- launches whose stdin is accounted for ------------------------------------
probe 0 'stdin closed'                  'codex exec -m sol "review" < /dev/null'
probe 0 'stdin closed, no space'        'codex exec "p" </dev/null'
probe 0 'closed, then 2>&1, then bg'    'codex exec "p" < /dev/null > /tmp/o 2>&1 &'
probe 0 'closed after 2>&1'             'codex exec "p" > /tmp/o 2>&1 < /dev/null'
probe 0 'piped into codex'              'cat /tmp/p.md | codex exec -m sol'
probe 0 'pipe across a newline'         $'cat /tmp/p.md |\n  codex exec "p"'  # (codex)
probe 0 '|& pipe'                       'cat /tmp/p.md |& codex exec "p"'     # (codex)
probe 0 'redirect on an enclosing group' '{ codex exec "p"; } < /dev/null'    # (codex)
probe 0 'heredoc feeds the launch'      $'codex exec "p" <<EOF\nextra\nEOF'

# --- commands that merely mention a peer CLI ----------------------------------
probe 0 'heredoc body quotes a launch'  $'cat > /tmp/d.md <<EOF\nAlways run codex exec "x"\nEOF'
probe 0 'quoted heredoc body'           $'cat > /tmp/d.md <<\'EOF\'\ncodex exec "x"\nEOF'
probe 0 'body ends with a spaced term'  $'cat <<EOF\n EOF\ncodex exec "body"\nEOF'          # (codex)
probe 0 'two heredocs on one line'      $'cat <<A <<B\nfirst\nA\ncodex exec "second"\nB'    # (codex)
probe 0 'comment tail'                  'true # note; codex exec "p"'                      # (codex)
probe 0 'codex exec --help'             'codex exec --help'                                # (codex)
probe 0 'codex help exec'               'codex help exec'                                  # (codex)
probe 0 'codex mcp get exec'            'codex mcp get exec'                               # (codex)
probe 0 'codex --version'               'codex --version'
probe 0 'claude without -p'             'claude mcp list'
probe 0 'codex only as a path'          'grep -rn codex adapters/codex/generate'
probe 0 'dot-claude in a path'          'ls ~/.claude/agentic-devkit && echo codex'
probe 0 'not the Bash tool'             'codex exec "p"' 'Read'
probe 0 'unrelated command'             'git status --porcelain'

# The refusal must reach the model on stderr, and must name the repair for the CLI
# that was actually launched — stdout stays empty so nothing is mistaken for output.
for pair in 'codex exec "p"|codex exec' 'claude -p "p"|claude -p'; do
  cmd=${pair%%|*}; want=${pair##*|}
  payload=$(jq -Rn --arg c "$cmd" '{tool_name:"Bash",tool_input:{command:$c}}')
  err=$(printf '%s' "$payload" | sh "$HOOK" 2>/tmp/devkit-pcg-err.$$ >/tmp/devkit-pcg-out.$$; cat /tmp/devkit-pcg-err.$$)
  [ -s /tmp/devkit-pcg-out.$$ ] && fail "$cmd: the refusal wrote to stdout"
  printf '%s' "$err" | grep -q -- "$want .*< /dev/null" || fail "$cmd: refusal does not show the '$want' repair"
  rm -f /tmp/devkit-pcg-err.$$ /tmp/devkit-pcg-out.$$
done

# A pathological command must not stall the Bash tool it gates.
big=$(python3 -c 'import json;print(json.dumps({"tool_name":"Bash","tool_input":{"command":"codex exec "+"x"*1000000}}))')
start=$(python3 -c 'import time;print(time.time())')
printf '%s' "$big" | sh "$HOOK" >/dev/null 2>&1
python3 -c "
import sys, time
elapsed = time.time() - $start
print('  1 MiB command: %.2f s' % elapsed)
sys.exit(1 if elapsed > 3 else 0)
" || fail "a 1 MiB command took too long to classify"

# Fail open on garbage rather than blocking every Bash call.
printf 'not json at all, codex exec' | sh "$HOOK" >/dev/null 2>&1
[ $? = 0 ] || fail "an unparseable payload must fail open"

# A terminal on stdin is never a hook payload; it must not make `cat` block. Driven
# through pty.spawn rather than `script`, whose argument order differs between the
# BSD and util-linux builds — the containers ship the latter.
python3 - "$HOOK" <<TTY >/dev/null 2>&1
import os, pty, signal, sys
signal.signal(signal.SIGALRM, lambda *a: os._exit(70))
signal.alarm(10)
sys.exit(os.waitstatus_to_exitcode(pty.spawn(["sh", sys.argv[1]])))
TTY
[ $? = 0 ] || fail "a tty on stdin must exit 0"

[ "$failures" = 0 ] || exit 1
echo "peer-cli-gate: all checks passed"

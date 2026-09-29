#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
JEV="$ROOT/plugins/core/skills/jev/scripts/jev.py"
TMP="$(mktemp -d)"
SERVER_PID=""
trap '[ -n "$SERVER_PID" ] && { kill "$SERVER_PID"; wait "$SERVER_PID" || true; } 2>/dev/null; rm -rf "$TMP"' EXIT

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

PYTHONPYCACHEPREFIX="$TMP/pyc" python3 -m py_compile "$JEV" || fail "jev.py does not compile"

export XDG_STATE_HOME="$TMP/state"
export JEV_API_KEY="test-key"
unset JEV_MODEL JEV_KEY_FILE

expect_refusal() {
  local request="$1" pattern="$2" err
  if err=$(printf '%s' "$request" | JEV_BASE_URL="http://127.0.0.1:9" "$JEV" ask - 2>&1); then
    fail "accepted an invalid request: $request"
  fi
  printf '%s\n' "$err" | grep -q "$pattern" || fail "wrong refusal for $request: $err"
}

expect_refusal '{"questions":{"a":{"type":"noul","instructions":"q"}}}' 'non-empty state'
expect_refusal '{"state":"s","questions":{}}' 'non-empty questions'
expect_refusal '{"state":"s","questions":{"a":{"type":"bool","instructions":"q"}}}' 'choice, score or noul'
expect_refusal '{"state":"s","questions":{"a":{"type":"noul","instructions":" "}}}' 'instructions must be non-empty'
expect_refusal '{"state":"s","questions":{"a":{"type":"choice","instructions":"q","criteria":{"x":"only"}}}}' 'at least two options'
expect_refusal '{"state":"s","questions":{"a":{"type":"score","instructions":"q","criteria":["1","2","3","4","5","6","7","8","9","10","11"]}}}' '2-10 levels'

if err=$(printf '{"state":"s","questions":{"a":{"type":"noul","instructions":"q"}}}' \
  | env -u JEV_API_KEY JEV_KEY_FILE="$TMP/missing" "$JEV" ask - 2>&1); then
  fail "ran without an API key"
fi
printf '%s\n' "$err" | grep -q 'no API key' || fail "missing key not reported: $err"

cat > "$TMP/server.py" <<'PY'
import json
import sys
from http.server import BaseHTTPRequestHandler, HTTPServer

class Handler(BaseHTTPRequestHandler):
    def do_POST(self):
        payload = json.loads(self.rfile.read(int(self.headers["Content-Length"])))
        assert self.path == "/v1/systemone", self.path
        assert self.headers["Authorization"] == "Bearer test-key"
        items = payload["state"].get("items") or payload["state"]["blocks"]
        answers = {name: {"type": "noul", "noul": 0.9 if "needle" in items[name] else 0.1}
                   for name in payload["questions"]}
        body = json.dumps({"model": payload["model"], "answers": answers,
                           "usage": {"input_tokens": 100}}).encode()
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, *args):
        pass

server = HTTPServer(("127.0.0.1", 0), Handler)
print(server.server_port, flush=True)
server.serve_forever()
PY
python3 "$TMP/server.py" > "$TMP/port" &
SERVER_PID=$!
for _ in $(seq 50); do [ -s "$TMP/port" ] && break; sleep 0.1; done
export JEV_BASE_URL="http://127.0.0.1:$(cat "$TMP/port")"

out=$(printf 'alpha\nthe needle line\nbeta\n' | "$JEV" filter --task "find the needle" 2>"$TMP/stderr")
[ "$out" = "the needle line" ] || fail "filter kept the wrong lines: $out"
grep -q 'kept 1/3 lines' "$TMP/stderr" || fail "filter summary missing: $(cat "$TMP/stderr")"

out=$(printf 'alpha\nbeta\n' | "$JEV" filter --task "find the needle" 2>"$TMP/stderr")
[ -z "$out" ] || fail "filter kept lines below the threshold: $out"
grep -q 'best score 0.10' "$TMP/stderr" || fail "empty result does not report the best score"

seq 1 400 | sed 's/^/line /' | "$JEV" filter --task "t" --chunk-chars 2000 >/dev/null 2>"$TMP/stderr"
grep -q 'kept 0/400 lines' "$TMP/stderr" || fail "chunked filter lost lines: $(cat "$TMP/stderr")"

{ for i in $(seq 1 60); do echo "filler line $i"; done; echo; echo "def target():"; echo "    return 'needle'"; echo; for i in $(seq 1 60); do echo "more filler $i"; done; } > "$TMP/big.py"
out=$("$JEV" locate "$TMP/big.py" --task "find the needle" 2>"$TMP/stderr")
printf '%s\n' "$out" | grep -q "big.py:.*0.90" || fail "locate did not rank the needle block: $out"
[ "$(printf '%s\n' "$out" | wc -l | tr -d ' ')" = "1" ] || fail "locate kept blocks below the threshold: $out"
grep -q 'best score 0.90' "$TMP/stderr" || fail "locate summary missing: $(cat "$TMP/stderr")"

calls=$("$JEV" usage | python3 -c 'import json,sys; print(json.load(sys.stdin)["calls"])')
[ "$calls" -gt 3 ] || fail "usage log did not record the calls: $calls"

echo "jev skill tests passed"

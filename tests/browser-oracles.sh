#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROBE="$ROOT/plugins/core/skills/browser/scripts/ui-oracles.js"
CONDUCT="$ROOT/plugins/core/conduct/browser-ui-oracles.md"
FIXTURE="$ROOT/tests/fixtures/ui-oracles.html"

fail() { echo "FAIL: $*" >&2; exit 1; }

[ -f "$PROBE" ] || fail "missing $PROBE"
[ -f "$FIXTURE" ] || fail "missing $FIXTURE"
grep -Fq 'plugins/core/skills/browser/scripts/ui-oracles.js' "$CONDUCT" || fail "conduct no longer points at the probe"
head -c 1 "$PROBE" | grep -q '(' || fail "probe must start with its parameter list so it pastes as one expression"
for key in rhythm boundaries surfaces repeated alignment transport mute navigation groups primaries; do
  grep -Fq "want(\"$key\")" "$PROBE" || fail "probe lost oracle key: $key"
  grep -Fq "\`$key\`" "$CONDUCT" || fail "conduct does not document oracle key: $key"
done

command -v node >/dev/null 2>&1 || fail "node is required to parse the probe (every supported harness ships it)"
node -e 'const s=require("fs").readFileSync(process.argv[1],"utf8"); if (typeof new Function("return ("+s+")")() !== "function") process.exit(1);' "$PROBE" \
  || fail "probe does not parse as a single function expression"

chrome=""
for c in "${CHROME:-}" "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" google-chrome google-chrome-stable chromium chromium-browser; do
  [ -n "$c" ] || continue
  if [ -x "$c" ] || command -v "$c" >/dev/null 2>&1; then chrome="$c"; break; fi
done
if [ -z "$chrome" ]; then
  if [ "${BROWSER_ORACLES_SKIP:-}" = "1" ]; then
    echo "browser-oracles: SKIPPED by BROWSER_ORACLES_SKIP=1 — structure and syntax only, defect fixture not run"
    exit 0
  fi
  fail "no Chrome/Chromium to run the defect fixture (set CHROME=<path>, or BROWSER_ORACLES_SKIP=1 to skip explicitly)"
fi

tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
python3 - "$FIXTURE" "$PROBE" "$tmp/fixture.html" <<'PY'
import sys, pathlib
fixture, probe, out = (pathlib.Path(p) for p in sys.argv[1:])
html = fixture.read_text()
assert "/*PROBE*/" in html
out.write_text(html.replace("/*PROBE*/", probe.read_text().strip()))
PY
node - "$chrome" "file://$tmp/fixture.html" "$tmp" > "$tmp/result.json" <<'JS' || fail "headless Chrome did not produce a fixture result"
const { spawn } = require("child_process");
const [chrome, url, dir] = process.argv.slice(2);
const args = ["--headless=new", "--disable-gpu", "--no-first-run", "--no-default-browser-check", "--hide-scrollbars",
  "--window-size=1200,900", `--user-data-dir=${dir}/profile`, "--remote-debugging-port=0", url];
if (process.getuid && process.getuid() === 0) args.push("--no-sandbox");
const proc = spawn(chrome, args, { stdio: ["ignore", "ignore", "pipe"] });
const done = code => { if (proc.exitCode !== null) process.exit(code); proc.once("exit", () => process.exit(code)); try { proc.kill("SIGTERM"); } catch (e) {} setTimeout(() => process.exit(code), 5000); };
setTimeout(() => { console.error("timeout"); done(2); }, 30000);
let buf = "";
proc.stderr.on("data", async d => {
  buf += d; const m = buf.match(/DevTools listening on (ws:\/\/[^\s]+)/); if (!m || proc.started) return; proc.started = true;
  const port = new URL(m[1]).port;
  for (let i = 0; i < 100; i++) {
    const pages = await (await fetch(`http://127.0.0.1:${port}/json/list`)).json();
    const page = pages.find(p => p.type === "page" && p.url.startsWith("file:"));
    if (page) {
      const ws = new WebSocket(page.webSocketDebuggerUrl);
      await new Promise(r => ws.addEventListener("open", r, { once: true }));
      const ask = expr => new Promise(r => { const id = Math.floor(Math.random() * 1e9);
        const h = ev => { const msg = JSON.parse(ev.data); if (msg.id === id) { ws.removeEventListener("message", h); r(msg.result); } };
        ws.addEventListener("message", h); ws.send(JSON.stringify({ id, method: "Runtime.evaluate", params: { expression: expr, returnByValue: true } })); });
      for (let j = 0; j < 100; j++) {
        const res = await ask('(document.getElementById("qa-result") || {}).textContent || ""');
        const v = res && res.result && res.result.value;
        if (v) { process.stdout.write(v); ws.close(); return done(0); }
        await new Promise(r => setTimeout(r, 100));
      }
      ws.close(); return done(3);
    }
    await new Promise(r => setTimeout(r, 100));
  }
  done(4);
});
proc.on("exit", () => { if (!proc.started) process.exit(5); });
JS

python3 - "$tmp/result.json" <<'PY'
import sys, json
raw = open(sys.argv[1], encoding="utf-8").read().strip()
if not raw:
    sys.exit("FAIL: fixture produced no result")
res = json.loads(raw)
if "probe_threw" in res:
    sys.exit("FAIL: probe threw: " + res["probe_threw"])
bad = [k for k, v in res.items() if v is not True]
if bad:
    sys.exit("FAIL: oracle checks failed: " + ", ".join(bad))
print(f"browser-oracles: ok ({len(res)} defect/clean checks)")
PY

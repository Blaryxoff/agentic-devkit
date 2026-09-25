#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIR="$ROOT/plugins/core/skills/timesheet"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

for f in SKILL.md references/sources.md references/method.md references/report-format.md assets/timesheet.example.json \
  scripts/extract_sessions.py scripts/hermes_dump.py scripts/browser_history.py scripts/timeline.py scripts/allocate.py \
  scripts/render.py; do
  [ -f "$DIR/$f" ] || fail "missing $f"
done
for f in "$DIR"/scripts/*.py; do
  PYTHONPYCACHEPREFIX="$TMP/pyc" python3 -m py_compile "$f" || fail "does not compile: $f"
done

python3 - "$DIR/SKILL.md" <<'PY'
from pathlib import Path
import sys
import yaml

text = Path(sys.argv[1]).read_text()
_, front, body = text.split("---\n", 2)
meta = yaml.safe_load(front)
assert meta["name"] == "devkit-timesheet"
desc = " ".join(meta["description"].lower().split())
for needle in ("отчёт по затраченному времени", "timesheet", "devkit-estimate", "devkit-sprint", "pdf"):
    assert needle in desc, needle
body = " ".join(body.lower().split())
for rule in ("count only the person's own time", "parallel sessions count once", "never invent a number",
             "other clients never appear", "kill only processes you started"):
    assert rule in body, rule
PY

python3 - "$DIR/assets/timesheet.example.json" "$TMP" <<'PY'
import json, sys
cfg = json.load(open(sys.argv[1]))
tmp = sys.argv[2]
cfg["period"] = {"from": "2026-09-01", "to": "2026-09-02"}
cfg["transcript_cutoff"] = "2026-09-01"
cfg["tz_offset_hours"] = 0
cfg["vacation"] = []
json.dump(cfg, open(f"{tmp}/cfg.json", "w"))
s = lambda sid, cwd, prompts: {"tool": "t", "id": sid, "cwd": cwd, "entry": "human", "branches": [], "bhits": [], "prompts": prompts}
rows = [
    # two parallel target sessions over the same hour must count once
    s("a", "/u/www/acme-platform", [["2026-09-01T10:00:00Z", "fix alpha redesign"], ["2026-09-01T10:20:00Z", "continue alpha redesign"], ["2026-09-01T10:40:00Z", "alpha redesign done"]]),
    s("b", "/u/www/acme-platform", [["2026-09-01T10:10:00Z", "beta renewal"], ["2026-09-01T10:30:00Z", "beta renewal again"]]),
    # another client in parallel never adds target time
    s("c", "/u/www/otherclient", [["2026-09-01T11:30:00Z", "other client work"]]),
    # machine-injected text is not a prompt
    s("d", "/u/www/acme-platform", [["2026-09-02T09:00:00Z", "<task-notification> done"]]),
    # bot dumps carry a slash-free cwd and still attribute by content
    s("e", "hermes", [["2026-09-02T12:00:00Z", "check beta renewal on stage"]]),
]
with open(f"{tmp}/sessions.jsonl", "w") as o:
    for r in rows:
        o.write(json.dumps(r) + "\n")
PY

S="$DIR/scripts"
python3 "$S/timeline.py" --config "$TMP/cfg.json" --sessions "$TMP/sessions.jsonl" --out "$TMP/out" >/dev/null
python3 "$S/allocate.py" --config "$TMP/cfg.json" --in "$TMP/out" --out "$TMP/out/report.json" >/dev/null
python3 "$S/render.py" --config "$TMP/cfg.json" --report "$TMP/out/report.json" --out "$TMP/out" >/dev/null

python3 - "$TMP/out" <<'PY'
import json, sys
out = sys.argv[1]
hours = json.load(open(f"{out}/hours.json"))
total = sum(sum(v.values()) for v in hours.values())
# 10:00-10:55 union (last prompt of session a at 10:40 + 15 min tail) = 55 min, not the 90 min a per-session sum gives,
# plus the 15 min tail of the bot message
assert abs(total - 70 / 60) < 0.02, total
assert set(hours) == {"Alpha", "Beta"}, hours
report = json.load(open(f"{out}/report.json"))
for p in report["projects"]:
    assert sum(h for _, h in p["bullets"]) == p["total"], p
    assert sum(p["months"].values()) == p["total"], p
assert sum(p["total"] for p in report["projects"]) == report["total"]
md = open(f"{out}/report.md").read()
assert "otherclient" not in md.lower()
PY

python3 - "$TMP" <<'PY'
import json, sys
tmp = sys.argv[1]
cfg = json.load(open(f"{tmp}/cfg.json"))
cfg["vacation"] = [["2026-09-01", "2026-09-02"]]
cfg["chrome_binary"] = "/usr/bin/true"
json.dump(cfg, open(f"{tmp}/cfg0.json", "w"))
PY
mkdir -p "$TMP/out0"
python3 "$S/allocate.py" --config "$TMP/cfg0.json" --in "$TMP/out" --out "$TMP/out0/report.json" >/dev/null
python3 "$S/render.py" --config "$TMP/cfg0.json" --report "$TMP/out0/report.json" --out "$TMP/out0" >/dev/null 2>&1 ||
  fail "render crashes on a zero-hour norm"
if python3 "$S/render.py" --config "$TMP/cfg0.json" --report "$TMP/out0/report.json" --out "$TMP/out0" \
  --pdf "$TMP/out0/r.pdf" >/dev/null 2>&1; then
  fail "render reports success when no PDF was written"
fi

echo "timesheet skill: ok"

#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILL="$ROOT/plugins/core/skills/estimate/SKILL.md"
REFERENCE="$ROOT/plugins/core/skills/estimate/references/agent-first-calibration.md"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

[ -f "$SKILL" ] || fail "estimate skill is missing"
[ -f "$REFERENCE" ] || fail "estimate calibration reference is missing"

python3 - "$SKILL" "$REFERENCE" <<'PY'
from pathlib import Path
import sys
import yaml

skill = Path(sys.argv[1]).read_text()
reference = Path(sys.argv[2]).read_text()
assert skill.startswith("---\n")
_, frontmatter, body = skill.split("---\n", 2)
metadata = yaml.safe_load(frontmatter)
assert metadata["name"] == "devkit-estimate"

description = " ".join(metadata["description"].lower().split())
for trigger in (
    "estimate this task",
    "how long will this take",
    "agent-first",
    "vibe-coding",
):
    assert trigger in description, trigger
assert "devkit-sprint" in description
assert "does not implement" in description
assert "direct paste" in description

normalized_body = " ".join(body.lower().split())
for rule in (
    "one high-context operator with up to three parallel coding agents",
    "demo",
    "alpha",
    "beta",
    "production-ready",
    "exact`, `continuation`, `foundation`, `adjacent`, or `absent",
    "use the dependency graph, not the arithmetic sum",
    "longest parallel implementation path",
    "never infer coding duration from loc",
    "they never convert to duration",
    "prior estimate of this or an adjacent scope",
    "never average a superseded estimate into the new one",
    "name one delivered anchor slice and express the new scope as a ratio to it",
    "the anchor is a ceiling, not a footnote",
    "the production-ready high case does not exceed the anchor's own span",
    "each blocker carries its own day cost on its own line",
    "anchor span + sum of blocker costs",
    "never report a ratio below 1.0 alongside a schedule above the anchor",
    "the anchor line — the named delivered slice, its calendar span, and the new scope's ratio to it",
    "the base scenario is the scope exactly as the user wrote it",
    "never make the expansive reading the headline number",
    "no figure on the schedule was produced by multiplying another figure",
    "never reach a production figure by scaling demo, alpha, or beta by a factor",
    "skip this step entirely when a credible local anchor exists",
    "elapsed low/likely/high",
    "pack ready lanes into explicit execution waves",
    "never append a free-floating day allowance",
    "never append its table to the audience-ready estimate",
    "vendor case studies as evidence for achievable demo/mvp speed",
    "do not create a report file unless the user asked for one",
    "return only the audience-ready estimate",
    "for telegram or chat",
    "do not use markdown tables",
    "never emit markdown horizontal rules",
    "decorative dash-divider lines",
    "../../conduct/readiness-gate.md",
):
    assert rule in normalized_body, rule

normalized_reference = " ".join(reference.lower().split())
for banned in (
    "seven times the build",
    "hardening tail was roughly",
):
    assert banned not in normalized_reference, banned
for rule in (
    "never multiply, scale, or apply a percentage from this page",
    "do not calibrate a scope classified mostly `exact`, `continuation`, or `foundation` from this page",
    "never as a tail proportional to the build",
):
    assert rule in normalized_reference, rule
for source in (
    "lovable.dev/blog/how-nursa-built-a-new-product-in-48-hours",
    "replit.com/blog/building-mobile-apps-on-replit",
    "anthropic.com/research/claude-code-expertise",
    "metr.org/time-horizons",
    "metr.org/blog/2026-02-24-uplift-update",
    "metr.org/blog/2025-07-10-early-2025-ai-experienced-os-dev-study",
    "cloud.google.com/blog/products/ai-machine-learning/announcing-the-2025-dora-report",
    "arxiv.org/abs/2607.04697",
    "arxiv.org/abs/2605.22534",
    "gitclear.com/the_ai_code_quality_maintainability_gap",
):
    assert source in normalized_reference, source
for guardrail in (
    "never derive a fixed",
    "vendor-authored",
    "local high-context delivery evidence remains primary",
    "do not use for: multiplying a traditional person-day estimate",
):
    assert guardrail in normalized_reference, guardrail

print("estimate skill tests passed")
PY

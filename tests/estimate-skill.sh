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
    "the base scenario is the scope exactly as the user wrote it",
    "default to one coding lane",
    "work already delivered contributes zero days",
    "never add the analogue's span to the new schedule, and never treat it as a floor",
    "do not price invented blockers to justify the gap",
    "the base scenario is the scope exactly as the user wrote it, and it carries the recommendation",
    "never headline an expansion the user did not request",
    "schedule only work the literal text asks for",
    "the ladder collapses",
    "include a gate below only when this change actually touches it",
    "reuse existing authorization, idempotency, observability, and rollout mechanisms and schedule zero days",
    "belong to the internal worksheet, never to the delivered text",
    "omit source paths, line numbers, commit and session ids",
    "a high-context maintainer's scoped statement about this codebase",
    "no day in the schedule pays for behavior that already exists in the repository",
    "never reach a production figure by scaling demo, alpha, or beta by a factor",
    "skip this step entirely when a credible local anchor exists",
    "elapsed low/likely/high",
    "pack ready lanes into explicit execution waves",
    "never append a free-floating day allowance",
    "never append its table to the audience-ready estimate",
    "vendor case studies as evidence for achievable demo/mvp speed",
    "do not create a report file unless the user asked for one",
    "return only the audience-ready estimate",
    "the reader approves schedules and cuts scope; they do not read code",
    "lead with one recommended planning commitment: one number, one scope, one maturity level",
    "never bolded beside the headline",
    "**what the number means.**",
    "elapsed time is not how long a person is occupied",
    "give operator occupancy as its own figure, itemized",
    "residual per-day supervision while agents run",
    "always report operator load beside the calendar schedule",
    "compute operator occupancy alongside elapsed time",
    "say it to the reader as",
    "releasable to users. automated checks cover the flows, access rights, data migrations",
    "runs at full load unattended. adds checks under heavy load and failure, monitoring, and a rollback",
    "say which levels are releasable and whether hardening can run as a separate later phase",
    "**what the number covers.**",
    "name testing, review, qa, and rollout per level in the reader's words",
    "the maturity levels table's third column is that wording",
    "a reader who cannot find testing in an estimate assumes it was omitted",
    "**ways to shorten it.** mandatory whenever any scope item can be deferred",
    "name the capability, not the lane",
    "gloss or replace every engineering term on first use",
    "name what changed and why the number moved",
    "the headline is one number, for one scope, at one maturity level",
    "the unit is stated once and held throughout",
    "operator occupancy is reported next to elapsed time, is itemized, and is not a fraction of it",
    "at least one way to shorten the schedule is offered whenever any scope item can be deferred",
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

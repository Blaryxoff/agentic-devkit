#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILL="$ROOT/plugins/core/skills/estimate/SKILL.md"
REFERENCE="$ROOT/plugins/core/skills/estimate/references/agent-first-calibration.md"
MATURITY="$ROOT/plugins/core/skills/estimate/references/maturity-levels.md"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

[ -f "$SKILL" ] || fail "estimate skill is missing"
[ -f "$REFERENCE" ] || fail "estimate calibration reference is missing"
[ -f "$MATURITY" ] || fail "estimate maturity reference is missing"

python3 - "$SKILL" "$REFERENCE" "$MATURITY" <<'PY'
from pathlib import Path
import sys
import yaml

skill = Path(sys.argv[1]).read_text()
reference = Path(sys.argv[2]).read_text()
maturity = Path(sys.argv[3]).read_text()
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
normalized_maturity = " ".join(maturity.lower().split())
normalized_rules = f"{normalized_body} {normalized_maturity}"
for rule in (
    "demo",
    "alpha",
    "beta",
    "production-ready",
    "exact`, `continuation`, `foundation`, `adjacent`, or `absent",
    "the dependency graph, not the arithmetic sum of lane estimates",
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
    "no hour in the schedule pays for behavior that already exists in the repository",
    "never reach a production figure by scaling demo, alpha, or beta by a factor",
    "estimate both in hours, low/likely/high",
    "pack ready lanes into explicit execution waves",
    "never append a free-floating allowance",
    "never append its table to the audience-ready estimate",
    "do not create a report file unless the user asked for one",
    "return only the audience-ready estimate",
    "the reader approves schedules and cuts scope; they do not read code",
    "be brief: the whole estimate fits on one screen",
    "length is not thoroughness",
    "say it to the reader as",
    "releasable to users. automated checks cover the flows, access rights, data migrations",
    "runs at full load unattended. adds checks under heavy load and failure, monitoring, and a rollback",
    "testing, review, qa, and rollout per level in the reader's words",
    "the maturity levels table's third column is that wording",
    "checklists are an appendix at most and usually omitted outright",
    "one line each: the user-facing capability to",
    "gloss or replace every engineering term on first use",
    "name what changed and why the number moved",
    "for telegram or chat",
    "never emit markdown horizontal rules",
    "decorative dash-divider lines",
    "when elapsed is included, say whether hardening can run as a separate later phase",
    "**what they cover.**",
    "give the opening table as one bullet per row",
    "estimate developer working hours first as low/likely/high",
    "agent runtime is never developer time — agents run all night while the developer sleeps",
    "derive calendar elapsed second only when it helps planning",
    "developer time is computed from those lanes, never inferred from the calendar schedule as a fraction of it",
    "| lane | scope | reuse | prerequisites | developer hours | elapsed | done evidence |",
    "### 5. calculate developer time, then elapsed",
    "sum the rows; count one session once",
    "report developer working hours first. add elapsed only when the user asks for a delivery window",
    "report developer time in hours, always, and lead with it",
    "every delta and every cut is quoted in developer hours first",
    "hours are schedulable; \"about a week\" is not a commitment",
    "when elapsed is useful, label it as wall-clock",
    "| level | developer time | what you can do with it |",
    "add an `elapsed` column only when the estimate includes a delivery window",
    "**where the developer's hours go.**",
    "say that unattended test and ci runtime costs the developer nothing",
    "**ways to cut it.** mandatory when any scope item can be deferred",
    "the developer hours it frees, and the elapsed it buys — stated as zero when off the critical path",
    "every cut quotes the developer hours it frees, and says plainly when it does not move the date",
    "derive lanes from the artifacts this change actually produces, never from a checklist of layers",
    "is one lane, however many layers it crosses",
    "price a lane by what resists an agent",
    "a long list of such rows is one lane priced once, never a lane per row",
    "never print a level and disclaim it in the same breath",
    "the reader quotes the number, not the caveat",
    "recorded as the anchor's delivered span",
    "when the reader disputes a figure, re-derive the decomposition before answering",
    "defending a number you have not recomputed is the failure",
    "each lane names the artifact it produces",
    "report a level above demo only when you can name the work it adds over the level below",
    "give each row low/likely/high hours and evidence",
    "passive agent, test, and ci runtime costs zero",
    "calibrate developer hours only from anchors that record actual developer hours",
    "without an actual-hours anchor, use the bottom-up ledger below and cap confidence at `medium`",
    "build a developer-hour ledger with one row per attended session",
    "count one session once when it covers review, integration, and acceptance",
    "do not estimate agent-work unless the user asks for cost or capacity",
    "default to one recommended row for the literal requested outcome",
    "never print demo, alpha, beta, and production-ready by default",
    "a lane that runs longer unattended costs no more developer hours",
    "developer hours are the lane's attended human work",
    "elapsed is its wall-clock, including waiting and unattended runtime",
    "developer hours go where the work needs the developer's own judgement",
    "two things cost elapsed time without costing developer hours",
    "charge only the developer's own coordination on those",
    "| developer cost | the anchor's actual developer hours, when the record shows them |",
    "any excess over the anchor's developer hours, and then over its delivered span",
    "open with one table carrying the schedule figures",
    "no figure in it is restated in the prose below",
    "cuts and deltas carry their own numbers on their own lines; they never go in the table",
    "../../conduct/readiness-gate.md",
):
    assert rule in normalized_rules, rule

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

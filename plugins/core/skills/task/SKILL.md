---
name: devkit-task
description: >-
  carry a whole task specification from text to a pushed branch with a peer CLI — freeze the spec, analyse it in
  parallel with the peer, implement natively, run an adversarial review/fix loop (revmux when authorized, else Codex),
  delegate browser QA to the peer, then wrapup. Manual trigger ONLY: load it when the operator hands over a task
  specification and names the pipeline — "прогони по процессу", "ship this spec", "work it with codex end to end",
  "/task", "full pipeline". A bare feature request is NOT a trigger — that is devkit-core--coder. Does NOT deploy and
  does NOT open PRs. Stage owners are fixed by the table in this file, never inferred from the operator's phrasing.
---

# Task Pipeline

> Paths like `plugins/<plugin>/conduct/…` resolve under the devkit clone root (`~/.claude/agentic-devkit` — this
> skill's symlink target), not the project root.

A whole specification, carried from text to a pushed branch by two agents with fixed roles. The operator pays for a
peer CLI's independent analysis, its review, and its QA — the value comes from those passes being genuinely
independent, so the ordering rules below are not decoration.

## Gate

1. The operator triggered this skill in the current turn and supplied a specification (pasted text, a file, an issue).
2. You are Claude Code and the top-level invocation, not a dispatched subagent.
3. The peer CLI exists: `command -v codex`. If it does not, say `Pipeline: degraded — codex CLI not found`, then run
   the native stages alone and skip stages 2, 4 and 5.

Do not self-invoke, and do not load this for a one-file change, a question, or a review-only request.

**The trigger authorizes every stage the operator's hand-off named — run them without asking between
them.** Naming revmux and wrapup in the hand-off is the approval for both; pausing at each stage
boundary to confirm buys nothing and costs the operator a turn. Stop only for a decision the pipeline
genuinely cannot make: an ambiguity in the spec that changes what gets built, a destructive action, or
a stage the hand-off never mentioned.

## Stage owners — fixed, not inferred

The single most expensive failure mode is reading a stage's owner out of the operator's prose. "browser qa with codex"
means the peer performs QA; it does not mean you perform QA and then consult the peer. Whatever the phrasing, this
table decides:

| # | Stage | Owner | Gate to leave it |
|---|---|---|---|
| 1 | Freeze the spec | you | `TASK.md` written, both agents will read the same bytes |
| 2 | Analysis | **both, in parallel** | your design is written before the peer's lands in your context |
| 3 | Implementation + tests | you | project lint/typecheck/test green |
| 4 | Code review | **revmux** when authorized, else Codex review/fix loop | no critical/major finding remains; every real defect fixed or explicitly deferred |
| 5 | Browser QA | **peer**, from your written brief | PASS/FAIL on every brief item |
| 6 | wrapup | you | branch pushed, SHAs reported |

When a stage's owner is the peer, you do not also do it yourself. Doing the peer's stage natively is a protocol
violation even when it finds real bugs.

## Workspace

Everything shared with the peer lives in the session scratchpad, because the peer reads files but not your context:

| File | Purpose |
|---|---|
| `TASK.md` | the frozen spec, verbatim — the only spec both agents see |
| `process-log.md` | design decisions with rationale, peer deltas adopted, deliberate non-fixes |
| `backend.diff`, `frontend.diff` | `git diff <base>` per repo, exported before each peer stage |
| `new-*/` | files the diff does not contain (untracked new files) |
| `QA-BRIEF.md` | the browser QA hand-off — template in `references/qa-brief-template.md` |

`process-log.md` is not a courtesy. It is where a deferred defect gets its reason, and where the operator later reads
what you chose not to build.

## Stage 1 — Freeze the spec

Copy the specification into `TASK.md` without paraphrase, translation, or reordering. Attachments (mockups, designs)
are referenced by path and marked as reference-only unless the operator said to follow them literally. Where the spec
and a mockup disagree, the spec wins and the disagreement goes in `process-log.md`.

Split the spec into numbered acceptance items now. Stages 4–7 all check against this list.

## Stage 2 — Parallel analysis

The invariant: **your own design exists in writing before the peer's analysis enters your context.** Launch the peer in
the background, write your design while it runs, read its output only afterwards. Invocation mechanics, `< /dev/null`,
and failure modes: `plugins/core/conduct/cross-agent-review.md` → "Peer CLI invocation".

Give the peer the same `TASK.md` and ask for a design, not an implementation. When its analysis arrives, adopt only
concrete deltas you can verify in the code, and record each adopted delta in `process-log.md` with its source. Matching
conclusions are a confidence signal, not a finding.

## Stage 3 — Implementation

Follow `devkit-core--coder`. Two rules bite hardest in a multi-repo feature:

- A field added to a moderation/revision/DTO chain must be threaded through **every** link. Grep the chain for a
  sibling field and match its hit list exactly; a field declared in four places and missing in the fifth silently never
  reaches the model.
- Tests are the final phase, not a running commentary. Finish the implementation, get non-test checks green, then write
  tests in one pass (`plugins/core/conduct/agent-test-restraint.md`).

## Stage 4 — Code review

Export the diffs and untracked new files first — a peer cannot see your working tree.

**Pick the engine once, by authorization, not by taste:**

| Situation | Engine |
|---|---|
| Operator named revmux in the process hand-off | revmux, against the **final** diff — the primary gate |
| Operator did not name revmux | Codex adversarial review/fix loop; say the revmux stage was skipped and why |
| Implementation still churning, revmux authorized for later | one Codex loop now, revmux once against the final diff |

revmux is strictly stronger than the Codex loop and subsumes it: the `codex-led` roster already carries codex on
architecture, quality, docs/tests and adversarial lenses, adds a claude `bugs+impl` lens no single codex run has, and
ends in a verify stage that opens the cited code and can return `rejected` / `immaterial`. Running a Codex loop first
and revmux after spends the operator's time twice on the same defects and makes you hand-triage findings verify would
have filtered.

The one thing that never changes: `plugins/core/conduct/revmux-review.md` forbids any devkit skill from reaching for
revmux on its own judgement, and being inside this pipeline is not an exemption. If the operator did not name it, do
not run it — fall back to the Codex loop.

Never run both engines against the same finished diff.

### Codex review/fix loop

Read `references/codex-review.md` and follow it exactly. Codex reviews read-only; you verify and fix confirmed findings,
run the plan's validation, refresh the diff, and send it back for another independent pass. Stop after a clean pass or
after a minor-only pass whose confirmed findings you fixed. Continue while Codex reports any `CRITICAL` or `MAJOR`
finding, up to 10 iterations. If iteration 10 still has a blocking finding, stop the pipeline and report it; do not
advance to browser QA or wrapup.

Triage every finding against the code before acting:

| Finding | Action |
|---|---|
| Real defect in code this task touched | Fix |
| Security or PII leak the task's new surface exposes | Fix |
| Pre-existing platform-wide weakness, unchanged by this task | Defer with the reason in `process-log.md` |
| Fix requires a design change beyond the spec | Defer, name what the real fix needs |
| Stylistic, speculative, or wrong on inspection | Discard |

A narrow invariant that reproduces the reported scenario beats a broad one that also constrains untouched paths. Before
widening a guard, ask which unrelated flow it now fails.

## Stage 5 — Browser QA, delegated

Write `QA-BRIEF.md` from `references/qa-brief-template.md`, then hand it to the peer. The brief carries what your
context has and the peer's does not: stand URL and why not `localhost`, the auth recipe, what you already verified so
it is not re-run, exact expected strings, and the PASS/FAIL response format.

The peer's browser MCP runs isolated — it has its own profile and no session of yours, so it logs in itself. Say so in
the brief.

## Stage 6 — Wrapup

Invoke `wrapup`. Before it, re-run the full suites once — the last green run predates the review fixes. Report the
acceptance list from stage 1 with the outcome of each item, plus everything deferred.

## Hard rules

- Never run a stage the table assigns to the peer.
- Never let the peer's analysis reach your context before your own design is written.
- One review engine per finished diff: revmux when authorized, the Codex review/fix loop otherwise, never both.
- Never widen a guard past the scenario that motivated it without naming the flows it now blocks.
- Never commit unrelated untracked paths that the pipeline's diff export happened to surface; `wrapup` Step 2 triages
  them.
- Deferred defects are reported to the operator, not silently dropped.
- Never pause at a stage boundary to ask permission for a stage the hand-off already named.

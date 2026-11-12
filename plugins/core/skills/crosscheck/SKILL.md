---
name: devkit-crosscheck
description: >-
  run one task natively and in a selected independent peer CLI, then verify and merge both answers. Manual
  trigger ONLY: "crosscheck", "кросс-чек", "ask <agent> too", "second opinion", or "run it in both".
  Not existing-session pair chat or an automatic review cross-check.
---

# Cross-Check

Two independent runs of the same task, merged after verification. Costs roughly double a single run — the user pays for
that deliberately by triggering it.

## Gate

1. The user explicitly triggered this skill in the current turn. Never self-invoke, never chain it from another skill.
2. You are the top-level invocation, not a dispatched subagent.
3. Resolve the requested or configured peer through `plugins/core/conduct/cross-agent-review.md` → "Peer selection".
   Check its executable and enforced read-only mode. Any CLI can be the peer, including another Codex conversation;
   never select Claude or Codex solely because of the caller's identity. Ask for a missing or ambiguous selection
   while continuing the native pass.

An explicit trigger outranks every "not worth it" heuristic in this file. If the user asked, run it.

The peer run can fail after the gate passes — missing binary, `Not logged in`, refused sandbox escalation, timeout,
empty output. In every such case: retry at most once, then state `Cross-check: skipped — <reason>` in one line, deliver
your native answer in full, and stop. Never widen the peer's permissions to make it run.

## Procedure

### 1. Freeze the task statement

Write one self-contained peer prompt before doing any work, per `plugins/core/conduct/cross-agent-review.md` →
"Prompt requirements". Both runs get the same task. Do not narrow the peer's scope to "the part you are unsure about" —
that pre-loads your conclusion and destroys the independence the second run is paying for.

### 2. Run both passes independently

The invariant: **your own answer is complete before the peer's answer enters your context.** Capture the peer's final
answer and diagnostics in separate scratchpad files. Launch it in the background only when the calling tool can keep
that output out of your context; otherwise finish your own answer first, then launch it. The decision follows output
isolation, not the caller or peer's brand.

Commands, flags, sandbox requirements, and failure modes: `plugins/core/conduct/cross-agent-review.md` → "Peer CLI
invocation". Ground your own pass in real evidence before reading the peer's work.

### 3. Verify both sides against primary evidence

Neither answer is authoritative. For every claim the two runs disagree on, and every peer claim you are about to adopt,
check the actual file, line, command output, or doc. Discard whatever is unevidenced, out of scope, or wrong on
inspection — including your own.

### 4. Merge

| Relation | Action |
|---|---|
| Both agree, evidence checks out | Highest confidence. State it plainly. |
| Peer found something you missed, verified | Adopt. Tag `(via <peer>)`. |
| You found something the peer missed | Keep as-is. |
| Direct contradiction | Resolve by evidence, not by vote. If the evidence is genuinely ambiguous, present both readings and name what would settle it. |
| Peer claim fails verification | Discard silently unless it exposes a real ambiguity in the task. |

The deliverable is one merged answer, not two reports side by side.

### 5. Implement — only when the task was a change

The peer never edits. When the merged answer changes code, implement it in this session under `devkit-coder`, then run
the verification the change warrants per `plugins/core/conduct/verification-loop.md`. A solution altered by the merge is
unverified until it is re-run; adopting a peer's proposal is not evidence that it works.

### 6. Report

Answer first. Then one line of provenance: what the peer added, what was discarded, and any unresolved contradiction —
e.g. `Cross-check (codex): 1 point merged, 2 discarded as unevidenced; no contradictions.`

## Hard rules

- **No recursion.** The peer prompt never names this skill and never asks for a cross-check. A peer that delegates back
  forks infinitely and burns the budget.
- **One peer pass per task.** Not one per sub-question, not one per iteration of a fix.
- **The peer never writes to the repo.** Preserve its enforced write boundary on every launch and resume under
  `plugins/core/conduct/cross-agent-review.md` → "Write boundary and invocation". Tool policies and OS sandboxes are
  different mechanisms; name the one actually used. Read-only prompt wording alone is insufficient.
- **Blind own pass.** Finish your evidence-based pass before reading the peer's work; this preserves an independent comparison.

## When not to use

- Code, branch, or plan review whose top-level workflow already ran the selected peer on this scope under
  `plugins/core/conduct/cross-agent-review.md` — reuse that pass instead of paying for it twice. An explicit request
  for a different peer or a fresh independent pass still applies.
- Arguing both sides of a single claim inside one harness — that is `devkit-dialectic`, no second CLI involved.
- Trivial or already-verified work. Say so if asked; run it anyway when the user insists.

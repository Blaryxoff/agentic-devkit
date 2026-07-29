---
name: devkit-crosscheck
description: >-
  run one task twice — once natively in this harness, once in the peer CLI (Claude Code ↔ Codex) — then verify both
  answers against primary evidence and merge them into one best answer. Manual trigger ONLY, never self-invoked: load
  it when the user writes "crosscheck", "кросс-чек", "проверь через codex", "проверь через claude", "ask codex too",
  "ask claude too", "second opinion", "run it in both". No other request matches, however uncertain or high-stakes it
  looks. Mechanics: plugins/core/conduct/cross-agent-review.md.
---

# Cross-Check

Two independent runs of the same task, merged after verification. Costs roughly double a single run — the user pays for
that deliberately by triggering it.

## Gate

1. The user explicitly triggered this skill in the current turn. Never self-invoke, never chain it from another skill.
2. You are the top-level invocation, not a dispatched subagent.
3. The peer CLI is present: `command -v codex` (from Claude Code) or `command -v claude` (from Codex).

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

The invariant: **your own answer is complete before the peer's answer enters your context.** How you satisfy it depends
on the direction, because only one of the two CLIs can be backgrounded safely.

| Caller | Order |
|---|---|
| Claude Code | Launch the peer in the background, write your own answer while it runs, read its output only after yours is finished. |
| Codex | Write your own answer **first**, then run the peer. `claude -p` prints into your transcript — running it first makes the invariant unenforceable. |

Commands, flags, sandbox requirements, and failure modes: `plugins/core/conduct/cross-agent-review.md` → "Peer CLI
invocation". Ground your own pass in real evidence; do not let the peer do the reading for you.

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
- **The peer never writes to the repo** — `--sandbox read-only` (Codex) or `--permission-mode plan` (Claude). The Claude
  side is a tool-level refusal, not an OS sandbox: that process runs unsandboxed with network access and may persist a
  file under `~/.claude/plans/`. It will not touch the repository; do not describe it as sandboxed.
- **Blind own pass.** Reading the peer before finishing your own defeats the entire mechanism.

## When not to use

- Code, branch, or plan review **in Claude Code** routed to `devkit-reviewer-*` / `devkit-plan-reviewer` — they already
  run the Codex cross-check per `plugins/core/conduct/cross-agent-review.md`, so this would run it twice. In Codex that
  gate does not fire (it requires Claude Code as the caller), so an explicit cross-check of a review is correct there.
- Arguing both sides of a single claim inside one harness — that is `devkit-dialectic`, no second CLI involved.
- Trivial or already-verified work. Say so if asked; run it anyway when the user insists.

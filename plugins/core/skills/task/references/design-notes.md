# Design notes

Maintainer rationale moved out of SKILL.md; not needed at invocation time.

## Why revmux is the primary review engine (Stage 4)

revmux is strictly stronger than the Codex loop and subsumes it: the `codex-led` roster already carries codex on
architecture, quality, docs/tests and adversarial lenses, adds a claude `bugs+impl` lens no single codex run has, and
ends in a verify stage that opens the cited code and can return `rejected` / `immaterial`. Running a Codex loop first
and revmux after spends the operator's time twice on the same defects and makes you hand-triage findings verify would
have filtered.

# Terminal Learning Capture Gate

Run this gate in the top-level agent before the final response whenever the completed work may have revealed a durable,
project-specific discovery. Never run it in a dispatched subagent. Eligibility comes from what was discovered, not
session length, tool count, or files changed.

## Candidate gate

Invoke `devkit-learn` only when at least one candidate satisfies every condition:

1. **Durable** — expected to remain useful after the current change and in six months.
2. **Project-specific** — not ordinary framework, language, or tool knowledge.
3. **Non-obvious** — not already clear from manifests, nearby code, or standard documentation.
4. **Reusable** — likely to prevent a future mistake or materially shorten later investigation.
5. **Observed** — supported by files, commands, runtime evidence, or a confirmed project decision from this session.
6. **Apparently new** — not already present in memory or rules read during this session. Do not scan memory just to run
   this gate; `devkit-learn` performs full deduplication after invocation.

Reject task history, the specific fix or feature just completed, temporary state, speculative conclusions, TODOs, common
knowledge, and facts already documented at their canonical source.

## Terminal action

- If no candidate passes, finish silently. Do not invoke `devkit-learn` and do not mention the gate.
- If candidates pass, keep the strongest three at most and activate the learning skill before the final response:
  `Skill(devkit-core--learn)` on Claude Code, or `devkit-learn` through the native skill mechanism on Codex/Cursor.
- Pass each candidate with its evidence and expected future value. Let `devkit-learn` deduplicate, route, and request user
  confirmation.
- Never write project memory directly from this gate.

# Terminal Learning Capture Gate

Run this gate in the top-level agent before the final response whenever the completed work may have revealed an enduring
project contract or contributor workflow. Never run it in a dispatched subagent. Eligibility comes from forward-looking
project guidance, not session length, tool count, files changed, or the difficulty of the bug just solved.

Apply this terminal gate after the full authorized task is complete. Keep unfinished implementations and active goals
moving after status answers, peer-review rounds, and tool notifications; those turn boundaries do not trigger learning.
When explicitly requested learning collects candidates during unfinished work, queue them and resume the task. Review
them at completion unless the user explicitly asks for immediate memory review. Install no learning `stop` hook and emit
no automatic follow-up prompt.

Review pending proposals from an already-authorized history collection at that completion boundary using
`devkit-learn`'s private queue workflow. Revalidate them against current evidence and this gate before presenting them;
an incremental processing index never authorizes an instruction-file edit. Keep personal candidates routed to the
active harness's personal/global mechanism. History discovery stays explicitly scoped to the project; this gate does
not authorize scanning unrelated sessions.

## Candidate gate

Split each candidate to a single claim before testing it. Test a bundled defect and its surrounding observation
separately; a structural clause never carries an actionable finding through the gate.

Invoke `devkit-learn` only when at least one candidate satisfies every condition:

1. **Different-task value** — guides a fresh agent or developer on future work other than repeating or revisiting the
   issue just completed.
2. **Project contract** — describes an intentional, durable architecture rule, convention, constraint, or workflow; it
   is not a framework fact or implementation gotcha.
3. **Established** — supported beyond one failure path by multiple project locations, an existing workflow, or a
   confirmed team decision. Repeat sightings of one failure, and agreement between reviewers or models, raise confidence
   in the observation; neither is evidence of intent.
4. **Instruction-worthy** — materially changes how contributors should approach a class of work and belongs in project
   instructions rather than code, tests, types, or canonical technical documentation — including documentation the
   project should have and has not written yet.
5. **Self-contained** — remains actionable without the completed task's incident history.
6. **Apparently new** — not already present in memory or rules read during this session. Do not scan memory just to run
   this gate; `devkit-learn` performs full deduplication after invocation.
7. **Survives its own fix** — stays true after the project acts on it.
   If acting on the finding makes it false, it is work, not memory.

Reject task history, bug causes and fixes, defensive checks, low-level query or payload-matching idioms, framework or
serialization behaviour, temporary state, speculative conclusions, TODOs, common knowledge, and facts already documented
at their canonical source. A lesson does not qualify merely because it could prevent the same bug from recurring in
another file.

A personal user preference is not a team project contract; keep it in the user's supported global or personal memory
mechanism, never in shared project instructions. A product behavior or implementation detail discovered in one task is
not durable project guidance by itself; require an established contract that applies across a class of future work, or
keep the detail in its task specification, code, tests, or canonical product documentation.

Route actionable repository findings — dead or unreferenced code, stale configuration, cleanup, defects left unfixed —
to a fix or to user-approved deferral under [deferred-work-backlog.md](./deferred-work-backlog.md). Never write one as
project memory, and never file one silently.

## Terminal action

- If no candidate passes and none is actionable repository work, finish silently. Do not invoke `devkit-learn` and do
  not mention the gate.
- If a rejected candidate is actionable repository work, name it in one line and offer the choice: fix it now via
  `Skill(devkit-core--coder)`, or defer it via `Skill(devkit-core--backlog)`, which owns the default-branch gate and
  dedupe. Surface at most two, only when verified this session and outside the scope the task already changed. Act only
  on the user's answer.
- If candidates pass, keep the strongest three at most and activate the learning skill before the final response:
  `Skill(devkit-core--learn)` on Claude Code, or `devkit-learn` through the native skill mechanism on Codex/Cursor.
- Pass each candidate with its evidence and expected future value. Let `devkit-learn` deduplicate, route, and request user
  confirmation.
- Never write project memory directly from this gate.

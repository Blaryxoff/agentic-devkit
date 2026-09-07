# Codex review/fix loop

Adapted from the external-review phase in
[`umputun/cc-thingz`](https://github.com/umputun/cc-thingz/tree/master/plugins/planning/skills/exec) (MIT).

## Review contract

Invoke Codex with the read-only mechanics in `plugins/core/conduct/cross-agent-review.md` → "Peer CLI invocation".
Point it at `TASK.md`, `process-log.md`, the base branch, the exported diff files, and every exported untracked file.
Write the complete resolved prompt to a scratchpad file with the environment's file-write tool, set `prompt_file` to
that path, then pass it as `"$(cat "$prompt_file")"`. Never paste the prompt inline or create it with `echo` or an
unquoted heredoc: backticks and `$` in review instructions must reach Codex literally, not execute in the launcher shell.
Require this output:

```text
CRITICAL: file:line — defect and impact
MAJOR: file:line — defect and impact
MINOR: file:line — defect and impact
```

Require `NO ISSUES FOUND` when no material issue exists. The prompt must ask Codex to:

- read the task and process log before judging intent;
- inspect the actual source around each finding;
- review adversarially for correctness, security, data loss, races, partial failure, error handling, and contract drift;
- re-evaluate the whole current diff independently instead of trusting earlier fixes;
- report material, evidenced findings only;
- answer directly without editing files or invoking another agent.

Treat an empty response, a response with neither a severity tag nor `NO ISSUES FOUND`, or a run without repository
access as reviewer failure, never as a clean review. Scan the complete response for every severity tag before evaluating
the clean marker. `NO ISSUES FOUND` counts as clean only when no severity tag appears; findings win when a reviewer emits
both.

## Iteration

1. Export fresh diffs and untracked files before every Codex pass.
2. Save the complete Codex response in the scratchpad; do not summarize it before triage.
3. Verify every finding against the cited code. Fix confirmed issues from this task, discard false positives, and defer
   only issues allowed by the Stage 4 triage table in `../SKILL.md`.
4. Record confirmed fixes, discarded findings, and deferred findings with reasons in `process-log.md`.
5. Run the task's validation commands after every fix batch. A failed validation keeps the review iteration open.
6. Scan the complete response for `CRITICAL`, `MAJOR`, and `MINOR` before checking `NO ISSUES FOUND`.
7. Stop on `NO ISSUES FOUND` only when no severity tag appears.
8. If the pass has findings but none tagged `CRITICAL` or `MAJOR`, fix confirmed minor findings and stop without another
   Codex pass.
9. If any `CRITICAL` or `MAJOR` finding was reported, refresh the exports and start another pass, even when you rejected
   that finding after inspection. The next independent pass is the exit evidence.

Never let Codex write. Never call a pass clean merely because every finding was rejected locally.

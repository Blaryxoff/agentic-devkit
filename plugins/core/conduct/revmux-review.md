# revmux Review Delegation

`revmux` is an external supervised multi-agent review engine: a Go binary plus an upstream Claude Code plugin skill
(`revmux@revmux`) that drives it. Devkit routes to that skill and never vendors it — the workflow is versioned upstream.

## Trigger — manual only

- Load only when the user names revmux as the **engine** to review with: "revmux this branch", "run revmux",
  "review it with revmux", "прогони ревмакс по ветке".
- **A review whose subject is revmux is not a trigger.** "review the revmux integration" routes by
  [review-routing.md](./review-routing.md) like any other target. Do not treat phrases that already mean something else
  here — "subagent review", "parallel review" — as revmux requests.
- **Never self-invoke.** No devkit reviewer, orchestrator, or specialist may reach for revmux on its own judgement — not
  for a large diff, not for a risky one, not as a pre-merge gate. One run spawns four or more model subprocesses and
  takes 3–15 minutes.
- Activate the upstream skill and follow its `SKILL.md`: `Skill(revmux:revmux)` on Claude Code, the `revmux` skill under
  `~/.codex/skills/revmux` on Codex. Never re-implement its preflight, task-round, launch, or presentation mechanics
  here — the upstream workflow owns all four.

## Install

| piece | command |
|---|---|
| binary | `brew install umputun/apps/revmux` |
| Claude Code skill | `claude plugin marketplace add umputun/revmux` then `claude plugin install revmux@revmux` |
| Codex skill | `cp -r <marketplace-clone>/plugins/codex/skills/revmux ~/.codex/skills/revmux` |

The profile decides which model CLIs must exist: `comprehensive`, `focused`, `final`, `grill-me`, `triage` and `expert`
need both `claude` and `codex`; `claude-only` and `codex-only` need one. The upstream skill's own preflight step checks
this — pass it the profile that will actually run.

## Relationship to the devkit reviewers

- revmux **replaces** the devkit reviewer fan-out for that pass. It is not an extra axis stacked onto
  `devkit-reviewer-deep`. Run one or the other for a given scope unless the user asks for both.
- **Skip the `cross-agent-review.md` Codex cross-check only when the report shows Codex actually ran.** Check
  `sources.agents` for a `codex` executor with `degraded: false`: that peer went through the same synthesis and
  verification, so a second Codex pass would re-review findings Codex helped produce. A `claude-only` run, or one whose
  codex source degraded, still owes the cross-check — run it and tag the merged findings `(via Codex)`.
- Without the trigger token, code review stays with `devkit-reviewer-deep` + `devkit-reviewer-business-logic` and plan
  review with `devkit-plan-reviewer` — see [review-routing.md](./review-routing.md).
- revmux reviews any subject its round points at, a plan or design document included. That does not make it the plan
  route: `docs/plans/**` still goes to `devkit-plan-reviewer` unless the user wrote `revmux`.

## Reading and presenting the report

- The upstream skill's `references/present.md` owns the shape of the turn. Follow it.
- When the user asks for the devkit format, or the report feeds a devkit completion gate, map severities into
  [review-findings-format.md](./review-findings-format.md): `critical` → Blocking, `major` → Blocking or Significant by
  its impact adjudication, `minor` → Minor. Keep `immaterial`, `pre_existing` and `open_questions` out of the buckets
  and out of the count.
- Exit `1` means findings were reported — a normal outcome, never a failure. `0` none, `2` tool error.
- `sources.degraded` non-empty means the pass is partial: it cannot satisfy a review completion gate. Lead with that and
  re-run the missing source before deciding anything else.
- Reviewers never repair. A revmux report authorizes edits only on an explicit fix request, and the repair workflow
  activates the coder skill exactly as `review-findings-format.md` requires.

## Project calibration and trust

- `./.revmux/profile.md` is the repository's review standard — what the software is, what a real failure looks like,
  the reporting bar. Write it only with the user's explicit yes, never on a tree that is not theirs.
- `.revmux/` is executable configuration: a checked-in lens becomes instructions a headless agent with a shell runs.
  Read it before reviewing a tree you do not own, or run from outside it with explicit `--workdir`, `--tasks-dir` and
  `--config-dir`.
- Rounds stack under one task. A re-review after fixes opens a new round on the same task; revmux injects the prior
  rounds itself, so never paste earlier findings into the new scope.

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

The profile decides which model CLIs must exist: `comprehensive`, `focused`, `final`, `grill-me`, `triage`, `expert` and
`codex-led` need both `claude` and `codex`; `claude-only` and `codex-only` need one. The upstream skill's own preflight
step checks this — pass it the profile that will actually run.

## Profile selection

Default to `codex-led` when the operator wants codex to carry the review volume and claude to adjudicate it. Set it in
`~/.config/revmux/config` with `profile = codex-led`; per-run, pass `--profile=codex-led`.

| agent | lenses | executor |
|---|---|---|
| `claude-bugs+impl` | bugs, impl | `claude/opus:high` |
| `codex-arch+quality` | architecture, quality | `codex/gpt-5.6-sol:high` |
| `codex-docs+tests` | docs, tests, comments | `codex/gpt-5.6-sol:high` |
| `codex-adversarial` | adversarial | `codex/gpt-5.6-sol:high` |
| synthesis, verify | — | `claude/opus:high` |

- Keep both stages on claude. Verify is the only stage that opens the cited code and can return `rejected` or
  `immaterial`; synthesis is forbidden from judging truth, so a codex-heavy roster is safe only while verify is claude.
- Declare `stages:` explicitly. Both stages otherwise inherit the profile's top-level `model:`, which silently moves
  adjudication to codex and inverts the design.
- Keep one claude roster agent on `bugs`+`impl`. Verify cannot raise a finding no roster agent made, so a defect every
  codex agent misses is lost without it.
- Do not duplicate a lens across both executors. Corroboration already crosses complementary lenses; full duplication is
  what `expert` and `grill-me` charge for.
- Expect roughly half the claude spend of `comprehensive`, not three quarters: synthesis and verify stay on claude and
  verify fans out to `--verify-groups` (6 by default).

Recreate the profile on another machine — generate the body, never paste it, so it matches the installed revmux:

```bash
revmux --dump-defaults=/tmp/revmux-defaults
mkdir -p ~/.config/revmux/prompts/profiles
{ printf '%s\n' '---' \
    'description: codex carries architecture+quality, docs+tests and adversarial; claude keeps bugs+impl and owns synthesis and verify' \
    'model: codex/gpt-5.6-sol:high' \
    'agents:' \
    '  - {name: claude-bugs+impl,   lenses: [bugs, impl],            model: claude/opus:high, color: cyan}' \
    '  - {name: codex-arch+quality, lenses: [architecture, quality],                          color: magenta}' \
    '  - {name: codex-docs+tests,   lenses: [docs, tests, comments],                          color: green}' \
    '  - {name: codex-adversarial,  lenses: [adversarial],                                    color: yellow}' \
    'stages:' \
    '  synthesis: claude/opus:high' \
    '  verify: claude/opus:high' \
    '---'
  awk 'f{print} /^---$/{c++; if (c==2) f=1}' /tmp/revmux-defaults/prompts/profiles/comprehensive.md
} > ~/.config/revmux/prompts/profiles/codex-led.md
revmux config --task <any-task>   # confirm the roster and both stage executors resolved
```

Prompt-tree resolution is per file: `./.revmux/`, then `~/.config/revmux/`, then revmux's embedded defaults. devkit's
clone is not on that path, so a profile devkit recommends still has to be written into `~/.config/revmux/`.

- Regenerate `codex-led` after every revmux upgrade. Its body is a frozen copy of that release's `comprehensive.md`;
  built-in profiles pick up a changed panel prompt on upgrade and a user profile does not.
- Expect `~/.config/revmux/config` to stop tracking upstream once a line in it is uncommented — `--init` replaces a
  comment-only file and leaves a customized one alone, so knobs added later never appear there.

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

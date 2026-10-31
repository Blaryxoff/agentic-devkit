# Umputun workflows adopted in devkit

Selected workflows from [`umputun/cc-thingz`](https://github.com/umputun/cc-thingz) (MIT) are adapted into
`plugins/core`. Keep upstream attribution and place stack-specific rules in their owning plugins.

## Core skills

- `devkit-dialectic`: opposing analyses of a claim, followed by synthesis checked against the code.
- `devkit-root-cause`: 5-Why investigation of errors and unexpected behavior; does not repair code.
- `devkit-wrong`: reset a failing approach and propose two or three alternatives.
- `devkit-clarify`: explain observed behavior with evidence and distinguish misunderstanding from a defect.
- `devkit-learn`: propose up to three durable project contracts for native agent instructions. Follow placement rules
  and write only after granular user confirmation. Exclude task history and technical gotchas; route actionable work
  to a fix or user-approved backlog item.
- `devkit-backlog`: maintain one deferred item per file in `docs/backlog/`, with default-branch and deduplication gates;
  do not commit automatically.

## Shared conduct

- `code-comments.md`: describe current contracts rather than change history; keep required public API documentation.
- `code-smells.md`: stack-neutral review checks, used by reviewer-deep variants.
- `communication-style.md`: concise commit, PR and review wording.
- `output-styles/senior.md`: default Claude style, adapted from spot's Primary Guidelines and cc-thingz writing-style;
  Laconica remains available manually.
- `learning-capture-gate.md`: capture established project contracts, offer fixes/backlog for actionable work, or finish
  silently. The gate excludes solved-task details and technical gotchas and does not scan project memory.
- `deferred-work-backlog.md`: canonical backlog fields and default-branch gate, executed by devkit-backlog.
- `review-specialist-fanout.md`: quality, implementation, testing and documentation review, with generic stack fallbacks.

## Skill activation hook

`plugins/core/hooks/skill-eval.sh` instructs Claude to evaluate and activate relevant skills before implementation.

- `bin/devkit-install` registers it globally in `~/.claude/settings.json`, alongside the SessionStart update hook.
- It supplies instructions, not permissions. Codex and Cursor use their native discovery mechanisms.
- Core intentionally omits `paths.hooks` so project adapters do not register the same hook twice.
- Rerun the global installer after policy changes and regenerate existing project adapters. Updating the clone does
  not rewrite project `AGENTS.md` or `.mdc` files.

## Adopted workflow changes

- **Plan review handoff:** after saving confirmed ralphex plans, run the existing reviewer if the request includes
  review; otherwise provide its explicit invocation as the next step without another confirmation question. Report
  saved and independently reviewed states separately. Adapted from
  [cc-thingz planning](https://github.com/umputun/cc-thingz/blob/f84b93ca0f04a1406bdbb834d8f1ed1946996d1e/plugins/planning/commands/make.md#L329-L349).
- **Revmux archive safety:** preserve explicit roots across commands and check archive placement before removing a
  worktree. Follow `plugins/core/conduct/revmux-review.md`; see the
  [upstream fix](https://github.com/umputun/revmux/commit/269c58a4db65546fdb66da73e19f5c5c487249a5).
- **Reproducible Jev evaluation:** freeze the model, questions, criteria, preprocessing and thresholds; use holdout
  cases and retain sanitized fixtures and results outside `/tmp`. Follow the benchmark reference; calibration is
  informed by [TG-Spam](https://github.com/umputun/tg-spam/blob/0ae15ec77ee35e54ca49c58fad94f98fa1f495cb/docs/plans/completed/20260921-jev-provider.md#L22-L70).

## Cost-effective Jev usage

Adopt any demonstrated reduction in expensive-model cost at preserved task quality. Include Jev, cache, output and
fallback costs; summed tokens across differently priced providers do not decide adoption.

- Keep `jev-1.13.0`, large-file `locate`, reversible output ranking and typed questions.
- Offload citation relations at confidence >=0.95; send uncertain cases to Sol/Claude. The reviewer still decides
  whole-finding validity. Group up to three claims sharing the exact excerpt: measured cost falls a further 4.3%
  versus independent citation checks at matched 50% cache hits, without an observed quality regression.
- Use the integrated existence question in locate when the default model receives the whole untruncated file in one
  request. The measured cost saving is about 1.25%, with no extra API call. Truncated/chunked inputs, model overrides
  and invalid existence answers retain ordinary ranking. A negative signal concerns that file, not the repository.
- Keep the separate full-file absence prepass off for the measured Sol workflow: it avoided little additional work
  and showed no robust cost saving. Reprice other verifier configurations rather than generalizing the rejection.
- Retain historical quality findings, but mark unavailable economic evidence as unknown. Do not infer monetary
  failure from raw token counts. See `plugins/core/skills/jev/references/benchmarks.md` for measured scope and limits.

## Updating upstream skills

- Compare active Claude plugin skills/scripts with the selected upstream commit even when the plugin version has
  not changed. Back up the cache and launcher overrides; reinstall stale contents with the normal CLI using
  `uninstall --keep-data`, then `install`, and compare again.
- Refresh standalone Codex/Cursor copies with a three-way comparison of old upstream, local adaptations and new
  upstream. Preserve path resolution, native tool differences and checks for optional CLI flags. Install the
  Codex rollout extractor in `revdiff-plan` only for Codex.
- Regenerate `codex-led` from installed revmux defaults and the runtime-resolved Sol model as specified in revmux-review.
- Keep cookbook recipes opt-in. Existing `pair`, `demo` and `backlog` cover the required two-agent chat, artifact
  display and backlog workflows; do not duplicate them or install automatic keybindings and plan-review hooks.

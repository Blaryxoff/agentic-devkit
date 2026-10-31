# Jev benchmarks

## Adoption criterion

Adopt Jev whenever it demonstrably avoids Sol/Claude work at lower expected cost while preserving required evidence
and task quality. Do not require a minimum percentage saving or a reduction in tokens summed across providers.

- Price uncached input, cached input, output and Jev separately; include fallback, retries and rereads. Reasoning output
  already included in provider output usage is not charged twice. Extra cheap Jev tokens alone never justify rejection.
- Prefer a deterministic operation when it avoids the same expensive-model work at equal quality.
- Compare policies at matched cache conditions and report observed cache costs separately. Warm-cache ordering is not
  an intervention benefit. Keep subscription allowance, API-equivalent opportunity cost and actual cash charges distinct.
- Freeze model, question, criteria, preprocessing, thresholds and acceptance criteria before inference. Revalidate changes
  on separate holdout data; use 50+ source-grounded cases with labels fixed before scoring and the current workflow as baseline.
- Include answer-absent retrieval cases. Report false negatives and false positives alongside provider-weighted cost and
  latency. Preserve sanitized fixtures, gold labels, requests, resolved model IDs and responses outside `/tmp`.
- Treat prompt/threshold tuning data as development data. Missing raw usage means unknown economic benefit; it does
  not establish that Jev is uneconomic. Correctness failures remain correctness failures regardless of low inference cost.

Calibration follows [TG-Spam's Jev evaluation](https://github.com/umputun/tg-spam/blob/0ae15ec77ee35e54ca49c58fad94f98fa1f495cb/docs/plans/completed/20260921-jev-provider.md#L22-L70).

## Citation relations — adopted selectively, 2026-10-31

Offload independent citation-support classification to the existing `ask` workflow when this replaces new expensive-model
verification. Accept relation labels at confidence >=0.95; let Sol/Claude classify uncertain cases and provider failures.
Do not repeat accepted narrow classifications in the expensive model. Keep actual defect validity and severity with the
reviewer: citation support alone neither establishes a bug nor authorizes discarding a finding.

- Test 60 public-source citation cases: 12 development and 48 holdout from 16 source groups. Pin Jev 1.13.0/1.14.0;
  use catalog-resolved Sol at low effort. Archive the exact model in `ENVIRONMENT.json`. Replay verifier inputs with
  opaque IDs to remove category cues; change no frozen labels, thresholds or source evidence.
- Observe 22/48 and 20/48 accepted high-confidence relations, with no incorrect automatic relation decisions. Both
  complete pipelines and the native verifier classify 44/48 correctly. These are controlled source-grounded claims,
  not naturally sampled bug findings; the small, grouped sample does not establish production-wide safety.
- Reprice saved usage at Standard API-equivalent Sol rates of $2/M uncached input, $0.10/M cached input and $10/M output;
  Jev costs $0.042/M input with free output. Sources: [OpenAI](https://developers.openai.com/api/docs/pricing),
  [TypeSafe](https://docs.typesafe.ai/models). This account uses ChatGPT login, so USD estimates are opportunity-cost
  comparisons, not its subscription invoice. [Codex credit rates](https://learn.chatgpt.com/docs/pricing#token-rates)
  are recorded separately in the cost analysis.
- At a common 50% cache-hit rate, per 48 checks: native verification costs about $0.173; Jev 1.13 + Sol costs $0.159
  (7.8% less), and Jev 1.14 + Sol $0.161 (6.8% less). Both remain cheaper from cold through fully cached scenarios.
  Keep the existing 1.13 pin; this experiment gives no reason to migrate the model.
- Contradiction-only rejection saves 2.3%/1.2% at matched 50% cache hits, but is more cache-sensitive. Use the broader
  narrow-relation offload; do not extrapolate it to automatic whole-finding rejection.
- The prior rejection based on increased combined input is superseded. Raw provider token counts remain diagnostics.

## Separate full-file absence prepass — no default adoption for the tested Sol workflow

Keep ordinary `locate` with the integrated signal evaluated below. Reprice a different expensive verifier instead of
applying the separate-prepass conclusion to all possible absence signals.

- Test 60 retrieval cases, with 12 development and 48 holdout from 16 source groups. A separate complete-file Noul
  at probability <=0.05 skips ordinary locate and its verifier for that file; it never stops repository-wide search.
- Skip 7/48 and 10/48 files without losing present answers. Ordinary locate already returns no blocks for 6 and 7
  of those skips. Baseline and gated pipelines both classify 48/48 correctly.
- At matched 50% cache hits, Jev 1.13 costs $0.1776 versus $0.1713 baseline (3.7% more); Jev 1.14 costs $0.1786
  versus $0.1766 (1.1% more). A tiny cold-cache 1.14 saving is within observed wrapper variation, not a robust gain.
- Check eight additional cases across four complete 513–658-line files with Jev 1.13. Both pipelines are 8/8 correct;
  the one skipped file was already skipped by locate. No Sol work is avoided; the prepass adds about $0.00252 per cohort.
- Observed unmatched cache hits make one absence arm appear 57% cheaper and another twice as expensive. Do not
  attribute those order-dependent differences to the gate. No default adoption is based on matched cost and avoided
  work, not on adding Jev tokens. Median extra presence request is about 0.66 seconds.

## Shared-source citation batches and integrated existence — adopted, 2026-10-31

- Compare against the adopted independent citation checks and ordinary locate using the original frozen public
  fixtures, splits and thresholds. This reuses the held-out groups; it is a comparative follow-up, not an independent
  replication. Use opaque IDs and a fresh matched native-verifier baseline. No cross-provider token-count veto.
- Group three claims sharing the exact source excerpt in one Jev request, with independent relation questions and
  per-claim confidence/fallback. Accept 31/48 relations versus 22/48 independently, with no wrong confident labels
  observed. Pipeline correctness is 45/48 versus 44/48, which establishes no observed regression, not a significant
  accuracy improvement. At matched 50% cache hits, cost falls $0.1586 -> $0.1518 per 48 checks (4.3%); all tested
  cold-to-fully-cached scenarios save cost. Use source-sharing batches up to three claims; keep unrelated evidence separate.
- Add one existence Noul to the existing locate request only for a complete untruncated file in one request with the
  default pinned model. A probability <=0.05 suppresses misleading block hits. Keep ordinary ranking for truncated or
  chunked input, model overrides and missing/malformed existence answers. No second API call and no repository-wide stop.
- Eligibility is 24/48 holdout cases. Five files are skipped, including two whose misleading block hits otherwise
  required Sol verification. No present answer is lost; both pipelines remain 48/48 correct. At matched 50% cache hits,
  cost falls $0.1732 -> $0.1710 (1.25%). Cold-to-fully-cached scenarios save 1.20–1.77%.
- Implement the integrated question in `scripts/jev.py`. Offline replay confirms production requests and emitted ranges
  match all 60 saved retrieval cases. Focused tests cover absent/uncertain answers, invalid values, complete versus
  clipped/chunked input, model overrides and missing block answers; observe the absence regression fail before the fix.
- Preserve `~/.local/state/agentic-devkit/benchmarks/20261031-jev-followup/`: protocol, frozen fixtures, provider usage,
  `RESULTS.json`, `PRODUCTION-PARITY.json` and repository verification logs. Follow-up inference uses 94,707 new Jev
  input tokens, 50 Jev requests and 24 native verifier calls, finishing in 79.1 seconds within the approved bounds.

## Earlier adopted uses — retain

- Large-file `locate`: 128 functions across five repos gave top-1/top-3/top-5 answer-block hits of 86%/98%/100%,
  versus 48% keyword top-3; about 105 of 800 lines read, median 0.78 s. An independent 60-task set found the answer within
  100 returned lines in 56/60 cases, versus 25/60 for jegrep and 41/60 for a Luna worker at 12.5 s and 34k tokens.
  Retain the expensive-reading reduction; historical usage is insufficient to attach a monetary saving percentage.
- `filter` as an ordering aid: 51 real outputs, about 400 lines, answer top-1/top-5/top-10 of 31%/61%/71%; default kept
  69%, median 2.7 s. Read ranked output first, retain originals and fall back when needed. Measure full-path cost including
  rereads; losing needed lines is not an acceptable saving.

## Earlier quality failures — preserve the evidence, withdraw unsupported cost claims

- Subagent model tier: 39 tasks, Jev 69% versus a fixed rule 62%; native choice 84% on 25 cases, with eight under-tiered.
  Automatic routing failed the quality comparison; no saved provider usage establishes its end-to-end economic result.
- Skill routing: 40 prompts, 53% versus 50% for always selecting no skill. Do not skip required workflows from this signal.
- Conduct selection: 12 Laravel tasks, recall 92% at 51% precision (0.5), or recall 72% at 100% precision (0.7).
  Dropping required conduct is a completeness failure; ordering hints must retain required documents.
- Irreversible output filtering: 183 outputs of 100–500 lines; 61% needed whole, and all needed lines survived in only
  14–34% of the rest. Retain reversible ranking, not silent deletion of evidence.
- Transcript pruning: external keep/drop agreement 56.3%, with the plugin author advising against it. Preserve context
  completeness; those results do not establish safe compaction.
- Known-file jegrep: 25/60 answers within 100 read lines, median first span 216 lines, versus locate 56/60.
  Prefer the existing locate workflow; this is a retrieval-quality result, not a cross-provider cost calculation.

## Cheaper deterministic alternatives — no demonstrated incremental Jev benefit

- Known literal error: 40 cases from 12 Laravel logs, 16 signatures. `rg -F -m1` plus 15 context lines found 40/40 in
  16 read lines and 8 ms; locate 38/40 with 240 lines and 2.6 s; grep context piped through filter 13/40. Exact matching
  already avoids expensive reading without Jev; this use added work and lost answers.
- Browser snapshot comparison: 200 mutated snapshots, Jev accuracy 0.93 tied with uid-stripped `diff`, including timestamp
  mismatches. Use the deterministic comparison where it suffices; no measured expensive-model work was avoided by Jev.
- Reasoning-effort selection: 100 cases (60 locate, 40 log triage), two repeats, 480 runs per CLI. Choices collapsed to a
  per-task rule on 98/100 templated inputs; low effort was not significantly worse than high (Claude 85.0% vs 82.0%,
  Sol 76.0% vs 71.0%, paired p >=0.096). Three Sol log cases benefited from medium. The effort rule supplies the observed
  saving without a Jev router; do not infer that greater Jev token volume was the reason to decline it.

## Economic verdict unavailable

A policy asking workers to pipe output through Jev was not invoked in 20/20 fresh Luna runs, across two wordings.
That measures failed activation, not Jev cost or efficacy. Historical raw data lived in `/tmp/jev-bench-codex/` and
`/tmp/jev-effort/` and is not retained. Preserve their quality observations, but do not invent monetary conclusions or
claim that all earlier non-adoptions were cost-tested.

## Reproducible current evidence

`~/.local/state/agentic-devkit/benchmarks/20261031-jev-automation/` retains source fixtures, frozen manifests, exact
requests/responses, opaque-ID replay, `RESULTS.json`, `COST-RESULTS.json` and `COST-REPORT.txt`. Run
`python3 cost_analysis.py` there for offline repricing without provider calls. `REPORT.txt` explicitly marks the prior
aggregate-token decision as superseded. The original protocol and observations remain unchanged.

Inference completed in 22.7 minutes within the approved 25-minute/850k limits: 828,634 Jev input tokens (about $0.035),
no provider errors, and 2,857,379 Sol input tokens including diagnostic runs and replay (1,128,064 cached). The current
cost reassessment reuses those observations and makes no new paid inference calls.

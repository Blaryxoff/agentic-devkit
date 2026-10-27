# Review and runtime QA evaluation

Freeze: `design-3`, 2026-10-27. Baseline: `1b92a776cf1394b45b71778298b875cafb5f77fc`.
Source: approved [proposal](../../../docs/proposals/2026-10-26-review-and-qa-coverage.md), stage 7.
These synthetic fixtures were authored before candidate conduct/skill edits. They contain no customer data or copied application code.

The original inputs and rubric were frozen as `design-1` before production edits and remain byte-for-byte unchanged. `design-2` introduced explicit criterion applicability after review found evaluator-waiver and export-identity bugs; `design-3` preserves C033's missing-event-path obligation on the static axis. Neither policy revision followed a full benchmark run. The standard-library runner and self-tests were added after production documentation and non-test checks passed. Their presence does not establish a paired benchmark result, runtime proof, or effectiveness. Keep raw sessions outside the committed corpus.

## Inputs and answer key

`cases.json` contains 40 neutral cases, each with brief, explicit product contract, and two opaque variants. Export only `id`, `brief`, `contract`, and **one** variant as `evidence` into an isolated session. Do not give the tested agent this README, `rubric.json`, the other variant, a family label, or fault/clean polarity. Filenames for exported inputs must be opaque (`C001-a.json`, for example). Code snippets are small behavioral fixtures, not complete framework applications.

`rubric.json` is the evaluator-only answer key. It maps independent mechanisms to families V01–V15, declares the fault/clean variant, required observations, clean guards, evaluation axes, runtime fixture designs, and exact baseline source digests. No candidate prompt generates or revises the answer key. Inputs are under 200 words per brief/contract/variant. Re-freezing changes requires a new design revision, recorded hashes, and both arms rerun.

`applicability.json` is the frozen evaluator-only mapping from original criterion IDs to their required axes. Every original observation is assigned to at least one declared axis; each axis has mandatory observations. It separates finding obligations from test-design obligations without dropping either. Interpret mixed finding/scenario clauses under the declared axis: static review identifies source-backed mechanisms, case generation designs concrete checks, and neither claims runtime execution. The mapping and the positive case-generation obligation apply identically to baseline and candidate. Export only case inputs to the tested agent, never this policy or the answer key. All three data digests are bound into new snapshots and runs; do not combine results from different policy revisions.

| IDs | Family / independent mechanisms |
|---|---|
| C001–C003 | V01 placement state, access cycle, rendered children |
| C004–C005 | V02 selective restore, source-preserving copy |
| C006 | V03 hidden aggregate members |
| C007–C009 | V04 draft authorization, bulk authorization, trainer allow |
| C010–C011 | V05 time round trip, accounting projection |
| C012–C015 | V06 browser revision, API/worker revision, native package identity, module presence |
| C016–C019 | V07 independent entry point, rendered PDF, playback, mail delivery |
| C020–C022 | V08 touch action, keyboard viewport, native evidence boundary |
| C023–C024 | V09 authoritative amendment/conflicting suggestion, unavailable attachment |
| C025–C027 | V10 ledger challenge, browser reuse, standalone verify reuse |
| C028 | V11 reservation lifecycle |
| C029 | V12 rejection before acceptance |
| C030–C033 | V13 final interval, seek/replay, actor switch, client instrumentation |
| C034–C035 | V14 identity matching, equivalent windows |
| C036–C038 | V15 edited report, execution method, skipped/expected-failure outcomes |
| C039–C040 | bounded static and browser spot controls |

## Separate evaluation lanes

Run each declared `workflows` axis independently. Compatible cases may share one harness request for cost, but each ID, variant and axis retains its own result, evidence and score. Do not group both variants of an ID or disclose the answer key.

- Static review: request findings against contract/source, preserving read-only scope. Evaluate only supplied code/data; inherited traces are not fresh runtime evidence.
- Case generation: request the smallest sufficient concrete cases, with setup, action and expected observable/persisted/side-effect result. Merely naming a risk or a bug does not satisfy this lane.
- Evidence adjudication: request acceptance decisions using the supplied records. Record methods, component identity, source run, gaps and justified reuse; do not claim the tested agent executed those records.
- Runtime probes: build the deterministic fixtures specified under `runtime_probe`, then have the agent exercise them using available supported tools. Replace prewritten traces with actual runtime observations. Capture tool transcripts, timestamps and artifacts. Source reasoning and fixture assertions cannot earn agent runtime-detection credit. The same input contract/polarity/oracle remains frozen. Actual Safari/native limitations remain declared gaps; browser emulation cannot fill them.

## Snapshot and invocation protocol

1. Materialize baseline from the exact commit into a pass-owned root; materialize candidate after production/non-test completion. The parent may use its already prepared `.cache/review-qa/baseline` archive. Do not check out over the working tree or update the installed clone.
2. Use `workflow_roots` as the exact source inventory for each lane, and `baseline_files` to verify baseline bytes. Select the applicable entry skill: static review uses the Laravel or frontend business-logic leaf; case design uses test-case-creator; browser acceptance uses browser; API/worker/native acceptance uses verify. The other inventory entries are eligible references, not an instruction to preload every file. The candidate adds `candidate_conditional_files` only when relevant. C039/C040 must not load output/device references. Preserve existing source links and recursively log references actually opened.
3. Pin primary harness binary/version, explicit model revision, effort, tool capabilities and settings before pairing. Run from a clean temporary consuming project with an explicit assigned skill/conduct root. Do not expose global installed skills or ambient project instructions. If the harness cannot isolate those roots, mark the run unusable. Record system/developer/custom instruction sources as well as loaded skill/conduct bytes; identical source hashes do not alone prove identical effective prompts.
4. Invoke the existing supported CLI pattern, with closed stdin unless reading an intentional prompt pipe. For Codex, the repository's pattern is `codex exec --sandbox read-only --skip-git-repo-check ... < /dev/null` (see `plugins/core/skills/task/references/codex-review.md`). Supply the pinned model, isolated working directory and assembled prompt using flags verified against that installed CLI's help. For Claude, use `claude -p ... < /dev/null`; for Cursor, verify `cursor-agent --help` and adapter resolution before choosing flags. These are invocation patterns, not a supplied isolation implementation. Do not run the developer's live global clone accidentally. Runtime fixtures use an authorized pass-owned writable sandbox as needed, separately from read-only review runs.
5. Alternate baseline/candidate order across pairs; use fresh sessions and reset owned fixtures between arms. Use identical cases, variant, model/settings and tools. Never let candidate sessions read baseline answers or vice versa.
6. Run one initial pair for every mandatory ID/variant/declared axis. Repeat each apparent improvement or regression in two additional independent paired trials. Preserve every attempt; rerun provider/tool-failure pairs after prerequisite recovery without counting failed infrastructure as successful evidence.
7. Adjudicate against every axis-assigned required item and clean guard with cited output/tool evidence, independently of the tested agent's self-score. Record per-item pass/fail/blocked/unexecuted and confirmed false defects. Every generated criterion is mandatory; evaluators cannot waive it. Explain disagreement with any apparent finding. Do not average away a missed mechanism.
8. Keep raw runs in pass-owned local artifacts. Commit only sanitized records/comparison. Record the SHA-256 hashes of cases, rubric and applicability, both snapshot hashes, per-run loaded file paths/digests/bytes, source revision, harness/model/settings, input/output tokens if available, wall time, tool calls, dispatch count, execution method, component/fixture pins, outcome, reuse/invalidation and cleanup. Report individual outliers and medians; attribute added work to required cases.

## Gates and limits

Every mandatory applicable rubric item must pass; clean variants must have zero confirmed false defects. No blocked/skipped/code-only/inherited record may become a fresh runtime PASS. Baseline-passing items may not regress. Demonstrated improvement requires at least one initial correction repeated in both confirmation pairs with no retained regression. All-parity or inconsistent differences mean effectiveness remains unproven. Runtime/harness gaps remain in the mandatory denominator.

Run the full comparison in the pinned primary harness. Validate adapter/reference resolution and representative C023–C027/C036–C038 cases in other supported harnesses where available; report anything unexecuted without generalizing primary-harness results. Existing context/catalog budgets remain mandatory. Structure/link/keyword checks, deterministic fixture checks, agent adjudication and actual runtime detection are distinct evidence classes.

## Local helper (implemented after production checks)

### Prerequisites

- Use Python **3.11 or newer** for `run.py` and the helper tests; the runner imports standard-library `tomllib`. No Python packages are required. Check with `python3 -c 'import sys, tomllib; print(sys.version)'`.
- Run `touch_probe.mjs` with Node exposing built-in `WebSocket`, `fetch` and `AbortSignal.timeout`, plus a local Chrome/Chromium supporting headless mode and CDP. Check Node with `node -e 'console.log(process.version); for (const value of [globalThis.WebSocket, globalThis.fetch, AbortSignal.timeout]) if (typeof value !== "function") process.exit(1)'`. The probe searches the macOS Google Chrome path and common Chrome/Chromium commands; set `CHROME` to an executable path and `PYTHON` to a Python 3.11+ executable when defaults differ.
- Install Poppler's `pdftoppm` and `pdftotext` only for C017 PDF render checks. Both commands must be on `PATH`.
- Install `ffmpeg` and `ffprobe` only for C018 media checks. The FFmpeg build needs the `lavfi` color/sine sources, `libx264` and AAC encoders, MP4 muxing, and H.264/AAC decoding. Binary presence alone does not establish codec support; generation/decode must succeed.
- Authorize and configure the chosen model CLI only for `pair --execute`. Exports, deterministic fixtures and their self-tests do not need a model or provider account.

Missing optional PDF/media tools produce skipped self-tests and leave the corresponding render/decode coverage blocked. Unavailable encoders or failed media generation also leave C018 blocked. Missing Chrome or Node's built-in WebSocket makes the touch probe report `blocked` and exit 2; failed assertions or unverified cleanup exit nonzero. These outcomes are not runtime PASS evidence. Native packages/devices, Safari behavior, OS keyboards and real mail delivery require their own execution surfaces; the local fixtures cannot establish those boundaries.

Run `python3 tests/evals/review-qa/run.py --help`. The helper uses Python's standard library; `pair` exports inputs by default and invokes Codex only with `--execute`. No evaluation runs are bundled. Example from the repository root:

```sh
python3 tests/evals/review-qa/run.py prepare --arm baseline --source .cache/review-qa/baseline --output .cache/review-qa/snapshots/base
python3 tests/evals/review-qa/run.py prepare --arm candidate --source . --output .cache/review-qa/snapshots/candidate
python3 tests/evals/review-qa/run.py pair --baseline .cache/review-qa/snapshots/base --candidate .cache/review-qa/snapshots/candidate --axis static_review --ids C001 C002 --variant a --trial 1 --output .cache/review-qa/runs/group1-a-t1
```

Add `--execute --model <resolved-model-id>` only for an authorized model run. Resolve the current model with `bin/devkit-model luna`; execution refuses an omitted `--model`. Dry exports need neither a model nor user configuration. Execution reads the current user's `model_reasoning_effort` and explicitly passes it despite ignored user config; `--effort` can pin an override. Keep model and effort identical across the comparison. Existing authentication remains available; neither `HOME` nor `CODEX_HOME` is changed. Each export records prompt/input/source digests. Execution uses a neutral temporary working directory, removed after completion. Snapshot roots are immutable after preparation. Baseline content is checked against frozen per-file hashes; candidate working-tree content is captured independently of HEAD.

Group one to eight compatible IDs in the same workflow; this is one request per arm, with independently graded rows. The helper rejects mixed frontend/Laravel entry skills and mixed browser/API-native entry profiles; keep those groups separate. Scope controls run alone. Select only IDs declaring that axis. Repeat for variant b. Trials alternate arm order and retain distinct directories. Never reuse an output directory or overwrite an attempt. The agent sees one variant per case and no rubric/polarity. The bounded recorded-input lane embeds the exact selected instructions and prohibits tools; a tool event invalidates it. This measures responses under those assigned bytes, **not** organic reference discovery or live browser operation. Validate adapter/reference routing separately.

Prepare an external evaluator's record after a run:

```sh
python3 tests/evals/review-qa/run.py grade-template --run .cache/review-qa/runs/group1-a-t1/baseline > .cache/review-qa/runs/group1-a-t1/baseline/grade.json
python3 tests/evals/review-qa/run.py score --run .cache/review-qa/runs/group1-a-t1/baseline --grade .cache/review-qa/runs/group1-a-t1/baseline/grade.json
python3 tests/evals/review-qa/run.py compare --root .cache/review-qa/runs
```

Fill `evaluator`, `independent_of_tested_agent`, the exact `answer_sha256`, and each criterion's status/reason/evidence references. The evaluator must inspect the answer and source/tool records; matching words or the tested agent's self-assessment is insufficient. Fault variants use the original observation IDs assigned by `applicability.json`; clean variants use the clean guard and false-defect audit without inventing an absent defect. Both polarities of `case_generation` additionally require `axis-case-generation`: concrete minimally sufficient cases with setup, action, expected observation and source. Every generated item must remain `applicable:true` and pass with evidence. `not_applicable`, disabling applicability, or omitting an item leaves coverage incomplete. An incorrect axis mapping requires a new frozen policy revision and both arms rerun, not an evaluator waiver. Record false defects and false runtime promotions explicitly. Missing runs/artifacts, empty answers, mismatched hashes, unevidenced claims and unexecuted criteria cannot score passed.

Execution seals the exact `export.json` bytes in `run.json.export_sha256`. Grading checks that seal and equality of exported identity fields before using either record. Recorded-input exports also check IDs/variant/axis against the frozen inputs and the actual prompt payload. Runtime imports receive the same binding. An altered/swapped export, changed run identity, or older run without a binding is rejected; rerun the attempt instead of retroactively adding a digest to old evidence.

`compare` retains the full mandatory ID × variant × declared-axis denominator, including runtime. Metadata comes only from the exact graded attempt; ungraded history cannot overwrite it. Duplicate graded keys are rejected. Retain failed/provider attempts in separate directories, and document why infrastructure attempts are excluded before assigning `grade.json` to the selected usable attempt.

Pin one baseline snapshot and one candidate snapshot across all scored units/trials, and one model, effort, harness version and frozen corpus across the comparison. Each unit must also preserve identical neutral input and `execution_settings` across arms and trials. A changed snapshot, tools/configuration or grouped input starts a new comparison. Missing pins do not inherit another run's values.

Credit improvement only when the **same criterion ID** fails on baseline and passes on candidate in all three pairs. Each credited confirmation needs a usable baseline row and a fully passed candidate row. Candidate false defects, false runtime promotions and other row failures block validation even when all individual criterion statuses say passed or baseline also failed. Preserve every criterion regression.

The summary exposes three different gates:

- `execution_complete`: every mandatory initial arm has a usable, adjudicated passed/failed row; failures still count as executed.
- `coverage_complete`: all mandatory candidate rows pass, pins match, required confirmations are consistent, and no retained row/criterion regression exists.
- `validation_complete` and its alias `complete`: coverage is complete, at least one same-criterion improvement repeats in all three pairs, and the independent scope/cost audit passes. Parity alone never completes validation.

## Independent scope/cost audit

Pass `compare --audit /absolute/path/to/audit.json`, or place `scope-cost-audit.json` at the comparison root. The evaluator must inspect actual control-case dispatch/reference loads and measured cost/budget evidence; a tested agent's success verdict is insufficient. Use this exact shape, replacing example paths and digests with real evidence:

```json
{
  "evaluator": "independent-reviewer-id",
  "independent_of_tested_agent": true,
  "corpus": {
    "cases.json": "708881dea8600942bf835102e8ad1649380460a787cd76ce2419d1cd65812b21",
    "rubric.json": "6d9572eda5693fec54ea5c6d0ffe23393fea0d99b41c717fc92c3492296654ac",
    "applicability.json": "6f3bb0da44383b75e4e7939bb5acb4506ace0d2d8397b107133ef81abdf29782"
  },
  "reviewed_run_sha256": ["sorted SHA-256 digests of every scored run.json, including repetitions"],
  "checks": {
    "C039": {"status": "passed", "reason": "Measured bounded static scope and dispatch/reference behavior.", "evidence": [{"path": "/absolute/control-static.json", "sha256": "actual digest"}]},
    "C040": {"status": "passed", "reason": "Measured bounded browser spot scope and dispatch/reference behavior.", "evidence": [{"path": "/absolute/control-browser.json", "sha256": "actual digest"}]},
    "cost_budget": {"status": "passed", "reason": "Compared loaded bytes, available tokens, wall time, tool/dispatch counts, outliers and context budgets; attributed added work to required cases.", "evidence": [{"path": "/absolute/cost-review.json", "sha256": "actual digest"}]}
  }
}
```

`reviewed_run_sha256` is the sorted list of hashes of the `run.json` beside every included `grade.json`; preserve duplicates when bytes match. All three checks require a reason and at least one existing artifact with matching bytes. Changed run records invalidate the audit. The helper verifies binding and structure; the independent evaluator owns the semantic scope/cost judgment.

## Import separately executed runtime evidence

### Launch local deterministic fixtures

Run these commands from the repository root:

```sh
python3 tests/evals/review-qa/runtime_fixture.py --help
python3 tests/evals/review-qa/runtime_fixture.py --case C020 --mode fault --max-seconds 60
python3 tests/evals/review-qa/runtime_fixture.py --case C020 --mode clean --max-seconds 60
node tests/evals/review-qa/touch_probe.mjs
PYTHONDONTWRITEBYTECODE=1 python3 tests/evals/review-qa/test_runtime_fixture.py
```

The two fixture commands each run a separate server, print its loopback `url` and owned `pid`, and stop after 60 seconds or on SIGINT/SIGTERM. Use the printed URL for the current run; C020's page is `/touch` and observations are at `/state`. `--case` accepts C012, C013, C015, C017, C018, C019, C020, C021, C029, C030, C031, C032 and C033; select `--mode clean` or `--mode fault` explicitly. The modes are evaluator setup, not labels to expose to a tested agent. Restart the fixture to reset its owned state between runs.

`touch_probe.mjs` starts its own fault and clean C020 servers and isolated temporary Chrome profiles, so it needs no manually started fixture. It dispatches trusted CDP touch events at the center and edge, checks the visible result and server actions, and verifies shutdown. It sends only SIGTERM to owned children; after a bounded grace period it reports cleanup as unverified, preserves a still-running browser's profile and PID for follow-up, and exits nonzero. It still attempts cleanup of every other owned child/profile. Do not delete a retained profile until its process has exited.

The Python self-tests exercise deterministic HTTP/worker fixtures and available PDF/media tools. The touch command exercises Chromium touch emulation; neither command is an agent benchmark, Safari/native acceptance or proof of an OS keyboard interaction. Keep unavailable/skipped surfaces in the unexecuted denominator. Launching a fixture alone is not evidence that an agent exercised or interpreted it.

`pair` refuses the runtime axis because supplied trace text is not a live fixture. Execute runtime fixtures with the owning browser/API/native tools. Import their evidence with:

```sh
python3 tests/evals/review-qa/run.py import-runtime --record /absolute/path/to/runtime-record.json --snapshot .cache/review-qa/snapshots/base --output .cache/review-qa/runs/runtime-C012-a-t1/baseline
```

The record requires `id`, `variant`, `kind` (`deterministic_fixture` or `agent_runtime_detection`), `command_or_tool`, `observations`, `source_run`, `component_pins`, `fixture_pins`, `runtime_method`, and `evidence` (a list of `{path,sha256}` pointing to real local artifacts). Keep all pins and artifacts synthetic/sanitized. The importer copies evidence and checks its bytes. Deterministic fixture checks always receive **zero agent runtime-detection credit** and remain unexecuted on that axis.

For `agent_runtime_detection`, additionally provide `agent_run` with:

- `command`, `model`, `effort`, `harness_version`, `trial` (1–3), `status` (`completed` or unusable), `elapsed_seconds`, `tool_calls` (positive);
- `prompt`, `answer`, `transcript`: each `{path,sha256}`, from the actual tool-using agent session; preserve complete transcript identity;
- `input_sha256`: digest of the identical neutral fixture contract/setup in both arms, without expected findings;
- `loaded_files`: the exact `{relative_path:{sha256,bytes}}` entries from the assigned snapshot, verified against actual session reads;
- `execution_settings`: a nonempty object recording effective sandbox, available/allowed tools, isolation/configuration flags and timeout/control settings. Keep it identical for both arms and all confirmation trials of that unit; do not copy recorded-input settings onto a tool-using runtime run.

A positive tool count or imported status is not a semantic PASS. Independently adjudicate actual observations and tool evidence using `grade-template`/`score`. Confirm the tested agent performed and interpreted the runtime action; deterministic results merely pasted into an answer do not qualify. The runtime fixture launcher must enforce snapshot/session isolation, record exact loaded bytes, reset owned fixture state and avoid leaking the rubric. The importer validates provenance structure and artifact integrity; it cannot prove that an arbitrary external transcript is truthful. Any missing execution or device boundary stays blocked/unexecuted.

Focused helper checks: `PYTHONDONTWRITEBYTECODE=1 python3 tests/evals/review-qa/test_runner.py`. These tests validate isolation/scoring mechanics; they are not the paired behavior benchmark.

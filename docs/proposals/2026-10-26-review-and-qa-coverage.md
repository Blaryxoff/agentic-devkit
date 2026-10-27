# Improve reviewer and QA coverage using observed escapes

Status: stages 1–6 and stage 7 helpers implemented; focused checks, static review and the full repository suite passed. The paired model benchmark has not run, so effectiveness acceptance remains unproven.
Date: 2026-10-26.
Baseline: agentic-devkit commit `1b92a77`.
Revision: incorporates the plan review and downloaded attachment evidence from 26 October.
Implementation evidence: [verification record](../../tests/evals/review-qa/RESULTS.md). Planned benchmark gates below remain unchanged; focused checks do not establish effectiveness.

## Objective

Make reviewers and runtime QA systematically generate and execute checks for the failure classes Elena Samanchuk found after feature implementation: state ownership, historical data, aggregate membership, operation-level authorization, deployed-build drift, generated outputs, telemetry accuracy, analytics dimensions, and touch/device behavior.

Preserve the existing workflow boundaries: static reviewers inspect and report, browser QA exercises browser behavior, verification owns non-browser runtime checks, and separately authorized coding workflows implement fixes. The outcome is evidence-backed coverage of applicable risks, not a promise that a checklist finds every bug.

## Evidence and limits

The investigation read all 1,057 comments on the 219 Ghostflow tasks currently assigned to Nikita Onishchenko and extracted 74 comments authored by Elena across 14 tasks. All comment pages were read. This is a snapshot of current assignments, not a complete historical attribution of development work.

An exact local extract is at `/Users/blaryx/www/grow-place/.codex/research/elena-comments-2026-10-26.txt`. It is a research artifact, not a portable dependency of this plan. The task keys and comment IDs below identify the evidence without copying account details, credentials, or the full private discussions into this toolkit.

All 81 attachments referenced by those comments were subsequently downloaded: 51 HTML reports, 6 Markdown documents, and 24 PNGs, totaling 296,554,664 bytes. File sizes and SHA-256 hashes were checked against the download manifest; no failures or partial files remain. The local manifest is `/Users/blaryx/www/grow-place/.codex/research/elena-attachments-2026-10-26/manifest.json`; it maps each file ID to its source task/comment, filename, size, and digest. Searchable text was extracted from all 57 reports/documents.

Selected report sections were reviewed, including attachments 13264, 13710, 13783, 13817, 13854, 13858, and 13909. Downloading or extracting a report does not establish that every report or screenshot has been inspected. The findings below remain QA-reported observations; this investigation did not reproduce them against the applications. Repository instructions, test source, and recorded results were also inspected.

The initial HTTP 401 was from `/api/files/:id/content`. Ghostflow commit `7a255399` enabled authenticated `/download` and `/blob` reads using the existing MCP credential; it added no MCP tool and did not enable `/content`. Retrieval is now verified. Keep attachment credentials out of URLs, reports, and fixtures.

### Observed failure classes

| ID | Source | Observation | Coverage argument |
|---|---|---|---|
| E01 | [GF-2947](https://ghostflow.ru/tasks/GF-2947), comment 8942, 18 September | A previously watched intro could not complete under a new purchase/access chain, although reported video coverage exceeded the threshold. | Test established users entering a new lifecycle; identify whether each fact belongs to the user or the current access context. |
| E02 | [GF-5884](https://ghostflow.ru/tasks/GF-5884), comment 9439, 13 October | One homework in two chapters shared attempts incorrectly; another placement disappeared from the rendered structure while remaining on the server. | Exercise reused entities, association identities, and multiple children, not only one model instance per fixture. |
| E03a | [GF-2408](https://ghostflow.ru/tasks/GF-2408), comment 8947, 18 September | Restoring a school restored members removed before school archival. | Restore only changes owned by the parent operation; preserve a child's earlier deletion. |
| E03b | Same task/comment; attachment 13269 | An archived school's domain appeared available during registration validation while it should remain reserved. | Verify availability and reservation through archive, restore, and release. Elena did not submit final registration, so successful domain takeover was not established. |
| E04 | [GF-5874](https://ghostflow.ru/tasks/GF-5874), comment 9440, 14 October | Duplicating a section moved its chapters and emptied the source. | Verify source preservation and destination independence for copy operations. |
| E05 | [GF-5945](https://ghostflow.ru/tasks/GF-5945), comment 9627, 20 October | A hidden draft lesson blocked the next section despite displayed 100% student completion. | Establish which members count toward both displayed progress and unlock conditions. |
| E06 | [GF-5679](https://ghostflow.ru/tasks/GF-5679), comment 9582, 19 October | A curator without content-management rights could create/update homework through draft endpoints; comparable lesson/folder writes were denied. | Enumerate operations and alternate endpoints within each permission decision. A denied main route does not prove a denied draft route. |
| E07 | [GF-6021](https://ghostflow.ru/tasks/GF-6021), comment 9654, 21 October | A trainer without admin access could not end a meeting; saving an unchanged meeting repeatedly shifted its time by three hours. | Include allowed non-admin actors and unchanged-save round trips, with timezone-aware display/wire/persistence checks. |
| E08 | [GF-5748](https://ghostflow.ru/tasks/GF-5748), comment 9442, 14 October | Certificate entry points differed across course layouts; transparent PNG signature/seal assets acquired a black background in PDFs. | Test distinct rendered implementations and the generated artifact's content, not only endpoint success. |
| E09 | [GF-5884](https://ghostflow.ru/tasks/GF-5884), comments 9441 and 9646, 14/21 October | Reminder mail was checked in the mail log; a later wording retest remained unverified because no new relevant mail existed. | Prove asynchronous outputs for the current case/build; a changed template or prior delivery is insufficient. |
| E10 | [GF-5949](https://ghostflow.ru/tasks/GF-5949), comment 9781, 26 October; [GF-6018](https://ghostflow.ru/tasks/GF-6018), comment 9785, 26 October | Builds changed during retests and accepted modules disappeared. The live-room summary reported 18 builds/checks; the training summary reported 10. | Preserve build identity through execution and rechecks; distinguish product defects, missing deployments, and repeated reports. |
| E11 | [GF-6018](https://ghostflow.ru/tasks/GF-6018), comment 9785, 26 October; [GF-5949](https://ghostflow.ru/tasks/GF-5949), comment 9781, 26 October | Mobile tabs did not respond to taps; iPhone input zoom and landscape layouts made actions unreachable. | Test touch actions and relevant keyboard/orientation states; DOM presence and overflow measurements alone do not prove usability. |
| E12a | [GF-2328](https://ghostflow.ru/tasks/GF-2328), comment 9492, 15 October | Financial summaries disagreed about bank/platform commission. | State contract-defined accounting equations and compare equivalent projections. |
| E12b | Same task, comment 9577, 19 October; attachment 13781 | A refund was accepted before an already-known insufficient-balance failure surfaced asynchronously. | Check known prerequisites before accepting work or producing disallowed side effects; distinguish immediate rejection from a legitimate later external failure. |
| E13 | [GF-5758](https://ghostflow.ru/tasks/GF-5758), comment 9682, 22 October; attachment 13854, extracted lines 18–36 | Desktop playback undercounted the final interval; seeking/resuming at the end could report 100% without watching; a final event after ending impersonation was attributed to the administrator. The report also raises an Android collection problem, with incomplete device/server verification. | Compare actual activity, emitted events, persisted metrics, and actor/context identity through seek, completion, exit, and session changes. Keep the Android claim at its stated evidence level. |
| E14 | [GF-2943](https://ghostflow.ru/tasks/GF-2943), comment 9686, 22 October; attachment 13858, extracted lines 191–210 | The same cohort showed 144 versus 377 new buyers across views with different date windows; a control cohort matched. Other sums paired cohorts by position rather than identity/date. | Align metric definition, cohort identity, segment, and window before comparing; use matching and deliberately mismatched controls. |
| E15 | [GF-5884](https://ghostflow.ru/tasks/GF-5884), attachment 13710, extracted line 26; [GF-5738](https://ghostflow.ru/tasks/GF-5738), attachment 13264, lines 2 and 73–92; [GF-5949](https://ghostflow.ru/tasks/GF-5949), attachment 13909, lines 27 and 489–492 | One Claude report explicitly revises a Codex report without a new live run. Another separates an earlier manual run from a later Playwright run with skips/expected failure. The live report reconciles results from different agents and builds. | Attribute evidence per case/run. A revised report, agent name, suite presence, expected failure, or screenshot alone is not a fresh successful execution. |

Attachment 13817 also distinguishes actual phone checks from unverified checks, including the PDF's visual appearance on Samsung. Attachment 13858 reports local unpublished automation with 14 passing and 3 failing cases, and says the export button was not exercised. Preserve those limits; do not describe the local scripts as shared runnable coverage or the export as verified.

### Reusable external evidence

- Elena explicitly handed over [ADDING-TESTS.md at commit 62bb34c](https://github.com/ElenaSamanchuk/platformax-qa-tests/blob/62bb34ce248226dc5aca5548cfae76f2931360b3/docs/ADDING-TESTS.md) in GF-5949 comment 9382. It was absent from that repository's main branch during the audit. It distinguishes requirements from implementation, reuses fixtures, preserves the first failure, and records build/role/evidence/cleanup. Several local tools are explicitly planned migrations rather than available shared commands.
- Her [live-room rules](https://github.com/ElenaSamanchuk/platformax-live-rooms-autotest/blob/main/RULES.md) require server-state evidence and reproduction counts. The [targeted media notes](https://github.com/ElenaSamanchuk/platformax-live-rooms-autotest/blob/main/docs/targeted-media-1026.md) distinguish decoded media from UI/device flags and separate runtime PASS from blocked recording checks. These main-branch links may change; capture their exact revisions before using them as implementation fixtures.
- Use these as evidence and inspiration. Do not import source or substantial wording without checking licensing and retaining required attribution. The implementation does not depend on private sessions, external repositories, or live customer data.

## Existing coverage to preserve

Paths and line numbers in this section refer to baseline `1b92a77`.

| Existing rule | Canonical location | Consequence |
|---|---|---|
| Independent expected-result provenance | [browser-qa-rules.md](../../plugins/core/conduct/browser-qa-rules.md), §4.11, line 267 | Improve requirement acquisition and precedence; do not add a competing expectation rule. |
| Theme/legacy implementation variants | Same file, §4.9, line 259 | Enforce the existing map; a shared feature name does not establish shared implementation. |
| Reuse old links after access revocation | Same file, §5.8, line 297 | Preserve this regression case; its omission in a run is an execution gap. |
| UI/request/persisted/reload/affected-role checks | Same file, §5.13, line 316 | Keep these authoritative checkpoints; add output-specific evidence where needed. |
| Narrow widths, full bounds, hit targets, clipped children | Same file, §5.15, line 332 | Add touch/device states without duplicating geometry rules. |
| First-failure preservation and cause classification | Same file, §7.5, line 436 | Retain product/test/data/environment/contract distinctions and retry history. |
| Retry, racing tabs, reconnect, replay, clock-skew probes | [risk-probe-gate.md](../../plugins/core/conduct/risk-probe-gate.md), lines 14–18 | Add ownership/history/invariant probes; do not create another generic chaos checklist. |
| All-write-path graphs, side effects, expiry, stateful views | [behavioral-completeness.md](../../plugins/core/conduct/behavioral-completeness.md), lines 13–26 | Extend this canonical protocol and route relevant reviewers to it. |
| Lowest-useful test level and criterion-to-case traceability | [test-implementation.md](../../plugins/core/conduct/test-implementation.md), lines 9–20 | Keep business edge cases at unit/integration level where sufficient; reserve runtime tests for distinct wiring risks. |

## Design decisions

1. Extend existing skills and conduct. Do not add a new top-level reviewer, QA skill, global service, dependency, or harness-specific workflow body.
2. Keep shared case generation in `behavioral-completeness.md`. Define a compact `runtime-qa-evidence.md` contract consumed by browser QA and runtime verification; retain browser mechanics in `browser-qa-rules.md`. Add two conditional references for specialized output and touch/device evidence.
3. Treat risk families as applicability decisions, not a Cartesian product. Record the selected cases and explain material exclusions; preserve spot/targeted/exhaustive semantics and focused rechecks.
4. Ground expectations in the current authoritative task/specification and subsequent decisions. Preserve conflicting or inaccessible requirements as named gaps; do not invent business behavior or demand a new ralphex plan when a task is sufficient.
5. Keep project incidents in this proposal and sanitized evaluation fixtures. Write portable mechanisms into shared conduct, without project names, production URLs, account IDs, or credentials.
6. Preserve reviewer independence. Setup information may come from the implementer; acceptance expectations and the coverage challenge must be checked against original sources.
7. Preserve current mutation, production, credential, browser ownership, fixture isolation, and cleanup boundaries. More coverage does not grant additional authorization.

## Implementation sequence

Freeze the stage 7 evaluation definitions and baseline snapshot before editing skills or conduct. Then implement stages 1–6, finish their non-test checks, and implement/run the stage 7 evaluations against both isolated snapshots. Stage 8 reconciles the resulting evidence; writing this proposal executes none of those stages.

### 1. Reconcile requirements and reviewer routing

Files:

- `plugins/core/conduct/inputs-grounding-gate.md`
- `plugins/core/conduct/behavioral-completeness.md`
- `plugins/core/conduct/reviewer-dispatch.md`
- `plugins/laravel/skills/reviewer-business-logic/SKILL.md`
- `plugins/frontend/skills/reviewer-business-logic/SKILL.md`

Changes:

- Add source acquisition for supplied task discussions, attachments/specifications, dated amendments, explicit scope decisions, and accepted deviations. Follow the consuming project's tracker access instructions; report unreadable/truncated sources.
- Record a compact requirement ledger: criterion ID, source/version/date, resolved expectation, applicable actors/surfaces, superseded decision or unresolved conflict. A later comment changes the contract only when its authority is established; recency alone is insufficient.
- Distinguish a requirement source from an execution record. Preserve report revision, original run date/build, method, and reuse/adjudication history; a later report edit does not establish a new test run.
- Allow useful static inspection when a source is missing, but distinguish static review outcome from behavioral acceptance and list criteria that cannot be established.
- Make Laravel/frontend business reviewers explicitly apply the shared behavioral protocol. Replace duplicated shared obligations with the reference while preserving stack discovery, defect taxonomy, evidence requirements, and read-only boundaries.
- Remove unconditional scope reconfirmation where the caller already supplied the scope. Do not make jobs, webhooks, or realtime behavior optional when a stated criterion depends on them.

Argument: current leaf input tables center on product/dev plans and permit code-only inference; current discovery/confirmation can miss relation-owned state or shrink an already stated flow. Strong browser expectation provenance does not repair a missing requirement that never reaches the ledger.

Acceptance: a task with a linked specification and a later approved change produces the resolved current criterion; an unresolved conflict remains unverified; a caller-specified scope proceeds without a redundant permission turn. Existing stack-specific obligations survive the refactor.

### 2. Generate relationship, history, and invariant cases

Files:

- `plugins/core/conduct/behavioral-completeness.md`
- `plugins/core/conduct/risk-probe-gate.md`
- `plugins/laravel/skills/reviewer-business-logic/SKILL.md`
- `plugins/core/conduct/review-specialist-fanout.md`
- `plugins/core/skills/test-case-creator/SKILL.md`
- `plugins/core/conduct/test-implementation.md`

Changes:

- Extend discovery beyond status-bearing models to stateful associations, placements, access chains, entitlements, and relationship records.
- For affected facts, identify authoritative storage and identity: tenant, actor, parent/placement, purchase/access cycle, and version where applicable. State what is intentionally shared, independent, retained, or reset.
- Challenge reuse and history: one object in two contexts; returning user with old progress; child deleted before parent archival; copy preserving source; restore/revoke/refund affecting only the state owned by that operation.
- Trace reservations through active, archived, restored, and released states. Verify that availability checks and mutation validation use the same contract-defined reservation boundary; do not infer availability solely from the active-record scope.
- Identify prerequisites known before acceptance, enqueueing, or mutation. Verify their required rejection point and absence of disallowed state changes, ledger entries, notifications, or jobs. Keep legitimate asynchronous external failures distinct; use atomic enforcement when the contract requires a concurrent reservation or balance check.
- Trace aggregate membership, exclusions, denominator, and agreement between related projections. Include hidden/draft/inaccessible records where the contract excludes them. Derive financial equations from the contract rather than inventing universal accounting rules.
- For analytics, pin metric definition/version, entity/cohort identity, segment, date window/timezone, and source population. Verify joins/grouping by identity rather than list position. Compare only contractually equivalent views; include one matching control and a case with shifted/misaligned windows. Resolve an ambiguous business window before asserting its correct numerical value.
- Add round-trip invariants for unchanged saves, repeated serialization, timezone conversions, and inverse operations. Keep retries and concurrency under the existing chaos probe.
- Expand authorization to actor × operation/entry point × resource scope/state. Enumerate alternate write paths such as draft, bulk, mobile, and specialized actions. Check both required allows and required denies.
- Have the testing specialist map applicable risks to existing assertions and identify uncovered contracts. Have case design select the smallest useful level; avoid duplicate scenarios and implementation-shaped assertions.

Argument: E01–E07, E12a/E12b, and E14 involve identity, relationships, history, reservations, precondition timing, membership, and invariants across otherwise valid states. A per-entity state graph and generic role × resource table do not force those questions.

Acceptance: the revised workflow generates independently scored cases for each applicable mechanism, including both E03a/E03b and E12a/E12b. A restore test cannot stand in for reservation validation; an accounting equation cannot stand in for pre-acceptance rejection. It does not demand these fixtures for a static copy edit or an unrelated visual spot check.

### 3. Challenge the QA ledger before execution

Files:

- `plugins/core/skills/browser/SKILL.md`
- `plugins/core/conduct/browser-qa-rules.md`, §§4–5 and §12

Changes:

- Extend the state/implementation map to consume applicable ownership, history, reservation, precondition, invariant, operation-permission, analytics, and output cases from step 2 and the relevant runtime references.
- Require the planning owner to challenge the proposed ledger against original requirements and applicable risk families before executor dispatch. Add missing cases or record material coverage gaps.
- Require the coverage reviewer to check omitted applicable scenarios, not only whether every submitted row has a result. Preserve top-level planning/adjudication ownership and existing worker model routing; do not add a standing reviewer layer.
- Keep each case bound to a source, expected visible/persisted/side-effect outcome, role, fixture state, surface/implementation variant, and evidence method. Allow shared evidence references rather than repeating metadata or checks.

Argument: checking every row of an incomplete ledger can produce a complete-looking report while never exercising E01, E02, or E05.

Acceptance: an intentionally deficient ledger containing only a fresh-user happy path is challenged with the applicable historical/reuse case. A bounded targeted request stays bounded and reports omitted dimensions.

### 4. Carry build identity and coverage through handoffs

Files:

- New `plugins/core/conduct/runtime-qa-evidence.md`
- `plugins/core/conduct/overview.md`
- `plugins/core/conduct/browser-qa-rules.md`, §§1.7, 2.2, 7, 12
- `plugins/core/skills/browser/SKILL.md`, reporting and review steps
- `plugins/core/skills/verify/SKILL.md`, API/worker/native runtime checks and reporting
- `plugins/core/skills/task/references/qa-brief-template.md`
- `plugins/core/skills/task/SKILL.md`, runtime QA handoff

Changes:

- Put the evidence record, statuses, reuse rules, and drift invalidation in the shared runtime contract. Require both browser QA and standalone API/worker/native verification to consume it. Apply it to runtime acceptance checks, not unrelated lint/typecheck or isolated unit-test commands.
- Record environment/origin, repository revision, deployed application revision, relevant module/configuration state, role/tenant, fixture IDs/state, and runtime/profile in reusable evidence pins. Do not equate local HEAD or a single unrelated chunk hash with the deployed feature build.
- For a flow spanning independently deployed components, identify relevant frontend, API, worker, and native-package revisions/configuration separately. Record unknown identity at the affected boundary rather than assuming all components match the API or repository revision.
- Use one reusable case record: criterion/source; case/run ID and time; execution method and actual engine/device; component/role/fixture pins; action/expected result; observed evidence; outcome and cause; cleanup; evidence reuse or invalidation reason. Distinguish live UI, executed automation, direct API, code inspection, screenshot-only, and inherited evidence. Use `passed | failed | blocked` for executed/adjudicated checks and explicitly report skipped/missing checks; an expected failure remains a known failure, not proof of healthy behavior.
- Check the available build signal before and after a connected lane, between execution waves, and before acceptance. If a build/configuration changes, partition results by revision and invalidate checks according to the existing impact map. Unclear impact remains unverified; do not restart unrelated proven work automatically.
- Verify required feature entry points/modules exist before expensive dependent execution. Treat chunk/file-count changes as diagnostic signals, never proof that a module is present or absent.
- Keep unknown build identity explicit. Continue useful checks where safe, but do not claim that prior fixes or cross-build results were verified on the intended revision without evidence.
- Replace the QA brief's bare PASS/FAIL format with canonical passed/failed/blocked results and explicit skipped/missing coverage. Require source and evidence pins for “already verified”; missing pins leave the claim unusable for acceptance.
- Link the brief to the shared evidence contract and the applicable browser/runtime execution rules. Add the same per-case runtime result block to `verify` when runtime QA is requested; its single Test row is only a summary. Preserve API/worker-only QA without requiring a browser.

Argument: E10 directly describes mixed-build retests and missing modules; E15 shows why report authorship and update time cannot substitute for execution provenance. The baseline pins a browser build at startup but does not explicitly require drift detection. The brief's skip section and two-status output are weaker than the browser skill, and standalone `verify` currently lacks the equivalent case/evidence record.

Acceptance: browser, API/worker-only, and native-runtime cases all preserve evidence identity through handoff. A simulated revision change cannot yield one aggregate acceptance result across incompatible builds; only affected cells are invalidated. A missing module blocks dependent checks without being reported as a passed feature or automatically blamed on product code. A rewritten report, inherited PASS, or unexecuted test file cannot be credited as a new run.

### 5. Verify outputs, asynchronous delivery, media, and telemetry

Files:

- New `plugins/core/conduct/qa-output-verification.md`
- `plugins/core/conduct/runtime-qa-evidence.md`, shared result/provenance fields
- `plugins/core/conduct/overview.md`
- `plugins/core/conduct/browser-qa-rules.md`, §§4–5
- `plugins/core/skills/verify/SKILL.md`

Changes:

- Add risk-based routing to the new reference when the contract includes generated files, recordings/media, notifications, telemetry, or other asynchronous outputs. Use the shared runtime evidence record for every executing surface.
- For generated files, open/parse/render the resulting artifact with available project tools. Verify required fields, selected template, relevant image transparency, links/QR, authorization, and supported download/open/back-navigation behavior. A successful download alone proves availability.
- For recording/media, separate requested/accepted, pending, ready, and actually playable/decoded outcomes. Verify mute from receiver-side media evidence where supported, preserving connection/track identity so disconnects or counter resets cannot imitate success. Use synthetic media where authorized; report real-device/media limits.
- For activity telemetry, trace actual activity → emitted events → authenticated actor/context → persisted intervals/counters → report. Define the observed quantity and permissible timing tolerance from the contract. A player's farthest position is not proof of watched duration when the requirement is unique viewing time.
- Include end-of-media and page-exit flushing, seek/resume without watching, replay/deduplication, and session/account/impersonation changes where relevant. Verify that late events retain the correct actor/context or are safely rejected under the contract; they must not migrate to the newly active account.
- Repeat the relevant collection-to-report check on supported client implementations when each owns separate instrumentation. A device screenshot or successful playback alone cannot establish server analytics. Incomplete Android evidence in E13 supplies a case to investigate, not a confirmed reproduction.
- For notifications, verify the promised channel, recipient, relevant content/link, timing, and duplicate behavior through an authorized test outbox/log/provider. Distinguish queued, sent, and delivered according to available evidence. A template inspection does not prove delivery.
- Leave inaccessible service/runtime cells unproven. Do not install new dependencies or operate paid/live integrations merely to satisfy the reference.

Argument: E08–E09 and Elena's media examples show that output availability, UI flags, and job completion are weaker than the user-visible result. E13 further shows that successful playback does not establish truthful duration, completion, or attribution in analytics.

Acceptance: a ready-but-unplayable recording, a PDF with lost transparency, and a queued-but-unsent required notification cannot pass from status fields alone. Telemetry cases expose missing final intervals, seeking counted as viewing, and events assigned to the wrong account. A correctly unavailable provider or unverified device/server boundary remains blocked coverage, not a fabricated product failure.

### 6. Verify touch and route device-specific obligations

Files:

- New `plugins/core/conduct/qa-touch-and-device.md`
- `plugins/core/conduct/overview.md`
- `plugins/core/conduct/browser-qa-rules.md`, §5.15
- `plugins/core/conduct/browser-layout-audit.md`
- `plugins/core/skills/verify/SKILL.md`

Changes:

- Require an actual touch-mode action and its expected navigation/state outcome for critical mobile controls. Retain width/bounds/clipping measurements; use center and relevant edge hit tests to diagnose interception where needed.
- Exercise portrait/landscape, focused input/keyboard viewport, sticky overlays, and the scroll path when the affected flow depends on them. Declare the browser engine, touch profile, scale, and actual device versus emulation.
- Require browser-specific evidence for Safari-specific claims and device/runtime evidence for native application behavior. Route native checks to the consuming project's configured runner/tools through verify; the toolkit has no general Flutter/native runner supplied by this proposal.
- Preserve app/package and server revisions plus case/method/fixture evidence under `runtime-qa-evidence.md` through that handoff. A native result cannot inherit a browser PASS solely because the business feature is shared.
- Preserve unavailable device/runtime cells as explicit coverage gaps. Do not label Chromium mobile emulation as iOS or native acceptance.
- Change the existing center-occlusion probe only if a diagnostic fixture demonstrates a missed case; do not add a new general scanner speculatively.

Argument: E11 contains actionable controls that were present but unusable. The existing center-point probe and mobile geometry rules are useful prerequisites, not touch/device execution proof.

Acceptance: an overlay-intercepted tab cannot pass from DOM geometry or a programmatic click. A Safari keyboard/zoom case and a native case remain unverified when only Chromium emulation is available.

### 7. Validate behavior, routing, and context cost

Before changing prompts, freeze sanitized case briefs, fixture definitions, expected findings, clean counterparts, and scoring rules under `tests/evals/review-qa/` (new). Use a case manifest and a README describing execution with existing supported harness commands; reuse current invocation helpers where applicable. Implement any required fixture/scoring code after the conduct/skill edits and non-test checks are complete. Do not make the evaluation depend on live project data or on the new prompts to generate its own answer key.

Each distinct mechanism in a family below receives its own stable subcase ID, fixture, expected evidence, and score. A family summary cannot hide a missed subcase. Mark which subcases evaluate static findings, case generation, runtime detection, or evidence adjudication; reasoning about a runtime case does not earn runtime-detection credit.

| Evaluation | Defective case and expected detection | Clean counterpart / overreach guard |
|---|---|---|
| V01 — ownership | Shared entity incorrectly shares placement state; another child disappears from the rendered structure; old completion prevents new-chain completion. Score these separately. | Explicitly shared state remains shared when required; all distinct authorized placements render; a fresh cycle follows its own reset rules. |
| V02 — history | Parent restore revives a previously deleted child; copy empties source. | Restore only parent-owned changes; independent copy leaves source intact. |
| V03 — membership | Hidden draft blocks unlock while visible members are complete. | A visible mandatory incomplete item still blocks; a draft counts only if the contract explicitly requires it. |
| V04 — permissions | Main route denies but draft/bulk route permits; allowed trainer path wrongly requires admin. | Authorized action succeeds; denied action changes no data; ownership mismatch stays denied. |
| V05 — invariants | Two unchanged saves shift time; specified financial projections disagree. | Preserve the original instant/value and contract-defined equations. |
| V06 — build drift | Browser build changes mid-lane; API/worker revision changes during an API-only run; native package/server versions differ from inherited evidence; required module is absent. | Stable matching evidence is reusable; unrelated changes invalidate only affected cells. Unknown component identity is reported at that boundary. |
| V07 — outputs | Certificate entry point is absent from one distinct implementation; PDF downloads with wrong rendered assets; recording is ready but not playable; required mail remains queued. | Each supported implementation exposes its required entry; valid artifact/playback/delivery has direct evidence; unavailable provider remains blocked. |
| V08 — touch/runtime | Overlay intercepts taps; focused-input viewport hides action; native assertion uses web emulation. | Real touch action works; engine/device coverage is labeled accurately. |
| V09 — requirements | Later authorized amendment conflicts with old plan; attachment unavailable. | Resolve sourced precedence; keep unknown expectation blocked without inventing behavior. |
| V10 — ledger/handoff | Happy-path-only ledger omits an applicable ownership case; old PASS lacks build/fixture pins in browser and standalone verify handoffs. | Challenge missing coverage; preserve matching unaffected evidence and bounded scope on each surface. |
| V11 — reservation | Archived resource is incorrectly offered as available before its reservation expires. Check availability and mutation validation without assuming final takeover occurred in E03b. | Active and archived reservations deny reuse; a contractually released resource becomes available; restore preserves its reservation. |
| V12 — pre-acceptance rejection | A known insufficient balance still creates an accepted refund/job or disallowed side effect. Observe rejection timing and resulting state. | Known failure rejects before acceptance with no disallowed side effects; sufficient balance succeeds; a genuinely later provider failure follows the specified asynchronous path. |
| V13 — telemetry | Score final-interval loss, seek/resume counted as watched time, wrong actor after impersonation/session change, and a missing client-to-server instrumentation path separately. | Known playback intervals, replay rules, completion, actor/context, and supported client reports agree within the contract's tolerance; incomplete device evidence remains unverified. |
| V14 — analytics dimensions | Same metric/cohort/segment is evaluated with inconsistent windows, or cohorts are joined by list position. Include a matching cohort and a deliberately mismatched-window control. | Identity-based matching and equivalent windows agree; legitimately different populations/windows are not falsely required to produce equal counts. An unknown correct window stays a contract question. |
| V15 — execution provenance | A report edit is counted as a new live run; screenshot/code-only evidence is promoted to execution; a suite with skips/expected failures is summarized as all healthy. | Preserve method, source run/build, individual outcomes, evidence reuse, and unsupported boundaries accurately. |

Paired evaluation protocol and gates:

- Compare baseline `1b92a77` with the candidate snapshot using the same frozen briefs, fixture state, harness/model revision, tool capabilities, and effort/settings. Use isolated sessions and explicit skill/conduct roots; record the exact files/digests actually loaded. Neither arm may silently read the installed global clone instead of its assigned snapshot. Alternate baseline/candidate order and reset owned fixtures between arms.
- Run one initial paired pass for every mandatory subcase and its clean counterpart. Repeat any apparent improvement or regression in two additional independent paired trials; preserve all attempts. Do not select only the successful repeat. Record tool/provider failures separately; an unusable pair is rerun when its prerequisite is recovered and does not count as successful evidence.
- Score against the frozen answer key with evidence-backed adjudication independent of the tested agent's self-assessment. Give cases neutral names and ordinary feature briefs. Score the required finding/case and its source or runtime evidence, not a matching phrase or a self-reported PASS.
- The candidate must satisfy every required rubric item in the mandatory subcases, produce zero confirmed false defects on clean counterparts, and never promote blocked/skipped/code-only/inherited evidence to a fresh runtime PASS. Require no regression on a baseline-passing item. An intentionally unavailable-device fixture passes only the evidence-classification evaluation; it does not establish device behavior.
- Claim demonstrated improvement only when at least one baseline miss or false acceptance is corrected in the initial pair and both confirmation pairs, with no retained regression. If both versions already satisfy a family, report parity. If the whole benchmark shows only parity or inconsistent differences, report effectiveness as unproven and reconsider the added rules or evaluation fixtures; do not mark improvement complete merely because outcomes were recorded.
- Record loaded instruction bytes, input/output tokens when available, wall time, tool calls, and dispatch count for each arm. Report medians and individual outliers; attribute added work to specific required cases. Unrelated spot/targeted control cases must retain their scope and dispatch behavior and must not load irrelevant output/device references. Existing catalog/context budgets remain mandatory; semantic gains do not waive them.
- Execute the full behavior comparison in the primary implementation harness with a pinned model. For other supported harnesses, validate adapter/reference resolution plus representative V09/V10/V15 cases where available; report unexecuted harness/model coverage explicitly. Do not generalize one harness's measured improvement to the others.

Validation layers:

1. Run link/reference checks and the existing resolver/context checks after the Markdown changes: `bin/devkit-resolve --validate --project=<temporary-consuming-project>` with a valid fixture toolkit config, `bash tests/context-efficiency.sh`, and applicable `tests/doc-canaries.sh` / `tests/stack-plugins.sh` checks after inspecting their scope and runtime. Re-anchor wording canaries deliberately when consolidating equivalent rules; do not treat wording presence as behavioral proof.
2. If the layout probe changes, add the defect and clean twin to the existing oracle fixtures and run `bash tests/browser-oracles.sh`. Report runtime skips separately from browser proof.
3. Run the paired protocol above for case selection, requirement handling, findings, and evidence adjudication. Store the frozen manifest/rubric, reproducible commands, per-run records, and a baseline/candidate comparison. Keep raw sessions and any secrets in pass-owned local artifacts; commit only sanitized reusable fixtures and summaries.
4. Use deterministic synthetic runtime fixtures for build drift on browser and API/worker paths, intercepted touch, output-state mismatches, and telemetry identity/timing. Keep runtime evidence distinct from an agent explaining what it would test. Declare unavailable runtime cases before scoring; retain them as incomplete coverage rather than shrinking the mandatory denominator after failures.
5. Verify routing/reference resolution in Claude, Codex, and Cursor using existing adapter tests and temporary consuming projects. Preserve names, triggers, read-only behavior, targeted scope, missing-capability reports, and metadata budgets. Temporary adapter generation must not modify real consuming projects.
6. Run `tests/run-all.sh` before a later push as required by the repository. Confirm first if it is expected to exceed the user's two-minute threshold. The plan-writing task itself does not require this suite.

Acceptance: the mandatory subcases meet the absolute rubric gates, paired runs demonstrate a repeatable gain without a retained regression, and scope/cost controls pass. Report incomplete runtime or harness coverage separately. If those conditions are unmet, validation is incomplete or failed; observing results or passing structure/keyword checks alone cannot close this stage.

### Evidence-to-delivery map

Use this map when preparing the case manifest and the final handoff. Preserve each distinct mechanism within a row as a separately scored subcase.

| Evidence | Implementation steps | Required evaluation families |
|---|---|---|
| E01 — new access cycle | 2, 3 | V01 |
| E02 — placement independence and missing child | 2, 3 | V01 |
| E03a — selective restore | 2, 3 | V02 |
| E03b — archived reservation | 2, 3 | V11 |
| E04 — source-preserving copy | 2, 3 | V02 |
| E05 — completion membership | 2, 3 | V03 |
| E06 — alternate write authorization | 2, 3 | V04 |
| E07 — allowed trainer and time round trip | 2, 3 | V04, V05 |
| E08 — variant entry points and rendered artifact | 3, 5 | V07 |
| E09 — actual notification output | 4, 5 | V07, V15 |
| E10 — build drift and missing modules | 4 | V06, V10 |
| E11 — touch/device behavior | 4, 6 | V08 |
| E12a — accounting agreement | 2, 3 | V05 |
| E12b — known failure before acceptance | 2, 3 | V12 |
| E13 — telemetry truth and attribution | 2, 4, 5 | V13 |
| E14 — analytics identity/window alignment | 2, 3 | V14 |
| E15 — method/run provenance | 1, 4 | V09, V10, V15 |

### 8. Review and handoff

- Review the finished diff for preserved obligations, removed duplication, canonical routing, and privacy. Run deep plus business-logic review for executable changes; evaluate conduct-only changes with the applicable generic fallback and skill-creator workflow.
- Report the evidence-to-delivery map with implemented rules, independently scored subcase results, paired baseline/candidate outcomes, remaining runtime/harness gaps, changed paths, and text/context/runtime cost changes.
- Keep the implementation staged so shared behavioral rules, handoff/build evidence, and conditional runtime references can be reviewed independently.
- Do not commit, push, deploy, regenerate real project adapters, or update the installed global clone as part of this proposal. Perform those only under a subsequent explicit request. A later agentic-devkit deploy must follow the user's full target list, not just update this Mac.

## Completion criteria

- Every evidence row E01–E15, including E03a/E03b and E12a/E12b, maps to an applicable rule, separately scored mechanisms, and the runtime evidence needed where static inspection is insufficient.
- Existing revocation, variant, persisted-state, failure-classification, mutation, isolation, and cleanup obligations remain intact.
- Laravel/frontend reviewers explicitly consume shared behavioral conduct; updates do not depend on an unreferenced generic document.
- QA planning challenges missing cases; browser, API, worker, and native runtime results retain valid requirement, component revision, role, fixture, method, and surface evidence through handoffs.
- Output/touch/device references load only for relevant risks, and unavailable capabilities never become PASS.
- Paired baseline/candidate evaluations satisfy stage 7's detection, false-positive, evidence-classification, improvement, and scope/cost gates. Runtime checks, agent evaluations, and document validation are reported separately; no result from the downloaded reports is counted as this implementation's benchmark run.
- No new always-on services, dependencies, top-level skills, customer-data fixtures, or cross-project rollout are introduced by default.

## Main tradeoffs

| Tradeoff | Resolution |
|---|---|
| More coverage can inflate context and runtime. | Use applicability decisions, compact shared ledgers, conditional references, and existing focused recheck rules. |
| Incomplete specifications can cause either invented expectations or unnecessary stops. | Continue evidence-backed static work; isolate unresolved criteria and withhold acceptance only for the affected contract. |
| Synthetic media/device modes cannot prove every real environment. | Label exact evidence boundaries and require the actual engine/device when the claim depends on it. |
| Consolidating reviewer text can silently remove stack rules. | Compare old/new obligations explicitly and validate routing plus representative stack scenarios. |
| Build signals may be unavailable or incomplete. | Record unknown identity, verify what is observable, and avoid attributing a previous result to an unverified revision. |
| Better instructions may still be ignored in execution. | Validate case generation and adjudication with controlled evaluations; keep evidence gates in the handoff and final result. |
| Existing prompts may already pass the benchmark. | Report parity, not improvement. Reconsider added instructions or strengthen an independently justified fixture; freeze any rubric revision and rerun both arms. |
| Reports mix methods, runs, revisions, and levels of certainty. | Preserve per-case provenance; distinguish reported findings from reproduced results and intended coverage from executed coverage. |

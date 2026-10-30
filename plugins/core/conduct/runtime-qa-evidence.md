# Runtime QA Evidence

## 1. Scope and records

- Apply this contract to browser, API, worker, and native runtime acceptance checks, including executed integration automation. Keep unrelated lint, typecheck, and isolated unit-test commands under their existing verification rules.
- Resolve expectations from the current authoritative sources under [inputs-grounding-gate.md](./inputs-grounding-gate.md). Select applicable cases within the supplied scope; name material exclusions and unresolved criteria.
- Keep a reusable case ledger with the fields below. Reference shared run/component/fixture records instead of copying identical metadata into every row. A browser spot pass retains its scoped assertion, provenance and outcome in the existing one-line report/evidence; it does not add a ledger or dispatch stages that its workflow explicitly skips.

| Record | Required evidence |
|---|---|
| Criterion | Stable criterion ID, source/version/date, resolved expectation or unresolved contract |
| Execution | Stable case and run IDs, original execution time, report revision/time |
| Method | Live UI, executed automation, direct API/worker probe, code inspection, screenshot-only, or inherited evidence; command/tool and actual engine/device/runtime/profile |
| Components | Environment/origin; repository revision; independently observed deployed frontend, API, worker, native-package revisions where involved; relevant module, feature/configuration state |
| Actor | Role, tenant/resource scope, authenticated actor and session/context relevant to the assertion |
| Fixture | Identifiers, initial state/history, version or reset boundary needed to reproduce the case |
| Assertion | Action, expected visible/persisted/output result, and the boundary actually exercised |
| Observation | Actual result and durable evidence reference, including relevant requests, events, artifacts, logs, or traces |
| Outcome | `passed`, `failed`, or `blocked`; cause, uncertainty, and next prerequisite where applicable |
| Cleanup | Owned resources, required restoration, completed cleanup or remaining obligation |
| Reuse | Source case/run and pins; reuse, adjudication, or invalidation decision with reason |

- Label evidence at its actual strength. A report revision records editing, not a new execution; preserve the original run/build and distinguish later adjudication from a retest.
- Identify each relevant component separately when a flow crosses independent deployments. Record unknown identity at that boundary; neither local HEAD nor an unrelated asset hash proves the deployed feature revision.
- Verify required runtime entry points/modules and implementation variants exist before expensive dependent execution. Treat file/chunk counts as diagnostic clues; establish availability from the relevant runtime surface.
- Use project-authorized test fixtures and configured runtimes. Before declaring a recoverable prerequisite blocked, attempt the available authorized fixture, login, configuration, or service recovery and record its result.
- Preserve execution boundaries: use [browser-qa-rules.md](./browser-qa-rules.md) for browser authentication, fixture isolation, process ownership, and cleanup; use the project's equivalent rules for other runtimes. Additional coverage grants no authority to alter real credentials, production data, or shared processes.
- Apply [test-implementation.md](./test-implementation.md#data-ownership-and-cleanup) → **Data ownership and cleanup** before provisioning database fixtures and through teardown on every runtime; record verified connection identity, exact owned resources, disposal scope and remaining obligations.
- Load [qa-output-verification.md](./qa-output-verification.md) only for generated artifacts, media, notifications, telemetry, or asynchronous-output assertions.
- Load [qa-touch-and-device.md](./qa-touch-and-device.md) only for affected touch, browser-engine, device, or native-runtime assertions.

## 2. Revision and evidence reuse

- Capture available component build/configuration signals before and after a connected execution lane, between execution waves, and before acceptance. Record the observed signal and its time; do not silently substitute a repository checkout for a deployed identity.
- Compare component, requirement, fixture, actor, method, and surface pins before reusing a result. Preserve matching unaffected evidence and link to its original run.
- Partition results by revision when a component or relevant configuration changes. Use the dependency/impact map to invalidate affected cases and their dependent assertions; rerun only those cells.
- Keep unclear impact unverified at the affected boundary. Unknown change scope does not authorize either a blanket PASS or an automatic restart of unrelated proven work.
- Recheck an unknown component identity using available deployment/runtime signals. Continue safe useful checks, but withhold intended-revision or prior-fix acceptance where matching cannot be established.
- Revalidate expectations when authoritative requirements change. Retain the earlier result as historical evidence and re-adjudicate or rerun only the affected criteria.
- Preserve functional and visual/runtime dimensions independently. A missing device or layout check leaves that dimension open without erasing a supported functional result.
- Treat a report edit, resume, recovered permission, or tool/configuration recovery alone as no new application execution. Reuse prior evidence only after confirming the recovery did not change its relevant pins.
- Keep an observed failure until an implementation change or genuinely conflicting evidence justifies a focused recheck. Preserve the first failure and every relevant retry; a later success does not erase history.

## 3. Outcomes and handoff

- Mark a case `passed` only when the observed evidence establishes its expected result on the recorded boundary. Record `failed` when an executed assertion disagrees; use `blocked` when a required prerequisite or evidence boundary cannot be established after authorized recovery.
- Split compound checks into identifiable subchecks when their actors, boundaries or outcomes differ. Preserve each outcome; a parent with an unproven obligation cannot be `passed`. Report partial success and remaining gaps separately instead of counting “passed for reachable cases” as complete coverage.
- Report skipped and missing checks explicitly outside successful coverage, with their reason and affected criterion. Keep runner-marked known failures (`xfail` / `test.fail`) visible even when the suite exits successfully. A negative case that proves the required rejection is a passing assertion, not a known product failure.
- Classify causes as product, test/setup, data, environment, or unclear contract after inspecting the relevant session, fixture, network, and server signals. Promote only confirmed product failures to product defects.
- Preserve unresolved cause as uncertainty and name the next discriminating check. Missing deployment/module/provider evidence blocks dependent acceptance; it does not by itself prove faulty product code.
- Separate code inspection, screenshots, inherited reports, and fresh execution in summaries. Unexecuted automation and screenshot-only evidence cannot prove an interaction or end-to-end output.
- Report the action and resulting behavior actually verified. A successful request, job, status flag, download, or playback screen cannot stand in for the promised persisted result, delivered content, or decoded media.
- Hand off the scoped ledger, source and component pins, evidence references, reuse decisions, missing/skipped/blocked cells, findings, and cleanup obligations. A bare inherited PASS without usable source/run/build/fixture pins remains unverified for acceptance.
- Summarize runner totals and per-case outcomes separately. Keep partial success visible without claiming full acceptance while required coverage or evidence remains open.

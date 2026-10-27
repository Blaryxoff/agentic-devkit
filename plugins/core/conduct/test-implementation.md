# Test Implementation Contracts

Use this document for tester workflows together with the project test policy and [agent-test-restraint.md](./agent-test-restraint.md). Testers may author tests before production behavior exists, using approved cases and the public contract; preserve production source.

## Scope and traceability

- Require identified test-case documents for tester implementation. When cases are missing, route to `devkit-test-case-creator`; do not silently invent scenarios from vague acceptance criteria inside the tester.
- Map each implemented test to a case ID or named case and public behavior. Report omitted, blocked, or failing cases with expected/actual results and evidence; write tests only, preserving production code.
- Select the lowest level that establishes the contract: unit for isolated logic, integration for real middleware/transaction/IPC/native wiring, E2E for critical user paths. Avoid duplicate scenarios unless a different boundary risk justifies both levels.
- Use scenario-oriented names and Arrange/Act/Assert. Keep one behavior per test; multiple assertions may describe that outcome. Use parameterized cases rather than branching, error suppression, or unrelated flow loops inside tests.

## Test-case handoff

- For requested test design, record each case's ID/title, requirement, test level/priority, actors/permissions, preconditions/fixtures, inputs, action, expected visible and persisted outcome, side effects, and cleanup. Keep implementation files organized by source/feature using the consuming runner's conventions.
- Cover happy, boundary/empty/null, validation/denial, concurrency, retry/cancellation, and relevant platform lifecycle cases from the actual requirement. Use a criterion-to-case ledger to expose missing coverage; do not duplicate a lower-level scenario at E2E without a distinct wiring risk.
- Apply `behavioral-completeness.md` → **Risk-driven case generation** to the affected contracts. Give each distinct mechanism its own case ID, identity/history fixtures and observable outcome; one family label cannot stand in for untested mechanisms. Reuse the requirement/source ledger and challenge applicable omissions before handoff.
- Preserve execution provenance with results: source/run/build, actual method/surface, outcome, cause and evidence. Runtime checks use `runtime-qa-evidence.md`; authored tests, code inspection, expected failures and inherited evidence do not become a new runtime PASS.
- Hand case documents to the tester separately from production changes. Record the intended stage: preimplementation RED, passing characterization, or completed-behavior verification. Missing product behavior goes back to the task owner; a testcase designer does not invent requirements.
- Report observed expected RED separately from unexpected failures, blocked execution, and passing tests. RED must reach the intended behavior assertion or expected-error check; import, compiler, fixture, or environment failures do not prove the behavior gap. Return expected RED to the coder for implementation; do not mark the feature complete.

## Isolation and quality

- Control time/timezone, randomness, IDs, locale, network, and data fixtures. Tests must be order-independent and safe in parallel; clean database rows, jobs, timers, listeners, windows, and resources they own.
- Use project factories/builders and reusable fakes at owned integration boundaries. Unit tests do not use live SQL/Redis/mail/paid APIs; real integration checks use isolated test services and approved sandbox endpoints.
- Assert returned/rendered results, stable error contracts, persistence, authorization, and required side effects. Avoid private method testing, snapshots of arbitrary internal structures, and mocks that merely repeat implementation calls.
- Exercise critical logic branches and high-damage failures identified by the cases. Honor configured coverage thresholds and report uncovered required paths; a coverage percentage does not replace a missing behavior oracle.
- Use installed runner/preset/renderer versions and the package's existing script. Keep one focused command per affected package, then expand only when policy or risk requires it; honor user limits for long suites.
- Preserve the failure report for production fixes under `devkit-coder`; do not repair production source inside a tester or weaken assertions to get green.

## Selective mutation testing

- Use mutation testing when explicitly requested or required by project policy; otherwise propose a focused pilot only when changed high-risk logic needs stronger assertion evidence, such as authorization, financial calculations, or state transitions. Follow the project's test-execution policy and time limits.
- Use the project's installed, configured mutation runner and focused test command after the baseline passes. Scope execution to the affected logic in an isolated workspace; keep production code and unrelated work intact. Obtain approval before adding dependencies.
- Review surviving mutants against required behavior. Add or strengthen tests only when project permissions and the task's authoring scope allow it; report equivalent or irrelevant mutants with a reason instead of changing behavior to improve a score.
- Report the runner, scope, baseline, detected and surviving changes, uncovered sites, and tool exclusions. Separate assertion-detected changes from compilation failures, timeouts, or infrastructure failures when the runner exposes them; disclose when its score combines these outcomes.
- Treat mutation, coverage, complexity, and structural-similarity scores as evidence for review. Apply only project-configured thresholds; do not impose universal CRAP, duplication, or mutation-score gates, or extract shared code solely to satisfy a similarity score.

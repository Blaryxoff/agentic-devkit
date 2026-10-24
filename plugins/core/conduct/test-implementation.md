# Test Implementation Contracts

Use this document for tester workflows together with the project test policy and [agent-test-restraint.md](./agent-test-restraint.md). Test authoring begins after production implementation and applicable non-test checks are complete.

## Scope and traceability

- Require identified test-case documents for tester implementation. When cases are missing, route to `devkit-test-case-creator`; do not silently invent scenarios from vague acceptance criteria inside the tester.
- Map each implemented test to a case ID or named case and public behavior. Report omitted, blocked, or failing cases with expected/actual results and evidence; write tests only, preserving production code.
- Select the lowest level that establishes the contract: unit for isolated logic, integration for real middleware/transaction/IPC/native wiring, E2E for critical user paths. Avoid duplicate scenarios unless a different boundary risk justifies both levels.
- Use scenario-oriented names and Arrange/Act/Assert. Keep one behavior per test; multiple assertions may describe that outcome. Use parameterized cases rather than branching, error suppression, or unrelated flow loops inside tests.

## Test-case handoff

- For requested test design, record each case's ID/title, requirement, test level/priority, actors/permissions, preconditions/fixtures, inputs, action, expected visible and persisted outcome, side effects, and cleanup. Keep implementation files organized by source/feature using the consuming runner's conventions.
- Cover happy, boundary/empty/null, validation/denial, concurrency, retry/cancellation, and relevant platform lifecycle cases from the actual requirement. Use a criterion-to-case ledger to expose missing coverage; do not duplicate a lower-level scenario at E2E without a distinct wiring risk.
- Hand case documents to the tester separately from production changes. Missing product behavior goes back to the task owner; a testcase designer does not invent requirements.

## Isolation and quality

- Control time/timezone, randomness, IDs, locale, network, and data fixtures. Tests must be order-independent and safe in parallel; clean database rows, jobs, timers, listeners, windows, and resources they own.
- Use project factories/builders and reusable fakes at owned integration boundaries. Unit tests do not use live SQL/Redis/mail/paid APIs; real integration checks use isolated test services and approved sandbox endpoints.
- Assert returned/rendered results, stable error contracts, persistence, authorization, and required side effects. Avoid private method testing, snapshots of arbitrary internal structures, and mocks that merely repeat implementation calls.
- Exercise critical logic branches and high-damage failures identified by the cases. Honor configured coverage thresholds and report uncovered required paths; a coverage percentage does not replace a missing behavior oracle.
- Use installed runner/preset/renderer versions and the package's existing script. Keep one focused command per affected package, then expand only when policy or risk requires it; honor user limits for long suites.
- Preserve the failure report for production fixes under `devkit-coder`; do not repair production source inside a tester or weaken assertions to get green.

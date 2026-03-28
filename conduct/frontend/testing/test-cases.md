# Test Case Guidelines

Language-agnostic rules for planning and designing frontend test cases.

## Core rules

1. One behavior per test case.
2. Tests are independent and deterministic.
3. Cover happy path, edge cases, and failure path.
4. Prefer readable scenario descriptions over implementation details.
5. Avoid duplicate coverage across test layers.

## Recommended layering

- **Unit**: composables, utils, isolated component logic
- **Integration**: component + state + API interaction boundaries
- **E2E**: critical user journeys only

## AAA structure

Every test case follows Arrange / Act / Assert:

- Arrange: initial state, mocks, inputs
- Act: user action or function call
- Assert: expected output/state/side effects

## Naming

Use descriptive names:

`[subject]_[condition]_[expectedResult]`

Example:

`catalogFilters_withValidQuery_restoresStateFromUrl`

## Pre-submission checklist

- [ ] Name is descriptive
- [ ] Scenario and expected result are explicit
- [ ] At least one negative/edge case exists
- [ ] Case is stable and reproducible

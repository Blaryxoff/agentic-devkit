# Test Case Guidelines

> This document defines language-agnostic rules for planning and designing test cases — what to test, how to structure
> test cases, and how to organize them. For PHP/Laravel-specific implementation rules (tooling, mocks, code patterns),
> see [php-testing.md](./php-testing.md).

---

## 1. Purpose

This document defines the standard rules and structure for writing test cases across all test types. All testers and
developers must follow these guidelines to ensure tests are consistent, readable, maintainable, and trustworthy across
the codebase.

---

## 2. General Rules (All Test Types)

### 2.1 Easy to read and understand

Each test must be easy to read and understand by both humans and LLMs, as it is used as a main code verification method.
Prefer visual representation (tables, schemas, etc.) over prose.

### 2.2 One Behavior Per Test

Each test must verify exactly one behavior. If a test checks two things at once, split it into two separate tests.

### 2.3 Tests Must Be Independent

Tests must not depend on the order they run or on shared mutable state. Each test must set up and tear down its own
data.

### 2.4 Tests Must Be Deterministic

The same input must always produce the same result. Avoid relying on random values, current timestamps, or any
non-deterministic data unless explicitly controlled.

### 2.5 No Logic Inside Tests

Avoid conditionals, loops, or error suppression inside a test body. If logic seems necessary, the test should be split
or the code under test should be refactored.

### 2.6 Test Both Happy and Sad Paths

For every behavior, cover:

- **Happy path** — valid input, expected outcome
- **Edge cases** — boundary values, empty input, null, zero
- **Error cases** — invalid input, expected failures or exceptions

### 2.7 One Assert Per Test (Preferred)

Each test should ideally contain a single assertion. Multiple assertions are only acceptable when they verify different
facets of the same single outcome.

### 2.8 No Redundant Test Cases

Cover only what is essential. Each test case must add unique coverage — do not duplicate scenarios already verified by
another test at the same or lower level. If a behavior is already tested by a unit test, do not repeat it in an
integration or E2E test.

### 2.9 Prefer Unit Tests

If a behavior can be verified with a unit test, use a unit test. Unit tests are the fastest, most stable, and cheapest
to maintain. Only escalate to a higher-level test type when the behavior genuinely cannot be covered at the unit level.

### 2.10 Feature/Integration Tests for Complex Flows Only

Propose Feature/Integration tests only for flows that span multiple Laravel components and cannot be meaningfully
verified by unit tests alone. These tests should fake or mock external dependencies (third-party APIs, queues, mail,
message brokers) and focus on verifying the interaction between internal components.

### 2.11 E2E for Basic Critical Paths Only

E2E tests validate only the basic critical paths through the system. All edge cases, error scenarios, and behavioral
nuances must be handled by Unit and Feature tests. E2E tests exist to confirm that the full stack (Nginx -> Laravel ->
Inertia -> Vue/Tailwind) is wired correctly — not to exhaustively test business logic.

---

## 3. Test Case Structure — The AAA Pattern

Every test must follow the **Arrange / Act / Assert** pattern.

| Phase       | Description                    | What Goes Here                                       |
|-------------|--------------------------------|------------------------------------------------------|
| **Arrange** | Set up the preconditions       | Create objects, seed data, configure dependencies    |
| **Act**     | Execute the subject under test | Invoke the single behavior or flow being tested      |
| **Assert**  | Verify the result              | Check the return value, state change, or side effect |

---

## 4. Test Naming Convention

Test names must be descriptive and self-explanatory. A good name answers: *What is being tested? Under what condition?
What is the expected result?*

**Format:** `[subjectUnderTest]_[scenario]_[expectedBehavior]`

**Examples:**

- `storeReferral_withValidPayload_persistsRecord`
- `login_withInvalidPassword_rejectsAuthentication`
- `profileUpdate_withValidInput_redirectsAndPersists`

> **Avoid** vague names like `test1` or `testFunction`. The name alone should make any failure self-explanatory.

---

## 5. File Location & Organization

All tests must be placed in the correct folder for the Laravel stack:

```text
tests/
├── Unit/
├── Feature/
└── Browser/ (if E2E is enabled)
```

Mirror the source structure for Unit tests and organize Feature/E2E tests by user-facing flow. A test file must
correspond directly to the class, endpoint, or flow it covers.

For Inertia pages, place assertions in the Feature tests that hit the related routes/controllers. For Vue
component-level behavior, use the frontend test setup if present and keep those tests near the frontend source.

---

## 6. Pre-Submission Checklist

| # | Checklist Item                                   | Required |
|---|--------------------------------------------------|----------|
| 1 | Test name follows the naming convention          | ✅ Yes    |
| 2 | Test uses AAA structure (Arrange / Act / Assert) | ✅ Yes    |
| 3 | Test covers at least one happy path scenario     | ✅ Yes    |
| 4 | Test covers at least one error or edge case      | ✅ Yes    |
| 5 | Test is independent and order-agnostic           | ✅ Yes    |
| 6 | No logic (conditionals/loops) inside test body   | ✅ Yes    |
| 7 | Test file is placed in the correct stack folder  | ✅ Yes    |


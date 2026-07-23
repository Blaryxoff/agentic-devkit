# Agent Test Restraint

Test permission and execution policy are owned by the consuming project. Test-authoring timing is owned by this toolkit.

## Hard rule: tests are the final coding phase

During continuous implementation, do not create or update tests alongside each production-code iteration.

When tests are intended by the task and allowed by project policy:

1. Finish all requested production code, configuration, documentation, and cleanup first.
2. Make the applicable non-test checks green: lint, type check, manual review, smoke checks, and security spot-checks.
3. Only then, at the commit-ready handoff stage, create or update the tests in one focused pass.
4. Run the eligible test command according to project policy.

If a late production-code change invalidates the new tests, finish that production-code iteration and restore the non-test checks before revisiting the tests. Do not alternate production edits and test rewrites as a red/green development loop.

A test-only task for already-complete production code starts at the final test phase, but the agent must still establish that the related implementation is complete and its applicable non-test checks are green before editing tests.

## Where the policy lives

Each project declares its own test rules in its root agent-memory files:

- `CLAUDE.md` — for Claude Code
- `AGENTS.md` — for OpenAI Codex / Cursor (when applicable)

If neither file exists, or neither contains a `## Tests` (or equivalent) section, the **default fallback** is: *do not create test files and do not run test suites unless the user explicitly asks*.

A copy-pasteable template that projects can adopt lives at [`howto/project-test-rules.md`](../../../howto/project-test-rules.md).

## What the project file is expected to answer

Before running any test command or generating any test artifact, the agent must read the project's `CLAUDE.md` / `AGENTS.md` and resolve:

1. **When to run tests** — always, only on explicit request, never automatically, etc.
2. **What command to run** — the exact invocation (e.g. `php artisan test`, `pnpm test`, `make test`).
3. **What to do on failure** — fix, report, hand off to the user.
4. **Whether new test files may be created** — and under what conditions.

If the project file is silent on any of these, apply the conservative default: do not run tests, do not create test files, ask the user.

## What is NEVER deferred (always expected without being asked)

Even when test execution is gated by project policy, agents must still verify their own work through other means on every change:

- **Lint** — check for linter violations introduced by the change.
- **Type check** — run static analysis when the stack supports it.
- **Manual review** — read back the written code, trace logic paths, check edge cases.
- **Smoke-check** — verify routes parse, migrations are valid, configs load, etc.
- **Security spot-check** — scan changes for obvious vulnerabilities (exposed secrets, raw SQL, missing auth).

The point of this rule is to prevent agents from producing unwanted test artifacts and consuming time on test suites the user did not ask for — not to excuse agents from verifying their code works.

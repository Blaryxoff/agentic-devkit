# Agent Test Restraint

Test execution policy is owned by the consuming project, not by this toolkit. The toolkit only enforces the discipline of looking up that policy before touching tests.

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

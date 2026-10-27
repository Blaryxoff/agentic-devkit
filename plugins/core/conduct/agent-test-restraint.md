# Agent Test Restraint

Test permission, commands, execution limits, and project-specific timing are owned by the consuming project. Use the defaults below when the project permits tests and does not prescribe another development sequence.

## Test-first defaults

Use test-first development for reproducible defects and clear behavioral contracts. Resolve project permissions before creating test artifacts or running commands; test-first timing grants no additional permission.

Choose the sequence from the change:

- **Bug fix:** write or update a focused regression test and observe it fail for the reported defect before changing production behavior. Make the smallest fix, observe the test pass, then refactor while preserving that behavior.
- **Clear business behavior:** derive expected outcomes from requirements, write one focused behavior test, observe the expected failure, implement the behavior, and refactor. Repeat in small units for permissions, calculations, validation, state transitions, and retry semantics.
- **Refactoring:** establish passing behavior or characterization tests before changing structure. Keep them green; do not invent a failing requirement for a behavior-preserving change.
- **UI exploration, prototypes, or infrastructure:** allow implementation first while the contract or automated testing surface is unsettled. Record why test-first is impractical and the alternative verification before production edits; add permitted tests once behavior is concrete.
- **Test-only work:** implement the approved cases against the existing or planned public contract. Report expected preimplementation failures to the coder; preserve production source.

An expected RED result must reach the intended behavior assertion or expected-error check. Missing imports, syntax/type errors, or broken fixtures do not establish RED. For a new interface, `devkit-coder` adds only the minimal public wiring needed to reach that check before implementing behavior. Test-only agents report a missing production seam to the coder and rerun their focused test after it exists; they do not add that wiring themselves.

Treat planned assertion-level RED as stage evidence within an already-authorized implementation task. The coder may continue with that authorized behavior; RED grants no permission to change unrelated production code. Apply project failure handling to unexpected failures, and honor any project rule that explicitly requires stopping or handing off even on expected RED. Test-only agents return RED to the coder without implementing the behavior.

If a meaningful automated test is impractical, or project rules prevent authoring or execution, record the specific limitation and the available before/after reproduction evidence. Do not claim an unexecuted test demonstrated RED or GREEN. Do not weaken assertions to fit the implementation.

Run the smallest eligible focused command during each cycle and honor project runtime limits. Complete the applicable lint, type, build, focused-test, and security checks before handoff; they are not prerequisites for the initial RED run.

## Where the policy lives

Each project declares its own test rules in its root agent-memory files:

- `CLAUDE.md` — for Claude Code
- `AGENTS.md` — for OpenAI Codex / Cursor (when applicable)

If neither file exists, or neither contains a `## Tests` (or equivalent) section, the **default fallback** is: *run test suites and create test files only when the user explicitly asks*.

A copy-pasteable template that projects can adopt lives at [`howto/project-test-rules.md`](../../../howto/project-test-rules.md).

## What the project file is expected to answer

Before running any test command or generating any test artifact, the agent must read the project's `CLAUDE.md` / `AGENTS.md` and resolve:

1. **When to run tests** — always, only on explicit request, never automatically, etc.
2. **What command to run** — the exact invocation (e.g. `php artisan test`, `pnpm test`, `make test`).
3. **What to do on failure** — fix, report, hand off to the user.
4. **Whether new test files may be created** — and under what conditions.

If the project file is silent on any of these, apply the conservative default: ask the user before running tests or creating test files.

## What is NEVER deferred (always expected without being asked)

Even when test execution is gated by project policy, agents must still verify their own work through other means on every change:

- **Lint** — check for linter violations introduced by the change.
- **Type check** — run static analysis when the stack supports it.
- **Manual review** — read back the written code, trace logic paths, check edge cases.
- **Smoke-check** — verify routes parse, migrations are valid, configs load, etc.
- **Security spot-check** — scan changes for obvious vulnerabilities (exposed secrets, raw SQL, missing auth).

The point of this rule is to prevent agents from producing unwanted test artifacts and consuming time on test suites the user did not ask for — not to excuse agents from verifying their code works.

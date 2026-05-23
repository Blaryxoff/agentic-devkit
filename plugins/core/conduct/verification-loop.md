# Verification Loop

Defines the standard verification cycle to run after implementation changes. Stack-specific commands come from active plugin conduct docs.

## The loop

After completing an implementation task (or a coherent subset), run these checks in order:

1. **Lint** — no new linter warnings or errors introduced by the change.
2. **Type check** — static type analysis passes (when applicable to the stack).
3. **Test** — existing tests pass; new tests pass if written.
4. **Security** — no obvious security regressions (exposed secrets, raw SQL, missing auth).

Do not run a separate build command. Assume the dev server is already running and will surface compile/bundle errors automatically. If the dev server reports errors, fix them.

## Reproduce before fixing

For any reported bug or regression, write a failing test that reproduces the defect *before* changing production code.

- The test must fail on the current code for the reason in the bug report. A green test on the first run means it does not cover the bug — rewrite it.
- The fix is complete only when that test passes and the rest of the suite stays green.
- If the bug surface cannot be tested (UI glitch, infra, third-party flake), state explicitly why no test was added, then describe the manual reproduction steps you ran before and after the fix.
- Do not skip this step because the fix "looks obvious". The test is what proves the diagnosis was correct, not just the patch.

## When to run

- After completing each task in a dev plan.
- Before marking a task as done.
- Before committing — the commit should represent verified, working code.
- After resolving merge conflicts.

## When NOT to run the full loop

- During exploratory/research phases where code is not yet meant to work.
- When the user explicitly asks to skip verification.
- For documentation-only or config-only changes where build/test are irrelevant.

## Failure handling

- If any step fails, fix the issue before proceeding to the next task.
- Do not accumulate failures across tasks — each task should leave the codebase in a passing state.
- If a failure is pre-existing and unrelated to the current change, note it explicitly and continue. Do not silently ignore it.

## Stack-specific commands

This document defines the loop structure. Concrete commands (`pnpm run lint`, `php artisan test`, `cargo check`, etc.) are defined in each stack plugin's conduct docs or in the dev plan's `## Validation Commands` section. The implementer must use the correct commands for the active stack.

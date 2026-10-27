# Verification Loop

Defines the standard verification cycle to run after implementation changes. Stack-specific commands come from active plugin conduct docs.

## The loop

After completing an implementation task (or a coherent subset), run these checks in order:

1. **Lint** — no new linter warnings or errors introduced by the change.
2. **Type check** — static type analysis passes (when applicable to the stack).
3. **Build** — production compilation and workspace exports pass when the project defines a build command or active stack conduct requires one.
4. **Test** — run the focused tests required by project policy and the changed behavior; new tests pass if written.
5. **Security** — no obvious security regressions (exposed secrets, raw SQL, missing auth).

A running dev server can surface compile and bundle errors during implementation, but it does not replace a required production build.

This order is the completion gate. During development, run project-permitted focused RED/GREEN checks under [agent-test-restraint.md](./agent-test-restraint.md) before production implementation or full lint/type/build checks when the test-first sequence calls for them.

## Reproduce before fixing

For a reproducible defect, write or update a project-permitted focused regression test before changing production behavior. Observe it fail for the reported defect, then make the smallest fix and observe it pass. Record the expected and observed behavior.

- Apply [agent-test-restraint.md](./agent-test-restraint.md) for meaningful RED, project permissions, and documented exceptions. If automated reproduction is impractical or not permitted, record the limitation and use an authorized runtime probe or manual steps before and after the fix.
- If a regression test was added after the fix under an exception, demonstrate its failure on a safely isolated pre-fix version when practical. Preserve current work; do not revert the working tree to demonstrate failure.
- Report any missing RED/GREEN observation explicitly. Do not claim that a test proved the regression without observing its failure on the original defect.
- Complete the fix only when the original reproduction no longer exhibits the defect and the eligible focused checks pass. A test that passes on both versions does not establish regression coverage.

## Selective mutation testing

Use [test-implementation.md](./test-implementation.md#selective-mutation-testing) when the task or project policy calls for checking assertion strength in changed high-risk logic. Keep this optional unless the project requires it.

## Reassess repeated failures

- After two fixes based on the same assumption fail the same check, pause production edits and state that assumption explicitly.
- Compare the failures with contrary evidence from the actual inputs, state ownership, call path, and environment. Distinguish a product defect from a failing fixture, tool, or setup before choosing another explanation.
- Use `devkit-wrong` to re-evaluate the approach or `devkit-root-cause` when the cause remains unknown. Resume implementation only with an evidence-backed explanation and a check that can distinguish it from the failed assumption.

The repeated-failure trigger is informed by [ub-mode](https://github.com/unclebob/ub-mode/blob/57a8bdd28e45ed41900ace0bafa2ff76dd9ed70f/SKILL.md#attack-the-premise); no license is declared at that revision. The guidance here is independently worded.

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
- Resolve failures before moving to the next task so each task leaves the codebase in a passing state.
- Record pre-existing failures unrelated to the current change explicitly before continuing.

## Stack-specific commands

This document defines the loop structure. Concrete commands (`pnpm run lint`, `php artisan test`, `cargo check`, etc.) are defined in each stack plugin's conduct docs or in the dev plan's `## Validation Commands` section. The implementer must use the correct commands for the active stack.

Every one of those commands runs through a shell. [shell-invocation.md](./shell-invocation.md) governs how to invoke one so it cannot block the session.

# Surgical Changes

Every diff must trace line-for-line to the user's request. Adjacent code is off-limits unless touching it is required to make the requested change work.

## The test

For each changed line, you must be able to answer: *which user request, plan task, or bug report does this line implement?* If the answer is "while I was here" or "cleanup", revert it.

## Allowed edits

- Lines that implement the requested change.
- Imports, types, or callers that *your* change made stale (orphans you created).
- Tests covering the new behaviour.

## Forbidden edits in the same diff

- Drive-by refactors of unrelated code in the same file or function.
- Style changes the linter did not flag — quote style, brace style, trailing commas, import ordering, indentation, whitespace.
- Adding type hints, docstrings, or comments to code you did not have to modify.
- "Improving" error messages, log lines, or variable names outside the changed region.
- Renames whose scope exceeds the requested change.
- Deleting pre-existing dead code, commented-out blocks, or unused helpers. Surface them to the user; do not delete.
- Reformatting a function because you changed one line inside it.

## Match the existing style

Match the conventions of the file you are editing, even when they conflict with your personal preference or with a different file in the same repo.

- Same quote style, same brace placement, same import ordering as surrounding code.
- Same naming convention (snake_case vs camelCase) as the enclosing module.
- Same error-handling pattern (exceptions vs result types vs sentinel values) as the surrounding layer.
- Same level of abstraction as siblings — do not introduce a class into a file of free functions, or vice versa.

If you believe the existing style is wrong, say so in chat. Do not change it as part of an unrelated diff.

## Orphans you created

When your edit removes the last call to a function, the last import of a symbol, or the last reference to a constant, delete the orphan in the same diff. This is cleanup *of your own change*, not drive-by refactoring.

Do not extend this to orphans that existed before your change. Those are out of scope — flag them to the user instead.

## How to surface findings without acting on them

When you notice unrelated issues during a task — dead code, bad names, missing tests, subtle bugs — list them in the chat summary. Do not edit them. Let the user decide whether to open a follow-up task.

## Why this matters

Bundled "improvements" hide the intentional change inside noise, defeat code review, and break `git blame`. A surgical diff is reviewable in seconds; a 200-line cleanup PR labelled "fix bug" is not.

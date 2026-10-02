# Surgical Changes

Keep every diff line tied to the user's request. Touch adjacent code only when the requested change depends on it.

## The test

For each changed line, you must be able to answer: *which user request, plan task, or bug report does this line implement?* If the answer is "while I was here" or "cleanup", revert it.

## Allowed edits

- Lines that implement the requested change.
- Imports, types, or callers that *your* change made stale (orphans you created).
- Tests covering the new behaviour.

## Keep the diff focused

- Limit edits to requested behavior and the smallest dependent changes. Leave unrelated code and its style as-is.
- Preserve existing quote style, brace style, trailing commas, import ordering, indentation, and whitespace unless the linter flags them.
- Add type hints, docstrings, and comments only to code the requested change requires you to modify.
- Keep error messages, log lines, and variable names outside the changed region intact.
- Keep renames within the scope of the requested change.
- Surface pre-existing dead code, commented-out blocks, and unused helpers to the user for a separate decision.
- Reformat only the code required by the change.

## Match the existing style

Match the conventions of the file you are editing, even when they conflict with your personal preference or with a different file in the same repo.

- Same quote style, same brace placement, same import ordering as surrounding code.
- Same naming convention (snake_case vs camelCase) as the enclosing module.
- Same error-handling pattern (exceptions vs result types vs sentinel values) as the surrounding layer.
- Match the abstraction level of sibling code: keep free-function files functional and class-based files class-based.

If you believe the existing style is wrong, explain that in chat and keep it out of an unrelated diff.

## Orphans you created

When your edit removes the last call to a function, the last import of a symbol, or the last reference to a constant, delete the orphan in the same diff. This is cleanup *of your own change*, not drive-by refactoring.

Limit orphan cleanup to items created by your change. Flag pre-existing orphans to the user as out of scope.

## How to surface findings without acting on them

When you notice unrelated issues during a task — dead code, bad names, missing tests, subtle bugs — list them in the chat summary and let the user decide whether to open a follow-up task.

## Why this matters

Bundled "improvements" hide the intentional change inside noise, defeat code review, and break `git blame`. A surgical diff is reviewable in seconds; a 200-line cleanup PR labelled "fix bug" is not.

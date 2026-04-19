---
name: devkit-verify
description: run the verification loop (lint, typecheck, test, security) after implementation changes and report results
---

# Verification Loop Runner

You are acting as a **quality engineer**. Your job is to run the project's verification loop after implementation changes
and report the results clearly.

## Resolving commands

Use this priority order to find the commands to run for each step:

1. **Active dev plan** — check the current plan's `## Validation Commands` section. These take priority.
2. **Conduct docs** — read `.devkit/toolkit.json`, identify enabled plugins, and read each plugin's `conduct/` directory
   for verification commands (lint, typecheck, test).
3. **Project files** — if neither source provides commands, infer from `package.json` scripts, `Makefile` targets,
   `composer.json`, or other project manifests.

## Build assumption

Do not run a separate build command. Assume the dev server is already running and will surface compile/bundle errors
automatically. If the dev server reports errors, fix them.

## The loop

Run these steps in order. Stop and report on first failure unless the user asks for a full report.

### 1. Lint

Run the linter as resolved above. If no linter is configured for this project, mark as `⏭️ skipped — not configured`.

### 2. Type check

Run static type analysis as resolved above. If the stack has no type checker configured, mark as
`⏭️ skipped — not configured`.

### 3. Test

Run the existing test suite **only if the user explicitly asked for verification that includes testing**.

If the user did not ask for tests, skip this step and mark it as `⏭️ skipped — not requested`.
Do not create new test files or write test code as part of verification.

### 4. Security spot-check

Review the changes (not the full codebase) for obvious security issues:

- Secrets or credentials in code or config files
- Raw SQL string interpolation
- Missing authorization on new endpoints
- User input passed to dangerous functions without sanitization

This is a quick review, not a full audit. Report findings inline with the other results.

## Output format

```
## Verification Results

| Step       | Status | Notes                          |
|------------|--------|--------------------------------|
| Lint       | ✅/❌  | <one-line summary or "passed"> |
| Type check | ✅/⏭️  | <one-line summary or "skipped — not configured"> |
| Test       | ✅/⏭️  | <one-line summary or "skipped — not requested"> |
| Security   | ✅/⚠️  | <one-line summary or "no issues found"> |
```

If any step failed, include the relevant error output below the table.

## Rules

- Do not fix issues yourself unless the user explicitly asks. Report findings only.
- Do not run destructive commands (database wipes, force pushes, etc.).
- If a failure is clearly pre-existing (exists on the base branch, unrelated to recent changes), mark it as
  `⚠️ pre-existing` rather than `❌`.
- Respect the agent test restraint rule: do not create test files or run test suites unless the user explicitly asked.
  All other verification steps (lint, typecheck, security review) are expected and should always run.
- Group security spot-check issues by severity per `plugins/core/conduct/review-findings-format.md`.

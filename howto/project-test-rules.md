# Project test rules — template for `CLAUDE.md` / `AGENTS.md`

This toolkit deliberately does **not** dictate when an agent may run tests or what command to use. Every project owns that decision and writes it into its own root memory files:

- `CLAUDE.md` for Claude Code
- `AGENTS.md` for Codex / Cursor

Paste the block below into your project's `CLAUDE.md` (and mirror it into `AGENTS.md` if you use both) and edit the three placeholders. The toolkit's `agent-test-restraint` conduct and `devkit-verify` skill look up exactly this section before they consider touching the test suite.

If no such section exists in either file, the toolkit applies the conservative fallback: ask the user for test permission before creating test files or running suites.

When the project permits authoring and execution, the toolkit defaults to test-first for reproducible bugs and clear behavioral contracts. Refactoring starts from passing behavior tests; UI exploration, prototypes, infrastructure, and impractical automated checks allow documented exceptions. Project-specific timing takes precedence. Permission and runtime limits still apply.

---

## The template (copy from the next line down)

```markdown
## Tests

**Policy:** {{always | on-request | never}}

- `always` — agents run focused tests during development and the project-required completion checks after any non-trivial change.
- `on-request` — agents run tests only when the user explicitly asks. The default verification loop skips them.
- `never` — leave test execution to the human. Useful when tests are slow, flaky, or require external services.

**Command:** `{{exact invocation}}`

For example: `php artisan test`, `pnpm test`, `make test`, `vendor/bin/phpunit --testsuite=Unit`.

If multiple commands are needed (e.g. PHP + frontend), list them in run-order and label them.

**On failure:** {{fix | report-only | handoff}}

- `fix` — agent attempts a fix, re-runs, and iterates up to a sane bound before reporting.
- `report-only` — agent reports the failure with full output and stops. Production code is never modified to make a test pass without explicit instruction.
- `handoff` — agent reports and asks the user how to proceed.

These actions govern unexpected failures. Planned assertion-level RED in an already-authorized test-first implementation task is stage evidence: the coder may implement the requested behavior, while test-only agents hand RED back to the coder. It does not authorize unrelated fixes. An explicit project rule to stop or hand off even on expected RED takes precedence.

**Creating new test files:** {{allowed | on-request | forbidden}}

- `allowed` — agents may add tests proactively for new behaviour they introduce.
- `on-request` — agents only add tests when the user asks.
- `forbidden` — only humans add tests.

`allowed` permits test authoring; the execution policy above governs running them. Use test-first for reproducible bugs and clear behavioral contracts when both are permitted. Record an exception when a meaningful automated test is impractical, and report unexecuted tests explicitly.
```

---

## Examples

### Fast, reliable suite — run automatically

```markdown
## Tests

**Policy:** always
**Command:** `make test`
**On failure:** fix
**Creating new test files:** allowed
```

### Slow integration suite — opt-in only

```markdown
## Tests

**Policy:** on-request
**Command:** `php artisan test --parallel`
**On failure:** report-only
**Creating new test files:** on-request
```

### Production hotfix project — humans run tests

```markdown
## Tests

**Policy:** never
**Command:** `pnpm test` (human invocation only)
**On failure:** handoff
**Creating new test files:** forbidden
```

---

## Where this is consumed by the toolkit

- [`plugins/core/conduct/agent-test-restraint.md`](../plugins/core/conduct/agent-test-restraint.md) — defines the fallback default and points agents at this file.
- [`plugins/core/skills/verify/SKILL.md`](../plugins/core/skills/verify/SKILL.md) — step 3 of the verification loop reads project policy before running tests.
- [`plugins/laravel/skills/tester/SKILL.md`](../plugins/laravel/skills/tester/SKILL.md) and [`plugins/nuxt/skills/tester/SKILL.md`](../plugins/nuxt/skills/tester/SKILL.md) — apply project permissions and shared test-first timing while preserving their test-only scope.
- [`plugins/laravel/conduct/git.md`](../plugins/laravel/conduct/git.md) and [`plugins/nuxt/conduct/git.md`](../plugins/nuxt/conduct/git.md) — pre-commit checks defer the test command to project rules.

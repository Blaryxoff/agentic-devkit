# Project test rules — template for `CLAUDE.md` / `AGENTS.md`

This toolkit deliberately does **not** dictate when an agent may run tests or what command to use. Every project owns that decision and writes it into its own root memory files:

- `CLAUDE.md` for Claude Code
- `AGENTS.md` for Codex / Cursor

Paste the block below into your project's `CLAUDE.md` (and mirror it into `AGENTS.md` if you use both) and edit the three placeholders. The toolkit's `agent-test-restraint` conduct and `devkit-verify` skill look up exactly this section before they consider touching the test suite.

If no such section exists in either file, the toolkit applies the conservative fallback: do not create test files, do not run test suites, ask the user.

Regardless of the project setting, test authoring is a finalization phase: agents finish production work and make applicable non-test checks green before creating or updating tests. They do not rewrite tests after every production-code iteration.

---

## The template (copy from the next line down)

```markdown
## Tests

**Policy:** {{always | on-request | never}}

- `always` — agents run the test suite automatically as part of verification after any non-trivial change.
- `on-request` — agents run tests only when the user explicitly asks. The default verification loop skips them.
- `never` — agents never run tests automatically; the human runs them. Useful when tests are slow, flaky, or require external services.

**Command:** `{{exact invocation}}`

For example: `php artisan test`, `pnpm test`, `make test`, `vendor/bin/phpunit --testsuite=Unit`.

If multiple commands are needed (e.g. PHP + frontend), list them in run-order and label them.

**On failure:** {{fix | report-only | handoff}}

- `fix` — agent attempts a fix, re-runs, and iterates up to a sane bound before reporting.
- `report-only` — agent reports the failure with full output and stops. Production code is never modified to make a test pass without explicit instruction.
- `handoff` — agent reports and asks the user how to proceed.

**Creating new test files:** {{allowed | on-request | forbidden}}

- `allowed` — agents may add tests proactively for new behaviour they introduce.
- `on-request` — agents only add tests when the user asks.
- `forbidden` — only humans add tests.

`allowed` controls permission, not timing. Allowed tests are still written only after the implementation is otherwise complete and green, at commit-ready handoff.
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
**Command:** `pnpm test` (for humans — agents do not invoke)
**On failure:** handoff
**Creating new test files:** forbidden
```

---

## Where this is consumed by the toolkit

- [`plugins/core/conduct/agent-test-restraint.md`](../plugins/core/conduct/agent-test-restraint.md) — defines the fallback default and points agents at this file.
- [`plugins/core/skills/verify/SKILL.md`](../plugins/core/skills/verify/SKILL.md) — step 3 of the verification loop reads project policy before running tests.
- [`plugins/laravel/skills/tester/SKILL.md`](../plugins/laravel/skills/tester/SKILL.md) and [`plugins/nuxt/skills/tester/SKILL.md`](../plugins/nuxt/skills/tester/SKILL.md) — enforce the finalization gate before authoring tests.
- [`plugins/laravel/conduct/git.md`](../plugins/laravel/conduct/git.md) and [`plugins/nuxt/conduct/git.md`](../plugins/nuxt/conduct/git.md) — pre-commit checks defer the test command to project rules.

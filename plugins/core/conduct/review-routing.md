# Review & Test Routing

Picks the right skill(s) when the user asks to **review**, **test**, **QA**, or **check** a change. The verb alone is ambiguous — route by intent **and by what the change actually touches**. Inspect the diff first.

## Inspect before choosing

Run `git diff --name-only <base>` (or scope to the named files/branch) and classify the changed paths:

- **plan/spec docs** — `docs/plans/**`, `*plan*.md`, spec/PRD markdown, ralphex plan files.
- **code** — anything the app runs (PHP, JS/TS, Vue, configs, migrations, tests).

## Decision table

| Request intent | What changed | Run |
|---|---|---|
| "review", "поревьюй", "посмотри изменения" | only plan/spec docs | `devkit-plan-reviewer` |
| "review the branch/code", "поревьюй ветку/изменения целиком" | code | `devkit-reviewer-deep` **and** `devkit-reviewer-business-logic` (both) |
| "quick/fast review", "быстро глянь" | code | `devkit-reviewer-fast` |
| "test", "протестируй", "QA", "smoke-test", "прокликай" | running app / UI | `devkit-browser` (or `devkit-browser-ralphex` when a persisted plan + markdown report is wanted) |

## Rules

- **Inspect the diff before deciding** — never route from the verb alone.
- **Full branch / code review = two skills.** `devkit-reviewer-deep` (architecture, security, data correctness, performance) and `devkit-reviewer-business-logic` (behavioural completeness, business-rule correctness) cover different axes — run both for "review the whole branch / the changes".
- **Mixed diff (plans AND code):** run the code reviewers **and** `devkit-plan-reviewer`.
- **Fast vs deep:** only use `devkit-reviewer-fast` when the user signals speed ("quick", "fast", "just regressions"). Default code review is deep + business-logic.
- **Test ≠ review:** "test/QA/протестируй" never means a static reviewer — it means `devkit-browser` (drives the running app).

# Review & Test Routing

Picks the right skill(s) when the user asks to **review**, **test**, **QA**, or **check** a change. The verb alone is ambiguous — route by intent **and by what the change actually touches**. Inspect the diff first.

## Inspect before choosing

Run `git diff --name-only <base>` (or scope to the named files/branch) and classify the changed paths:

- **plan docs** — any file under `docs/plans/**`. Classify by path, never by inferred format.
- **other spec/PRD markdown** — `*plan*.md` elsewhere, PRDs, spec markdown. No dedicated reviewer.
- **code** — anything the app runs (PHP, JS/TS, Vue, configs, migrations, tests).

## Decision table

| Request intent | What changed | Run |
|---|---|---|
| "review", "поревьюй", "посмотри изменения" | only files under `docs/plans/**` | `devkit-plan-reviewer` |
| "review" + the word `ralphex` written explicitly | any plan/spec doc | `devkit-plan-reviewer` |
| "review", "поревьюй" | other spec/PRD markdown, `ralphex` not written | no skill — review directly |
| "review the branch/code", "поревьюй ветку/изменения целиком" | code | `devkit-reviewer-deep` **and** `devkit-reviewer-business-logic` (both) |
| "quick/fast review", "быстро глянь" | code | `devkit-reviewer-fast` |
| "test", "протестируй", "QA", "smoke-test", "прокликай" | running app / UI | `devkit-browser` (or `devkit-browser-ralphex` when a persisted plan + markdown report is wanted) |

## Rules

- **Inspect the diff before deciding** — never route from the verb alone.
- **Plan skills are keyword-gated.** `devkit-plan-creator` and `devkit-plan-reviewer` load only when the prompt literally
  writes `ralphex`. The reviewer may also load when the review target is a file under `docs/plans/**`. Claude Code's
  built-in `/plan` mode is not ralphex; never route it to `devkit-plan-creator`.
- **Full branch / code review = two skills.** `devkit-reviewer-deep` (architecture, security, data correctness, performance) and `devkit-reviewer-business-logic` (behavioural completeness, business-rule correctness) cover different axes — run both for "review the whole branch / the changes".
- **Mixed diff (`docs/plans/**` AND code):** run the code reviewers **and** `devkit-plan-reviewer`.
- **Fast vs deep:** only use `devkit-reviewer-fast` when the user signals speed ("quick", "fast", "just regressions"). Default code review is deep + business-logic.
- **Test ≠ review:** "test/QA/протестируй" never means a static reviewer — it means `devkit-browser` (drives the running app).
- **Reviewers never repair:** a plain review returns findings and stops after one complete pass. Only an explicit fix/repair request authorizes a separate repair workflow to invoke the coder skill.
- **Repair/recheck loops are finite:** apply `review-findings-format.md`'s completion gate. Blocking/Critical findings fail; Significant findings require impact-based adjudication; Minor findings pass. Explicit repair loops stop after at most 5 complete review passes.

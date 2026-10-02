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
| "review the logging", "проверь логи", "log audit" | code | `devkit-reviewer-logging` |
| "test", "протестируй", "QA", "smoke-test", "прокликай" | running app / UI | `devkit-browser` |
| `revmux` named as the review **engine** — "revmux this branch", "run revmux", "review it with revmux" | any target | upstream `revmux` skill — [revmux-review.md](./revmux-review.md) |

## Rules

- **Inspect the diff before deciding** — classify changed paths and route by request intent and scope.
- **Plan skills are keyword-gated.** `devkit-plan-creator` and `devkit-plan-reviewer` load only when the prompt literally
  writes `ralphex`. The reviewer may also load when the review target is a file under `docs/plans/**`. Route Claude Code's
  built-in `/plan` mode to its native planning workflow; reserve `devkit-plan-creator` for literal `ralphex` requests.
- **Full branch / code review = two skills.** `devkit-reviewer-deep` (architecture, security, data correctness, performance) and `devkit-reviewer-business-logic` (behavioural completeness, business-rule correctness) cover different axes — run both for "review the whole branch / the changes".
- **Flatten full-review fan-out.** From the top-level session, resolve the applicable deep and business-logic variants,
  generic fallbacks, and risk-gated specialists from `review-specialist-fanout.md` exactly once. Launch one parallel batch
  when capacity permits, or the minimum capacity-bounded waves otherwise. Keep dispatch at the top-level session and use
  one shared change set unless the user explicitly requests independent scopes.
- **revmux is keyword-gated.** Run it only when the user names revmux as the engine to review with; it then replaces the
  devkit reviewer fan-out for that pass rather than adding to it, unless the user asked for both. Route based on the
  named engine, not diff size, risk, or a pre-merge gate. Mechanics: `revmux-review.md`.
- **revmux as a subject is not a trigger.** "review the revmux integration", "поревьюй ревмакс-конфиг" and any other
  request whose *target* happens to be revmux route by the rows above like any other code or plan review. Naming a
  review engine and naming a review target are different asks; when the sentence reads both ways, ask.
- **Mixed diff (`docs/plans/**` AND code):** run the code reviewers **and** `devkit-plan-reviewer`.
- **Fast vs deep:** only use `devkit-reviewer-fast` when the user signals speed ("quick", "fast", "just regressions"). Default code review is deep + business-logic.
- **Test ≠ review:** route "test/QA/протестируй" to `devkit-browser` (drives the running app), not to a static reviewer.
- **Reviewers report; repair workflows edit:** return findings after one complete pass for a plain review. Start a separate
  repair workflow with the coder skill only after an explicit fix/repair request.
- **Repair/recheck loops are finite:** apply `review-findings-format.md`'s completion gate. Blocking/Critical findings fail; Significant findings require impact-based adjudication; Minor findings pass. Explicit repair loops stop after at most 5 complete review passes.

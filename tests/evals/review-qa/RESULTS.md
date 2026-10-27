# Implementation verification — 2026-10-26 to 2026-10-27

The shared review/QA rules and evaluation helpers are implemented. The full repository suite passed on 27 October
after the user's approval for the longer run. The separate paired behavior benchmark has not run; stage 7
effectiveness remains unproven.

## Observed checks

| Check | Observed result | Boundary |
|---|---|---|
| `bash tests/run-all.sh` | Passed before wrapup publication on 27 October | Complete repository suite; not the paired model benchmark |
| Context efficiency and existing wording canaries | Passed | Metadata/routing/document obligations; not agent effectiveness |
| Claude, Codex and Cursor adapter checks | Passed | Generated adapter structure and references; not behavior across all models |
| Stack plugin checks | Passed | Resolution and generated stack capabilities |
| `bash tests/review-qa.sh` | Passed: 54 Python tests (40 runner, 14 runtime fixture) and 3 Node cleanup tests, zero skips | Helper/fixture mechanics only |
| `node tests/evals/review-qa/touch_probe.mjs` | Passed after graceful-cleanup fix on Chromium 156 at 390×844, scale 1 | Actual trusted touch at center/edge; blocked by overlay in the faulty fixture, successful UI/server action in the clean fixture; no Safari/native claim |
| PDF and media fixture checks | Rendered PDF and decoded valid/invalid ten-second audio/video cases passed | Synthetic artifacts using installed tools, not product output acceptance |
| Static behavioral/documentation review | No retained findings in production Markdown | Does not establish runtime detection |
| Evaluation-helper review | Export/run binding and mandatory per-axis applicability rechecks passed; C033's source-path obligation preserved. Direct NestJS routing, graceful cleanup and prerequisite docs corrected. No retained findings in the focused rechecks | Source review and focused regressions |

The context check retains pre-existing warnings: six skills exceed the progressive-disclosure target; catalog metadata
is 16,963 characters, below the enforced 17,000-character limit but above its 16,000 target.

## Limited model smoke

An isolated connection probe returned `READY`. A single recorded-input control pair, C039 variant a / static review,
ran on the live-catalog-resolved Luna model with effort `high`; its exact identifier remains in the local smoke `run.json` files. Both baseline and candidate identified the supplied label mismatch without tools.
The initial candidate source package used 5,032 instruction bytes versus 8,303 in the baseline; elapsed times were
10.99 and 13.51 seconds respectively. These are one-pair observations, not general cost or detection measurements.

This smoke preceded the final helper review fixes and has no benchmark grade. It does not close a mandatory benchmark
unit, establish runtime detection, or satisfy the new experiment-identity and independent scope/cost audit gates.

## Reproducibility and remaining work

- Frozen design-3: 40 original cases, 83 declared case/axis combinations, 166 mandatory variant/axis units, including 22 runtime units. The original inputs/answers are unchanged; per-axis applicability was versioned after review and before any full benchmark.
- `cases.json` SHA-256: `708881dea8600942bf835102e8ad1649380460a787cd76ce2419d1cd65812b21`.
- `rubric.json` SHA-256: `6d9572eda5693fec54ea5c6d0ffe23393fea0d99b41c717fc92c3492296654ac`.
- `applicability.json` SHA-256: `6f3bb0da44383b75e4e7939bb5acb4506ace0d2d8397b107133ef81abdf29782`.
- Local raw artifacts are under `.cache/review-qa/`: baseline source archive/manifest, initial snapshots, provider probe,
  C039 smoke transcripts and `touch-evidence.json`. They are ignored by git and are not required inputs to the portable corpus.
- Follow [README.md](./README.md) to prepare fresh final snapshots, resolve/pin the model, execute paired runs, grade
  independently, confirm changed outcomes and supply the exact-run scope/cost audit. Retain runtime gaps in the denominator.
- Earlier unbound runs and snapshots with the old corpus cannot be graded under design-3. Do not retrofit identity seals or applicability grades onto the historical smoke.
- Full-suite output is retained locally in `.cache/review-qa/wrapup-full-suite.log`. This record covers pre-publication
  verification; the wrapup report records commit/push identity and deployment receipts separately.

## Live workflow pilot — 27 October 2026

A local product-gift-certificate pilot exercised the existing worktree at
`19bf0f7c9a48cd8de68c6f317cc1ccc083fc2f35`. PHP and Vite process working directories, the served module, and unchanged
source revision were checked independently. Delegated CLI execution used runtime-catalog-resolved Luna with inherited
`high` effort; its exact identifier is retained in `.cache/review-qa/pilot-20261027-checks.json`. Scouts and reviewers
used Luna with inherited effort. This was a real-feature workflow trial, not a
paired baseline/candidate benchmark or release acceptance for every brand and native client.

| Observed workflow problem | Generic correction and evidence |
|---|---|
| Existing/enabled fixtures were not necessarily selectable; an unsaved toggle produced an invalid sale-blocker test. | Verify role-specific runtime eligibility and persisted preconditions. The corrected no-design sale test rejected the operation. Bound downstream effects even when a negative test unexpectedly succeeds. |
| The first lane allocation omitted delivery rotation, prior access, expiry recovery and tariff-decision checks. | Map in-scope criteria back to cases/gaps and sequence checks before their fixtures are consumed. Added lanes verified these lifecycle paths, with timer execution still blocked. |
| An empty DOM input was mistaken for an empty submitted value. | A neutral event fixture showed MCP `fill("")` clearing the DOM without input/change events; its bound value remained unchanged. Checkbox fill/click controls delivered events. The application validation finding remains unproven; keyboard selection was not established in that recheck. Require input-method and payload evidence. |
| A worker repeatedly traversed focus without finishing its target check. | Interrupt the stalled lane, preserve its checkpoint, and bound recovery by focus progress. The interrupted log contains 712 key calls; the scoped continuation used 10. These different scopes are not a performance benchmark. |
| Emulation reset a wizard and invalidated state labels on its measurements. | Re-pin rendered state after emulation and restore it before measuring; preserve invalid attempts separately. |
| A missing `main` selector stopped a whole-page oracle. | Resolve a correct explicit root without broadening scope. The observed `#app` root completed the follow-up at three viewports. |
| A menu's low-contrast hit-area edge was promoted to a major icon defect. | Measure the meaningful glyph. The real glyph measured 17.30:1; independent dark/pale glyph controls measured 13.92:1 and 1.14:1. The updated interpretation rejected the former false positive while detecting the low-contrast control. See [W3C boundaries guidance](https://www.w3.org/WAI/WCAG22/Understanding/non-text-contrast#boundaries). |
| Automatic browser replacement left an empty global profile delta. | A controlled continuation verified recovery through the same dedicated MCP ancestry and a new isolated profile, then re-pinned the page. |
| One executor used a pre-existing shared MCP instead of its dedicated tree. | Preserve the shared process, close only its pass-created tabs, and require invocation-unique tool bindings plus a lead-verified ready/release gate. Two subsequent workers waited before navigation; the lead checked live ancestry and exact ready-file digests before release. |
| Shared defaults and prose descriptions generated incorrect feature findings. | Check the actual runtime variant and controlling requirement. The product's terminal-state override and the live mobile picker resolved two false positives. Preserve unexplained earlier toggle evidence instead of erasing it after a successful recheck. |
| A startup-only worker repeated unrelated project discovery and stopped on a missing CLI registry. | Carry the lead's verified project-discovery receipt into the startup brief; keep the executor's ownership stage scoped to its assigned binding. This final clarification received document review, not a fresh model trial. |

Verified application paths included a simulated purchase, wrong-code rejection and activation, self-paced access after
existing ordinary access, future-flow selection/change without early consumption, independent gifts on one product,
first-use consumption, no-date behavior, expiry extension, tariff warnings and registry membership, immediate email
rotation, stale-link/code rejection, and stored upload bytes. Provider receipt rows are not delivered fiscal receipts;
local mail-log output is not inbox delivery.

| Retained product observation | Reproduction boundary |
|---|---|
| Create/Save disappears on narrow screens. | `OfferForm.vue` puts the only submit in the title's desktop-only actions slot. Rendered bounds were zero at 390/768 px; edit was also checked at 360 px. |
| Form/detail controls lack accessible names. | Two instruction textareas, the template-name input, and icon-only detail navigation were unnamed in the accessibility tree. Visual labels alone did not associate with the controls. |
| Required sender can be omitted. | The product wizard advanced from step 2 with an empty “От кого”; product-specific UX requires it. Server validation was not established. |
| Long greeting is clipped. | A permitted 469-character greeting had 48 px visible height versus 112 px content height on the recipient preview, without an expansion control; `GiftCertificatePreview.vue` clamps the text. |
| Archived tariff still offers holder continuation. | After the owned tariff was soft-deleted and the position entered the decision filter, its holder still saw an enabled confirmation instead of the required neutral message. No confirmation POST or forbidden grant was demonstrated. |
| Focus escapes the expiry modal. | From its focused reason input, Tab reached the background assistant after the modal buttons despite `aria-modal=true`. Compare the [APG modal keyboard pattern](https://www.w3.org/WAI/ARIA/apg/patterns/dialog-modal/); no mutation was submitted. |
| Unselected wallet tab lacks hover feedback. | `GiftWalletTabs.vue` retained identical paint properties on desktop hover; the tab remained usable. |

Low-contrast field cues and several ambiguous reports retain their stated evidence limits; the pilot did not turn every
oracle candidate into a confirmed product defect. In particular, the unexplained first toggle attempt and empty-email
application validation remain unproven, rather than disappearing from history after a later result.

Physical touch/Safari/native and other-brand coverage, safe future-timer execution with the synchronous queue, real
payment/fiscal/inbox delivery, later automatic flow progression, refunds, some alternate-write denials and remaining
pre-activation visual states remain incomplete. Five append-only QA tenants were retained; application source and
pre-existing servers were preserved. Spawned workers and owned browser trees exited; the shared MCP was left untouched.

The changed conduct/skill documents passed focused review and context checks; the unchanged probe's 61 defect/clean
checks passed. The frozen design-3 corpus and the unexecuted full paired benchmark above are unchanged. Raw scratch
reports are not part of this repository; this sanitized record preserves the observations and their limits.

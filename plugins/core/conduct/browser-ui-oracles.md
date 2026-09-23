# Browser UI Oracles

## 1. Scaling

1.1. Scope every run to the smallest root that contains the change — a section, card, form or table. With no root the
probe uses `main`, then `body`. An explicit root that is invalid or matches nothing returns `blocked`; report that
instead of re-running unscoped.

1.2. Run only the oracles the change can affect, chosen from §2. A one-section change runs one to three scripted keys
plus the applicable manual oracle, at two viewports, in one `evaluate_script` call per viewport. An exhaustive pass runs
every applicable §5 oracle, scripted and manual.

1.3. Measure at the narrowest and widest supported viewport (default 390 and 1440). Below ~500 CSS px `resize_page` may
leave the layout unchanged: use `emulate` with `"<w>x<h>x1,mobile,touch"` and assert
`document.documentElement.clientWidth` before trusting any measurement.

1.4. Measure in the data state the change targets. An empty list passes every density, repetition and alignment oracle
vacuously — report the cell as not reached, with the missing fixture, never as passed.

## 2. Which oracles to run

| What changed | Oracles |
|---|---|
| A control primitive or its states | §5.1 states, `boundaries`, `rhythm`, `primaries` |
| A form, filter bar, toolbar or inline edit row | `rhythm`, `boundaries`, `mute`, §5.1 states |
| A list, table, feed or timeline | `repeated`, `groups`, `transport` |
| A detail card or label/value block | `alignment`, `transport`, `surfaces` |
| A new page, layout or navigation | `navigation`, `surfaces`, `primaries` |
| Copy, labels, formatting or locale | `transport`, §5.9 language |
| Anything that renders at narrow width | `browser-layout-audit.md` containment probe |

## 3. Running the probe

3.1. The probe is `plugins/core/skills/browser/scripts/ui-oracles.js`, one arrow-function expression. Paste it into
`evaluate_script` byte-for-byte; never retype, trim or paraphrase it.

```js
() => { const probe = /* contents of ui-oracles.js */; return probe("#target", ["rhythm", "boundaries"], { scale: [36, 40, 48, 56] }); }
```

3.2. Arguments: `root` CSS selector or `null`; `only` array of scripted keys (`rhythm`, `boundaries`, `surfaces`,
`repeated`, `alignment`, `transport`, `mute`, `navigation`, `groups`, `primaries`) or `null` for all; `opts`:

| Option | Meaning |
|---|---|
| `scale` | Allowed control heights in px |
| `primaryFills` | CSS colours of the primary action fill, from tokens |
| `forbidden` | Literal spellings the product never prints (escaped by the probe) |
| `maxNodes`, `maxMs` | Traversal budget; defaults 6000 nodes, 4000 ms |
| `cap` | Items returned per list; default 12, overflow reported as `truncated` |

3.3. Read the result metadata before the findings: `truncatedNodes > 0`, `timedOut` or a list's `truncated` count
means coverage was partial;
`untested.shadowRoots` and `untested.iframes` count content the probe did not enter — check it by hand or report it
untested; `indeterminate: true` on a measurement means gradients, images, filters, blending, opacity or a painted
`::before`/`::after` — on the element or behind it — sit in the paint, so the ratio is not trustworthy and the value
needs a manual measurement. An indeterminate measurement is always returned as a candidate, never dropped as clean.

3.4. Probe output is candidates. Confirm each against the requirement, design reference, tokens and neighbouring screens
before filing it, and cite the source that confirmed it.

3.5. Every probe change adds a defect and its clean twin to `tests/fixtures/ui-oracles.html` and keeps
`tests/browser-oracles.sh` green. A probe that cannot fire on the defect it targets certifies nothing.

## 4. Measurement rules

4.1. Rasterise colours before computing contrast. `getComputedStyle` returns `oklch()`, `oklab()` or `color()` for
tokenised colours; a regex over digits fabricates the ratio. Draw the colour on a 1×1 canvas and read the pixel.

4.2. `box-shadow !== "none"` is not a shadow, and a shadow is not necessarily an edge. Count a layer as the control's
edge only when it has offset, blur or spread, touches the box (offset no larger than blur plus positive spread plus
1px), and its colour composited over the backdrop — at half alpha when blurred without positive spread — differs from
the backdrop by at least 1.1:1. `0 0 0 0 <colour>`, a 3%-alpha haze and a copy offset clear of the box are no edge. A
shadow under opacity, a filter or blending on the element or an ancestor proves nothing: measure it as indeterminate.

4.3. A negative spread shrinks an outset shadow on every side. It paints nothing when `width + 2·spread ≤ 0` or
`height + 2·spread ≤ 0`, so a card shadow such as `0 22px 48px -30px` on a 40px control is no edge at all.

4.4. Measure the painted box, not the native element. A native `<input>` is ~22px tall and flat inside a 36–56px styled
wrapper. A control inside that wrapper is an adornment of the field only when it has no visible text and no fill,
border, shadow or painted pseudo-element of its own — it reads as part of the field, whatever its hit area. Any other control is independent. Stop
climbing at any ancestor that owns a second independent control: neither a field nor a button on a bordered toolbar
borrows the toolbar's edge.

4.5. Composite fills from the outermost opaque ancestor inward, and borders over their own element's fill, before
comparing against what sits behind the control. Compare unrounded ratios against a threshold; display them floored.

4.6. Computed style of `::-webkit-*` pseudo-elements returns the host element's style. Detect native spinners and
pickers from the smallest element capture taken while hovering or focusing the control (`browser-qa-rules.md` §6.6).

4.7. Count rendered nodes, not presence. "Is there a primary action" passes a page with three; ask how many are visible
at rest, and include global chrome such as the site header in the count. Exclude hidden, zero-opacity, off-canvas and
clipped-away nodes, including a fully clipping `clip-path` and the visually-hidden `clip: rect(0 0 0 0)` pattern.

4.8. Compare against the design system's canonical value, not only within the block. A block that is internally
consistent at a non-canonical size passes a within-block check.

4.9. WCAG 1.4.11 exempts a disabled control from 3:1 but not from being perceptibly different from its enabled state.

4.10. Report blocked over inferred. When the state or data an oracle needs is unreachable, report the cell blocked with
the missing prerequisite.

## 5. Oracles

Assign severity only after §3.4 confirmation. A confirmed boundary failure on a field or icon-only control, a page with
no way out, and an unnamed control are at least `major`; set the rest by user impact.

5.1. **States** (manual). Every activatable element shows a perceptible resting, hover, focus-visible and active state,
plus disabled where it can be unavailable. Perceptible means a computed `background-color`, `border-color`, `box-shadow`,
`color`, `outline` or `text-decoration` differs from resting. Read the six properties at rest, after the `hover` tool,
and after `press_key Tab` reaches the element; take active from the primitive's source. Opacity alone is not a disabled
state. A removed focus ring with nothing in its place is not a focus state. A state that drops the control's shadow must
keep an edge of at least 3:1 (§5.3).

5.2. **`rhythm`** — controls on one visual line share one height. Candidates are rows with more than one height, a mixed
font size, or a height outside `opts.scale`. Checkboxes, radios and a field's own adornments are excluded. Name the
control that should change and to what size.

5.3. **`boundaries`** — a control whose edge is drawn by no real shadow needs a fill, border or outline of at least 3:1
against what is behind it. `kind: field` and `kind: icon` need a visible boundary to be identified; `kind: text` is a
finding only when the same primitive draws an edge in another state or on another screen, because its label already
identifies it. Report both colours and the ratio.

5.4. **`surfaces`** — `bare` lists boxes wider than 240px, drawn by a border or by a rounded fill, with no real shadow
and a fill — transparent or opaque — that does not separate them from what is directly behind them: visible only by an
outline, or muddy. A box nested inside a card is a section of that card and is not listed. `mixed` lists headed blocks when
some have a surface and some do not.

5.5. **`repeated`** — one text shape (digits normalised) covering at least 60% of five or more items reads as a log
dump. Report item count, distinct shapes and whether anything tones, groups or caps it.

5.6. **`alignment`** — `pairs` lists label/value blocks where some values wrapped under their label and others did not,
columnar blocks whose values start at different x, and mixed label or value font sizes. `stacks` lists vertical stacks
of single controls that do not share a left edge.

5.7. **`transport`** — the screen prints what the API sent: ISO dates, machine decimals (`100.000`, `0.00`), enum slugs,
and any `opts.forbidden` spelling. Judge each hit against the project locale; a confirmed hit is a call site that
skipped a formatter — name the field and the helper.

5.8. **`mute`** — `empty` lists fields with no value and no placeholder; they are findings when the page already prints
the answer elsewhere. `nativeCandidates` lists input types that can render browser chrome inside a styled component;
confirm by §4.6.

5.9. **Language** (manual). Report UI strings that transliterate a foreign term instead of translating it, and mixed
scripts in one sentence. Judge the word, not the letters: established loanwords are correct. Check the project glossary
before proposing a replacement.

5.10. **`navigation`** — every page has a way out other than Browser Back: a same-origin link to a strict path prefix or
the section root, rendered in the normal authorised state, visible above the fold or in sticky chrome, at every tested
viewport. The page also states where it is (heading plus parent). `waysUp: 0` or `aboveTheFold: 0` is a candidate.

5.11. **`groups`** — `unnamed` lists controls, form fields, checkboxes and links with no accessible name, resolved from
`aria-labelledby`, `aria-label`, associated labels, then content that is not `aria-hidden`; a form field never takes its
name from its own content, so a `<select>` is not named by its options. The probe approximates the platform algorithm —
confirm a candidate in the accessibility tree (`take_snapshot`);
`detached` lists icon groups that wrapped below their row's label; `constantColumns` lists table columns holding one
value on every row.

5.12. **`primaries`** — with `opts.primaryFills` the probe counts controls filled with the project's primary colour
across the whole document; without it, it groups saturated fills as a labelled heuristic. More than one primary visible
at rest is a candidate; so is one rendered per row or card. `state: "selected"` marks a highlighted toggle; an
accent-filled toggle without `aria-pressed` or `aria-selected` exposes no state to assistive technology.

## 6. Project profile

Take these values from the project's tokens, instruction file and code. State every assumed value in the report.

| Value | Source | Probe option |
|---|---|---|
| Primary action fill | Tokens | `primaryFills` |
| Control height scale | The primitive's size map | `scale` |
| Spellings the product never prints | Style guide, glossary | `forbidden` |
| Locale, date, number, unit and currency formats | i18n config or instruction file | — (judge §5.7) |
| Formatter helpers every display must use | Code search | — (name in §5.7) |
| Canonical label/value sizes | The design system's data-row primitive | — (compare in §5.6) |

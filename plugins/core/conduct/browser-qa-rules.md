# Browser QA

Canonical rules for the `devkit-browser` QA skill. Cite the relevant sections from the skill and keep these rules canonical here.

## 1. Scope

1.1. Input is always a scope: a feature name, a route/page set, or `whole project`.

1.2. Discover routes, roles, entities, and credentials from the codebase — never hardcode project-specific names or secrets.

1.3. Apply `plugins/core/conduct/inputs-grounding-gate.md` before mapping the QA surface.

1.4. Classify the pass before preflight; the first match wins, and the skill cites this list instead of restating it.

1. **Exhaustive** — the request says `full`, `e2e`, `exhaustive` or `final`, names the whole project, or asks for feature
   QA with no narrower boundary.
2. **Targeted** — the request names roles, a user flow or entity lifecycle, a regression set, permissions or security, a
   design reference, or says `smoke`, `only` or incremental.
3. **Spot** — the scope is exactly one page, route, section or component and none of the above applies.

1.5. A targeted pass verifies every explicitly selected matrix cell plus its directly adjacent regression path, reports every omitted dimension, and never claims final acceptance. Run the exhaustive pass once the implementation is stable; scope intermediate rechecks to affected cells under §1.7.

1.6. A spot pass drops only the coverage ledger and the planner, executor and reviewer dispatch; run it in the current
session. Every other rule still binds: §2 preflight, environment pin and surface choice, §3 when the pass mutates data,
§6 evidence, all §9 hard rules, and §10 cleanup of whatever the pass started. Choose oracles by
`browser-ui-oracles.md` §2, scope the probe to the changed root, measure at two viewports, exercise the changed
interaction once for real, and check console errors. Report findings with the §7 fields and end with the skill's
one-line spot result. A spot pass never claims acceptance and never replaces a targeted or exhaustive pass.

1.7. **Resume and rechecks** — preserve the original ledger, evidence references and proven checks. Track functional
outcomes and visual/runtime audit dimensions separately: a missing hover or layout check leaves that dimension
incomplete, without erasing an evidenced functional result. The pass remains incomplete until all required dimensions
are reconciled. Follow-up briefs name exact missing, conflicting or invalidated cell/dimension IDs and only the setup
dependencies needed to reach them; collect the missing audit while preserving completed functional results. A changed
implementation, fixture state, origin or role invalidates only the checks it can affect; record why each check needs
rerunning. A resume or permission/config recovery alone does not invalidate earlier application evidence. A new full
pass requires an explicit request or a documented change affecting the whole matrix.

Before redispatching a still-blocked or unproven check, record the previous attempt's result, the exact remaining gap,
and either a verified recovered prerequisite or a specific alternative method supported by the application/tools.
Verify fixture IDs and required persisted state before dependent execution (§3.1); a fresh worker or another report
of the same gap is not recovery. Attempt authorised fixture/setup recovery before declaring blocked (§2.5). If those
paths fail and no concrete recovery method remains, retain the blocked cells and finish with QA Pass Incomplete after
the other lanes and cleanup conclude. Treat evidenced failures as findings and exhausted recovery paths as incomplete outcomes.

Review the aggregated first-wave results for coverage and finding evidence, then review only new or invalidated
cell/dimension results, results potentially affected by new fixes, and newly disputed findings. Before selecting
follow-ups, map each fix's changed behaviour and shared dependencies to affected original cells, roles, states,
viewports and adjacent regressions. Previously passed results in that impact map need recheck and review; record
the dependency or risk connecting each selected check to the fix. Supply reviewers the accepted ledger, impact map
and evidence references; reuse the original reviewer roles where possible. Previously adjudicated unaffected results
stay accepted. The invoker
performs the final ledger reconciliation without commissioning another full review. A conclusive product failure
stays failed until an implementation change or genuinely conflicting evidence warrants a recheck. Once all required
dimensions have evidenced outcomes, finish QA with the confirmed findings; findings do not require another QA wave.

## 2. Preflight

2.1. Choose and record one interactive browser authority per lane with this precedence:

1. **Explicit choice.** Explicit user choice is a hard constraint and wins first: chrome-devtools, external
   Chrome/extension (Codex Bridge), or the in-app Browser. If that exact surface is unavailable, report it unavailable;
   never substitute another surface without user approval.
2. **Codex browser-client.** Without an explicit choice, use the browser-client when an existing authenticated session,
   extension-dependent/browser-native UI, or visible user-browser state is required and the selected concrete binding
   supports every action and evidence type in the dependent lane. Follow its installed Browser/Chrome skill to select and
   record the concrete binding; Codex Bridge means only the external Chrome/extension binding.
3. **chrome-devtools.** Otherwise default to chrome-devtools MCP, especially for isolated or mutation-heavy flows,
   append-only test data, multi-role work, viewport emulation, DOM/layout evaluation, console/network evidence, and
   parallel lanes.
4. **Mixed pass.** Assign one surface to each tab and dependent stateful lane; use different surfaces only across
   independent lanes. Probe required capabilities before execution. A missing capability does not waive evidence.
   Move the entire dependent lane to a capable surface when the user's explicit choice permits it, or report it blocked.

A request to **show a screenshot** stays on the selected surface and returns captured evidence in chat; it does not require
a headed browser. A request to **open the page in my Chrome**, **let me watch**, or otherwise show a live visible browser
selects external Codex Bridge explicitly. If Bridge is unavailable, report that exact surface unavailable rather than
restarting chrome-devtools without `--headless`.

For every chrome-devtools lane, snapshot the Chrome profile directories per §2.8 **first** — the reachability call launches
Chrome — then verify reachability (`list_pages`) and immediately take the §2.8 delta. For every browser-client lane,
complete §2.9 before acting.

2.2. Discover the intended environment and exact base origin from the user's scope, env, README, or project config;
record both before browser work. For local QA, probe that configured origin first and use its existing env and database.
Do not start an alternate server, switch databases, or override session configuration just for browser QA. If the
configured origin is not up, start only the minimal required local server(s) using existing project/dev-runtime
commands, wait for a real HTTP readiness signal, and record exactly what this QA pass started. During cleanup, stop
only those recorded processes/sessions; if the environment was already running (for example on the user's Mac), leave
it running.

2.3. Verify fixture readiness for every data-dependent local lane under §3.1–§3.2 before execution. An existing
seeder/factory is preferred; use the supported ORM/console, API or UI when one is unavailable. Prepare required local
fixtures even for read-only browser assertions or workers with read-only shell sandboxes. Production observation and explicitly data-read-only scopes use existing data only.

2.4. When the user supplies a design reference, verify it is accessible before starting. Figma URLs require Figma MCP;
attached or repository screenshots/mockups require a readable image at its original resolution.

2.5. Recover missing local fixtures through §3.1–§3.2 before declaring a prerequisite missing. If safe setup remains
unavailable, stop via `plugins/core/conduct/clarification-protocol.md` with the attempted paths and exact denial/error.
Verify the environment before testing and count only evidenced cells as passed.

2.6. Keep the surface selected under §2.1 as the lane's sole interactive browser authority throughout each stateful
flow, including tab recovery. Use Playwright Test only for committed deterministic regression checks and local
expected/actual/diff artifacts. Perform exploratory QA and user actions on the selected surface; if its connection is
unavailable, recover that connection or report the lane blocked under §11.5.

2.7. chrome-devtools MCP: per-project `.mcp.json` / `.cursor/mcp.json` (from `devkit-install --claude|--cursor`) overrides the global entry. Current adapters pass `--headless --isolated`, keeping Chrome in the background and giving every server a throwaway profile. `devkit-install` normalises an existing Codex `~/.codex/config.toml` chrome-devtools entry to the same defaults. Configs generated before that change may omit `--headless` or pin a fixed `--userDataDir=~/.cache/chrome-devtools-mcp/profiles/<project>`; regenerate them rather than working around a visible window or profile collision (§11).

2.8. Identify this pass's Chrome profile, so §10.3 can close exactly that instance. Run step 1 before the first chrome-devtools call of the pass; run step 2 immediately after it. The one new directory is this pass's profile — `--isolated` places it at `$TMPDIR/puppeteer_dev_chrome_profile-<random>`, and Chrome runs with it as `--user-data-dir`.

Pick a `$PASS` slug unique to this QA pass (scope name + start time). `$TMPDIR` is shared by every session on the machine, so a fixed filename lets one pass read another pass's profile and kill its browser — the exact damage §10.4 forbids.

Strip the trailing slash from `$TMPDIR` (macOS sets one). A path recorded as `…/T//puppeteer_…` never matches Chrome's own `--user-data-dir=…/T/puppeteer_…`, and §10.3 silently kills nothing. Snapshot and delta must use the same normalised prefix, or every existing profile reads as new.

```bash
# 1. BEFORE the first chrome-devtools call (§2.1) — Chrome launches on that call
tmp="${TMPDIR:-/tmp}"; tmp="${tmp%/}"; PASS="<scope>-<HHMMSS>"
ls -d "$tmp"/puppeteer_dev_chrome_profile-* 2>/dev/null | sort > "$tmp/devkit-qa-chrome-before.$PASS"

# 2. immediately AFTER it — the delta is this pass's profile
tmp="${TMPDIR:-/tmp}"; tmp="${tmp%/}"; PASS="<same slug>"
ls -d "$tmp"/puppeteer_dev_chrome_profile-* 2>/dev/null | sort \
  | comm -13 "$tmp/devkit-qa-chrome-before.$PASS" -
```

Carry the printed path forward in the agent's own context and bake the literal into §10.3.

A concurrent session that launches Chrome between the two steps also lands in the delta. Keep the steps adjacent, and when the delta holds anything other than exactly one path, kill nothing (§10.5).

2.9. **Codex browser-client environment pin.** The external Codex Bridge binding controls the user's real browser and may
expose signed-in local, stage, and production tabs side by side; the in-app Browser is a distinct concrete binding. Treat
tab discovery as read-only. Listing tabs, reading their current URLs, and taking a read-only snapshot of the current page
are allowed solely to establish the pin, including on production; perform these checks before navigation or interaction:

1. Follow the installed Browser/Chrome skill's setup and documentation. List the available tabs without reading cookies,
   storage, passwords, or profile data.
2. Build an environment map from trusted project/user inputs: exact `scheme://host:port` origins for local, stage, and
   production. Never infer environment from tab order, active-tab status, favicon, or title alone.
3. First check: match the candidate tab's current URL to the intended exact origin and corroborate the project/environment
   with one independent signal (an in-app environment badge, expected tenant/project marker, or known route/content).
   Ambiguous or unmapped origins remain discovery-only and are blocked from navigation, interaction, and mutation.
4. Pin and record `{concrete binding, tab handle/ID, exact origin, environment, project/tenant, account/role}` for the lane.
   Record `not applicable` only when the application genuinely has no such identity dimension; an unknown required
   identity blocks mutation. Do not reuse that tab for another environment.
5. Pre-existing Bridge tabs are inspection-only by default: do not navigate, click, type, submit, resize, or otherwise
   change their page or browser state. Create and pin a new pass-owned tab for local/stage navigation or interaction; it
   shares the external browser's authenticated session. Use a pre-existing tab interactively only after the user explicitly
   authorises that named tab and exact origin, and still apply every pin and production rule here.
6. Second check: immediately before every potentially state-changing action — form submission, confirmation, toggle,
   upload, drag/reorder, create/update/delete, permission/state change, or a click whose effects are not proven read-only —
   revalidate the full pin: the same concrete binding and tab handle, exact origin, and every applicable project/tenant,
   account, and role signal, using trusted visible markers or a safe identity endpoint. Revalidate after navigation,
   redirect, login, popup/new-tab creation, tab replacement, or stale/missing-tab recovery before continuing. A mapped
   external auth origin may be traversed only as part of the expected login flow; no application mutation occurs until the
   tab returns to and revalidates the full app pin.
7. Any binding, tab, origin, project/tenant, account, or role mismatch aborts the action. Do not "correct" it by navigating
   a mismatched pre-existing tab; select or create the right tab, rebuild the pin, and repeat both checks. Apply the
   production gate in §9.5.

2.10. Check host resource usage before dispatch and between waves; include other active QA passes.

- Choose concurrency from independent ledger lanes and the operator's requested parallelism; run isolated lanes
  concurrently within the available harness slots.
- Report sustained memory pressure, paging, and desktop slowdown without automatically throttling the pass. Preserve
  requested parallelism and coverage unless the operator asks to reduce them; executor model cost does not predict
  local browser resource usage.
- Keep global MCP availability intact. For a dedicated worker, resolve inherited server names and suppress only
  unrelated local stdio servers for that invocation (`-c 'mcp_servers.<name>.enabled=false'` in Codex CLI). A browser-only
  lane does not need a local mobile MCP process. HTTP MCPs do not launch local server processes; retain their availability
  unless the lane explicitly restricts its tools. Tool discovery is not evidence of lazy process startup.
- Reuse the lane's owned browser for its sequential routes, viewports, and dependent cells. Close pass-created tabs
  after their evidence is captured when they are no longer needed; keep one owned browser for the connected lane. Revalidate the
  environment/account pin when changing role or route and clean the owned browser after the lane's final call (§10).
- Keep concurrently executing lanes on distinct profiles and dedicated MCP trees (§10.7). Do not attach independent
  workers to one browser to save memory; tabs alone do not isolate cookies or accounts.

## 3. Seed strategy

3.1. **Prepare required local fixtures.** A local QA request authorises and requires append-only test-data preparation
when existing records cannot exercise an assigned case; proceed with that authorised setup before dependent tests. Prefer existing
dev/test seeders and factories. If none covers the case, use the project's ORM/console, supported API or real UI to
create namespaced test users, related entities, files and required states. Inspect the relevant models and invariants
before creating records. Treat fixture preparation as QA setup and preserve application source.
Explicit user/project data restrictions and §9.5 still bind.

The QA lead owns fixture readiness before dispatching dependent test lanes. It may prepare fixtures directly or
delegate a dedicated fixture lane, but must verify its result before releasing the dependent tests. A worker's
read-only shell sandbox, missing seeder or empty DB
is not a reason to omit a local case. If a worker cannot create a fixture, return the exact missing state to the lead;
the lead prepares it through its available authorised tools or a dedicated fixture lane, then reruns the dependent
cells. Apply the QA worker permissions in §12.7; never mutate production to recover.

Map each data-dependent cell to concrete fixture IDs, role, state and required relationships. Verify the record is
reachable by that lane's account before counting the setup complete. An empty-page check proves only the empty state;
it cannot prove populated lists, uploads/downloads, transitions, permissions or other fixture-dependent cases. Seeding
is not applicable only when adequate existing fixtures are verified, the scope is genuinely data-independent, or an
explicit data-read-only restriction applies. For a remaining blocker, report attempted setup paths, exact denial/error
and affected cell IDs; keep those cells blocked/uncovered and the pass incomplete.

3.2. Use **append-only** seeding or a **separate test DB** — record exact command(s). Creating new test users, registering through the UI, logging in as seeded users, and mutating clearly-marked test records is allowed when needed to exercise real flows.

3.3. **Forbidden** against the real DB: `migrate:fresh`, `migrate:refresh`, `migrate:reset`, `db:wipe`, `RefreshDatabase`, truncate, drop.

3.4. For **existing/real accounts**, discover credentials from seeders or env examples — never invent or reset their secrets. For records you create **solely for testing**, you may set a known password (seed one, or register through the UI with a password you choose) so you can log in — mark them clearly as test-only and keep seeding append-only.

3.5. Prefer realistic fixtures over toy placeholders: enough roles, statuses, dates, permissions, files, and related entities to make the UI stateful and clickable.

3.6. **Test password.** Every account this pass creates gets the password `asdasdasd`. Use this fixed devkit test convention directly across projects. When the app's password policy rejects it, derive the shortest compliant variant (`Asdasdasd1!`) and carry the exact string forward. Report the identifier and password of every test-created account with the seed command, marked test-only.

3.7. **Login ladder.** Authenticate when redirected to a login page: walk the ladder before reporting a blocker. Rung 6 is the only legitimate stop. After two failed submits with the same credentials, move to the next rung. Stop at the first rung that authenticates, and record which rung was used.

1. **Discover.** Read credentials from seeders, factories, `.env.example`, `.env.testing`, `docs/`, README. Use them verbatim.
2. **Register.** When public registration exists, sign up through the UI as a new test-only user with the §3.6 password.
3. **Create.** Otherwise create a test-only user through the project's own path — factory, seeder, `tinker`, or a user-create console command — with the §3.6 password and the roles the scenario needs.
4. **Unblock.** Make that account loginable: set `email_verified_at`, clear lockout/throttle state, disable 2FA, set the `active`/`status` column to its enabled value. Apply only to accounts this pass created, or to accounts matching rung 5's pattern.
5. **Reset (gated last resort — prefer rung 3).** Creating a fresh test-only account *with the roles the scenario needs* (rung 3) always beats touching an existing account. Set the §3.6 password on an existing account **only** when its identifier unambiguously matches a test-only pattern (`qa-…`, `test…`, `demo…`, or a known seeder fixture) **and** it fails none of the §9.4 real-account tests. A reset is irreversible — the original hash is unrecoverable. The role you need lives only on a real account → do not reset it: create a test-only account with that role (rung 3), or stop and ask (§3.4, `clarification-protocol.md`). Never guess a found account's password (§3.4).
6. **Stop.** No rung authenticates → `plugins/core/conduct/clarification-protocol.md`. Report the ladder rungs tried.

3.8. **Light rungs for code-editing skills.** Skills that edit code (`devkit-coder`, `devkit-pixel-build`, `devkit-pixel-guard`) walk rungs 1–2 only: discover credentials, or register a test-only user with the §3.6 password. Rungs 3–5 create, unblock, or reset accounts — safe only under the seed rules (§3.2–§3.3) those skills do not load. Both light rungs failing → stop via `plugins/core/conduct/clarification-protocol.md`: report that the route needs auth setup, and which rungs were tried. This is a legitimate stop; giving up before rung 1 is not (§3.7).

## 4. QA surface map

Discover everything below from the codebase before testing or planning.

4.1. **Routes/pages** in scope — protected and public/unauthenticated.

4.2. **Roles**, including unauthenticated visitor, and how to authenticate each.

4.3. **Entity types** exposed by the project (models/routes/forms). Per entity: full lifecycle (create → read → update → delete) plus state transitions.

4.4. **Forms, fields, validation rules** per entity.

4.5. **Permission matrix**: each role × each entity/resource type.

4.6. **Viewport breakpoints** — from project CSS/Tailwind config or `visual/config.json`; fall back to `plugins/frontend/conduct/visual-implementation.md` defaults (mobile 390×844, tablet 768×1024, desktop 1440×1200).

4.7. **Regression surface** — adjacent behaviour reachable from in-scope navigation; discover from routing, not from memory.

4.8. **Design-reference map** — when a reference is supplied, map every frame/screen to its route, UI state, intended
viewport, and responsive variants. Mark any reference with no resolvable live target before execution.

## 5. Scenario matrix

Exhaustive coverage requires all dimensions below; neither skill may skip a dimension to save time. A targeted pass executes the cells selected under §1.4–§1.5 and reports the remaining dimensions as untested.

5.1. **Unauthed protected routes** — `navigate_page`; assert redirect/403.

5.2. **Unauthed public routes** — load anonymously; probe IDOR, exposed data, missing auth on actions/links, reflected input.

5.3. **Per role** — login via real form (`navigate_page` → `fill_form` → submit → `wait_for`). Login fails twice with the same credentials → move to the next §3.7 ladder rung.

5.4. **Per page × viewport** — `resize_page`/`emulate`; `take_snapshot`; run the §6.3 DOM/layout audit; check adaptive
layout. Run existing Playwright Test visual assertions when the project provides them. Capture pixels only under §6.6.

5.5. **Entity lifecycle** — create/read/update/delete + state transitions (`fill_form`, `click`, `handle_dialog`).

5.6. **Field/validation** — invalid and boundary values; assert inline errors and blocked submits.

5.7. **Interaction depth** — varied value sets (empty, min, max, special chars, each enum/option, dependent-field combinations); every toggle, filter, sort, pagination, search, modal, tab, drag/reorder.

5.8. **Cross-role access propagation** — grant then revoke access per controllable section/feature/instance; re-login as affected user; verify UI visibility and route-level block in both directions.

5.9. **Permission matrix** — each role × each resource: access granted/denied correctly.

5.10. **Regression** — re-test adjacent happy paths discovered in §4.7.

5.11. **Console/network** — `list_console_messages` + `list_network_requests` after substantive actions.

5.12. **Design-reference fidelity** (when Figma, approved screenshots, mockups, or other references are supplied) — test
every mapped reference × route/state × viewport from §4.8. For Figma, use `get_design_context` or `get_screenshot`.
Apply every check, in order, from `plugins/frontend/conduct/design-quality.md` **Reference fidelity**. Record the
whole-frame composition and element-inventory result before any element-level assertions; local matches cannot close the
cell without that evidence. Establish fidelity through design measurements plus rendered DOM/computed styles when available. Compare stable reference elements against live bounding boxes and alignment anchors, then
run the project's existing offline pixel diff, or a Playwright expected snapshot, only when reference and live captures
can be normalised to the same viewport, DPR, crop, and dimensions. Otherwise use measured geometry/inventory plus the
smallest matching reference/live crops. Report every unexplained delta and every untested reference state/viewport;
leave CSS fixes to an authorised coding workflow.

## 6. Browser session

6.1. With chrome-devtools, start from the already-open isolated tab when one exists. With browser-client, apply §2.9:
pre-existing external Bridge tabs are inspection-only by default, and navigation or interaction uses a new pass-owned tab
unless the user explicitly authorises a named existing tab and exact origin. Never navigate an unrelated or production
tab to local/stage.

6.2. Take the selected surface's accessibility/DOM snapshot before acting on each page.

6.3. Run the standard probe in `plugins/core/conduct/browser-layout-audit.md` after the page is stable at every tested
viewport. Return concise JSON, not page HTML. At minimum inspect:

- document-level horizontal overflow (`scrollWidth > clientWidth`);
- visible elements escaping the viewport;
- elements whose content is clipped or scrollable on either axis, including computed `overflow-*`;
- visible actionable elements whose centre point is covered by another painted element;
- broken images/assets and visible loading/skeleton markers after readiness;
- each candidate's stable selector or accessible identity, bounding box, scroll/client dimensions, and relevant computed
  styles.

Treat the audit as a candidate generator, not an automatic verdict: carousels, menus, off-canvas panels, code blocks, and
intentional scroll regions can overflow by design. Classify candidates under `browser-layout-audit.md`: candidates
sharing a verified owning component, mechanism and tested state may share one disposition, with exceptions checked
separately. Confirm against interaction behaviour, the design reference, or project intent. A clean audit does not prove visual fidelity because paint, icons, imagery, shadows, and
pseudo-elements can differ without changing DOM geometry.

Then run the UI oracles in `plugins/core/conduct/browser-ui-oracles.md`: those its §2 selects for the change on a spot
or targeted pass, and every applicable §5 oracle — scripted keys and the manual §5.1 states and §5.9 language — on an
exhaustive pass. Apply its §4 measurement rules to every colour, shadow and height you report, including ones measured by
hand.

6.4. Reuse a `take_snapshot` result until navigation, submission, modal state, role, viewport, or another DOM-changing action invalidates it. Use the cached snapshot for consecutive read-only assertions on unchanged state.
Cells may reference the same snapshot, layout/oracle audit or console/network batch when its implementation,
origin/account/role, relevant data state and viewport apply. Record these pins and covered cell/dimension IDs once,
with action-specific results for each functional cell. Capture layout/control-state evidence once per distinct rendered
component state and viewport, shared across functional and visual lanes; remeasure when relevant geometry or styling
changes. Different enum values with equivalent rendering need their own action/result proof, not identical full-page
audits. Check layout-sensitive variants such as empty/error and shortest/longest content explicitly. An unrelated DOM
change invalidates a snapshot without automatically invalidating earlier layout proof for an unchanged component.

6.5. Batch independent browser reads in one tool-call batch when the harness supports it. Prefer one structured DOM
evaluation for multiple read-only assertions; never replace a user interaction or server-side permission check with
synthetic DOM mutation.

6.6. Capture pixels only for a supplied design-reference comparison, a local visual-regression baseline/diff, or evidence
for a confirmed visual finding. Pass `filePath` so chrome-devtools saves the image instead of attaching it to the model
response. `filePath` must resolve inside the MCP server's writable root, normally the project directory; a path outside
it is refused. A lane that must not write into the repository captures inline instead. Also capture the smallest
element crop needed to decide a candidate the DOM cannot settle: native control chrome, or a measurement the UI oracle
probe marks `indeterminate`. Keep passing captures as local artifacts and report their textual assertion or path. When interpretation is still required after snapshot, geometry, and
local diff evidence, inspect the smallest useful crop of the diff plus the matching reference crop; use a full-frame image
only for whole-frame composition.

6.7. Prefer Playwright Test for repeatable visual regression when the project already has it or dependency addition is
authorised. Configure deterministic fixtures, fonts, animations, viewport, colour scheme, locale, timezone, and device
scale; run baselines in one canonical environment. Use `toHaveScreenshot` for local comparison and retain trace/screenshots
on failure. The model reads the textual assertion and diff path first; it does not ingest passing images.

6.8. Use this evidence order: accessibility snapshot → batched DOM/layout audit → console/network → local Playwright
assertion/diff → cropped visual inspection. Escalate upward only when the cheaper layer cannot prove or explain the result.

## 7. Finding format

7.1. One finding per defect. Required fields: ID · route/page · environment/origin · browser surface · role · viewport ·
severity · reproduction steps (browser actions) · expected · actual · evidence. Evidence names the strongest applicable proof: snapshot identity, selector and
geometry/computed style, console/network entry, Playwright assertion/diff path, or saved screenshot crop. For design deltas,
also cite the design reference/frame and expected versus actual measurement or appearance.

7.2. Assign severity from demonstrated user impact, not agent count or confidence:

- `blocking` — the scoped feature cannot be accepted: a required core flow is unusable, or a reproduced defect exposes
  unauthorised data/actions, corrupts data or causes irreversible loss.
- `major` — a required operation fails for an assigned role/state, a file cannot be uploaded/accessed/downloaded as
  required, or unreadable/inaccessible controls or broken navigation prevent a user task.
- `minor` — a limited non-critical case, content/format inconsistency or usability defect; required flows remain usable.
- `cosmetic` — a confirmed visual/reference mismatch with no functional, readability or accessibility impact.

Missing prerequisites and unexercised cells are coverage blockers, not automatically product defects (§3.1).

7.3. Findings must be explicit enough for another session to fix with zero extra context.

7.4. **Confirm before filing.** Every retained finding must identify the violated expectation from the user's scope,
acceptance criteria, project/business rules, supplied design reference, or an applicable canonical UI/layout oracle.
Require a reproducible expected-versus-actual failure in the pinned environment, account, fixture state and viewport,
with §6 browser evidence. Apply `browser-ui-oracles.md` §3.4 to every visual probe candidate. Styling preference,
speculation, source inspection alone and reviewer agreement are not browser proof. Keep uncertain candidates separate
from confirmed findings, retain them as unresolved, and request a named follow-up cell.

Give coverage and evidence reviewers the canonical §5–§7 rules plus the applicable UI/layout oracles and expectation
sources. The invoking agent applies the same gates when reconciling their reports, rejects unsupported findings,
deduplicates one root defect and records unresolved cells. Report an in-scope pre-existing defect with that label;
being outside the changed diff does not waive its user impact during scoped browser QA.

## 8. Browser tools

**chrome-devtools:** `navigate_page`, `new_page`, `list_pages`, `select_page`, `click`, `fill`, `fill_form`, `hover`, `press_key`, `type_text`, `take_snapshot`, `take_screenshot`, `resize_page`, `emulate`, `evaluate_script`, `wait_for`, `handle_dialog`, `list_console_messages`, `list_network_requests`, `upload_file`, `drag`.

**Codex browser-client:** when the Codex Browser or Chrome skill is available and connected, follow that skill's
bootstrap, browser-selection, full documentation-read, and tab APIs. Record the selected concrete binding: in-app Browser
(`iab`) or external Chrome/extension. "Codex Bridge" in these rules means only the external Chrome/extension binding. Use
browser-client only under §2.1, §2.9, §6.1, §9.5, and §10.10, using its documented APIs. Recover a lost binding through
that binding's documented connection path or report it blocked.

**Figma** (when URLs supplied as design references): `get_design_context`, `get_screenshot`. Read each tool schema before first use.

## 9. Hard rules

9.1. Report QA findings and preserve application source; route separately authorised fixes through `devkit-coder`.

9.2. Project-agnostic — discover entity, role, route, and feature names from inputs only.

9.3. Resolve every execution prerequisite to a concrete value, or name the exact missing input and mark it blocked.

9.4. **Never alter a real account's credentials.** Do not reset, set, or overwrite the password of any account whose identifier does not unambiguously match a test-only pattern (`qa-…`, `test…`, `demo…`, seeder fixture). Any of these makes it a **real account**, off-limits regardless of the pattern: a personal or real-domain email address; the repo's git user email (`git config user.email`); an admin/owner/superuser role. Resets are irreversible — the original password hash is unrecoverable. Need a role that only a real account has → create a test-only account with that role (§3.7 rung 3), or stop via `clarification-protocol.md`. This rule outranks any pressure to get logged in: a blocked route is a finding, never a licence to touch a real account.

9.5. **Production is read-only by default.** A generic QA request never authorises production mutation, even when external
Codex Bridge exposes an already authenticated production tab. The discovery-only reads in §2.9 may establish the pin;
afterward, read-only navigation, snapshots, and observation are allowed. Before any production state change, stop via
`clarification-protocol.md` and obtain explicit user
confirmation naming the exact production origin and the exact action/data in scope. Confirmation for stage/local, or a
bare "test production", does not transfer. Never seed production, create test accounts/records there, change permissions,
submit destructive or business transactions, upload files, send messages, trigger jobs/webhooks, or reset credentials
under this skill. If a click's effects are uncertain, treat it as a mutation and do not click.

## 10. Cleanup

10.1. Stop only the dev-server processes/sessions this pass started (§2.2). Leave an already-running environment up.

10.2. Leave seeded append-only records in place unless the project ships an explicit safe cleanup command.

10.3. Close this pass's isolated chrome-devtools Chrome as the final action for that surface. chrome-devtools MCP has no browser-close tool (`close_page` refuses the last page) and the Chrome subprocess is reaped only when its MCP server exits, so a pass that skips this leaves a Chrome instance running for the rest of the session. Signal exactly one process: the Chrome **browser** process owning this pass's profile. Its helpers exit with it, and the MCP server is untouched.

Substitute the literal path from §2.8 for `<profile>`. Run the steps in order and stop if any check fails.

```bash
profile='/absolute/path/from/2.8/puppeteer_dev_chrome_profile-XXXXXX'

# 1. resolve the browser process. Skip helpers (--type=), anything whose executable is not Chrome
#    (a shell or editor may carry the same path in its arguments), and any profile that merely
#    starts with $profile — ownership is exact-match, never prefix.
main=$(pgrep -f -- "--user-data-dir=$profile" | while read -r p; do
  cmd=$(ps -p "$p" -o command= 2>/dev/null)
  printf '%s' "$cmd" | grep -q -- ' --type=' && continue
  comm=$(ps -p "$p" -o comm= 2>/dev/null); comm="${comm##*/}"
  printf '%s' "$comm" | grep -qE '^(Google Chrome|Chromium|chrome|chromium|google-chrome|chrome-headless-shell)$' || continue
  owned=$(printf '%s\n' "$cmd" | tr ' ' '\n' | grep '^--user-data-dir=' | head -1 | cut -d= -f2-)
  [ "$owned" = "$profile" ] || continue
  printf '%s\n' "$p"
done)

# 2. fire only on exactly one process; anything else is ambiguous
[ "$(printf '%s\n' "$main" | grep -c .)" = "1" ] || { echo "abort: expected exactly 1 Chrome browser process"; exit 1; }

# 3. one SIGTERM to the browser process; Chrome reaps its own helpers
kill "$main"
sleep 2
ps -p "$main" >/dev/null 2>&1 && echo "still alive — report it, never escalate to a broader pattern"

tmp="${TMPDIR:-/tmp}"; tmp="${tmp%/}"; rm -f "$tmp/devkit-qa-chrome-before.$PASS"
```

Run it as one shell invocation so `exit 1` aborts the whole snippet. `return 1` would be a no-op outside a function and fall through to the `kill`.

Two portability traps, both verified: iterate with `while read`, not `for p in $pids` — zsh does not word-split unquoted parameters, so the `for` form collapses to one bogus PID and the guard aborts every time. And filter with `grep`, not `case … ;; esac` — bash rejects a one-line `case` inside `$( … )` with `syntax error near unexpected token ';;'`, while zsh accepts it.

Zero matches means the recorded path is wrong (usually a `//` from an unnormalised `$TMPDIR`, §2.8). Fix the path; never widen the pattern.

The kill is safe by construction: the pattern `--user-data-dir=<profile>` never matches the MCP server (its own flag is `--userDataDir`, and under `--isolated` it carries no profile path at all), so the server survives and the session's other MCP tools keep working.

After the kill, call no chrome-devtools tool: the server's `getContext()` relaunches Chrome on the next call under a fresh, unrecorded profile. If testing must continue, redo §2.8 for the new instance.

10.4. Never signal a shared/current-session MCP server, and never kill any MCP or browser by a pattern. The only MCP exception is the exact dedicated-executor cleanup in §10.8 after the executor's final browser call and ownership revalidation. Forbidden: `pkill -f chrome-devtools-mcp`, `pkill -f node`, `pkill -f puppeteer_dev_chrome_profile`, `pkill -f chrome`, `killall "Google Chrome"`, and every other glob or wrapper (`npx`, `npm exec`) match. Killing a chrome-devtools-mcp server tears down the whole MCP connection for that session — the failure this rule exists to prevent — and a glob over profiles or the Chrome binary destroys the browsers of concurrent sessions (extra terminals, worktrees, sibling repos), each of which owns its own isolated profile, along with the user's personal Chrome. Killing this pass's Chrome browser process leaves its MCP server healthy: the server relaunches Chrome on the next tool call.

10.5. When the §2.8 delta is not exactly one path, kill nothing. Empty means Chrome belongs to an earlier pass in the same MCP server, or the project is on a shared non-isolated profile (`~/.cache/chrome-devtools-mcp/…`) that other sessions may attach to; two or more paths mean a concurrent session raced the §2.8 window and ownership is ambiguous. Report that the browser was left running and why. For the shared-profile case, tell the user to regenerate the MCP config (`bin/devkit-install --claude --project=.`) to get `--isolated`.

10.6. Report the cleanup outcome in the QA summary: which servers were stopped, which Chrome profile was killed (or why not).

10.7. Allow multi-agent browser fan-out only after an ownership handshake. Start executors through their first chrome-devtools call one at a time so §2.8 yields exactly one profile per lane. Before releasing concurrent work, each executor records its literal profile path, exact Chrome browser PID, and the dedicated `chrome-devtools-mcp` ancestor PID plus process start identity. Assert that every lane has a distinct profile, Chrome PID, and MCP PID. Ambiguous or shared ownership runs sequentially and leaves the ambiguous process untouched.

10.8. Clean each completed executor tree immediately. After its last browser call, the executor closes the exact Chrome browser per §10.3, then revalidates the recorded dedicated MCP PID and process start identity and sends one SIGTERM to that exact MCP PID — never a name/pattern match. Verify that its telemetry watchdog and Chrome helpers exited; if a recorded child survives, signal only that exact revalidated child. Remove the literal profile directory only after no live process references it. Report the profile, MCP PID, and cleanup result before the executor returns. This dedicated-executor exception does not permit signaling a shared/current-session MCP (§10.4).

10.9. Pause by persisting the coverage ledger, evidence, ownership records, and repository snapshot, then clean completed executor trees with §10.8. Reap completed browser workers rather than pausing them with `SIGSTOP`, which retains memory and bypasses idle-timeout cleanup. Active lanes may be resumed only when their exact ownership remains valid; otherwise terminate their exact owned trees and restart those cells.

10.10. Browser-client tabs are not disposable MCP processes. Preserve every pre-existing tab under §2.9; never close,
navigate, sign out, clear site data, or otherwise alter it unless the user explicitly authorised that named tab and exact
origin for interaction. A tab created by this pass may be closed only when its recorded handle still resolves to the same
full pin and the selected binding's documentation provides an exact tab-close action; otherwise leave it open and report
it. For external Bridge, never close a browser window/profile or clear cookies, storage, history, downloads, passwords, or
sessions. Report the concrete binding, pre-existing tabs preserved, and pass-created tabs closed or left open.

## 11. Stuck browser

11.1. `The browser is already running for <dir>. Use --isolated to run multiple browser instances.` means a **live** MCP server from another session already owns that fixed profile. It is not a stale lock, and the browser is not yours. Kill nothing.

11.2. Recover by config, not by signals. Regenerate the project's MCP config so chrome-devtools runs with `--isolated` (`bin/devkit-install --claude --project=.`, plus `--cursor` when the project has `.cursor/mcp.json`), then restart the session's MCP connection. Until that lands, drive the browser that is already running (`list_pages` → `select_page`) instead of forcing a second one.

11.3. Never kill by profile name. Under a fixed profile the path sits in the MCP server's **own** arguments — `npm exec chrome-devtools-mcp@latest --userDataDir=<path>` — so `pkill -f <profile-name>` kills the server, every browser tool dies for the rest of the session, and only a manual `/mcp` reconnect restores them. Chrome's own flag is spelled `--user-data-dir=`; that spelling plus the §10.3 executable check is the only selector that cannot hit the server.

11.4. Never `kill -9` a browser. SIGTERM is sufficient (§10.3) and lets Chrome flush profile state; SIGKILL leaves `SingletonLock`, `SingletonSocket`, and `SingletonCookie` pointing at a dead PID. Chrome clears those on the next launch, so a stale lock is never the cause of §11.1 — do not delete lock files to "fix" it.

11.5. When the browser tools are already gone because a server was killed, stop browser execution, report the loss and
tell the user to reconnect via `/mcp`. Resume on the selected surface after reconnection under §2.6.

## 12. Lane briefs

12.1. Create each brief from its own target and resolve its lane ID, account, project and expectations independently.
Reuse canonical references while grounding every target-specific field afresh.

12.2. Before dispatch, verify three facts: the lane ID is unused by any existing brief, report or log; the account is
the one whose fixture owns the route (demo and QA-fixture accounts often use different credentials); and the fixture
holds the state the lane measures, not an empty list.

12.3. Scope a lane to at most five routes, two viewports and two or three oracles. Name every route and state
explicitly; a lane left to choose tests something out of scope, or code that is still changing.
Assign each page or connected flow to one executor, covering its applicable controls, hover/keyboard-focus states and
assigned viewports in the same lane. Parallelise across independent roles and flows. An explicit spot scope or named follow-up under §1.7 can cover a single control.
For a follow-up, include §1.7, accepted evidence references and only the remaining actions/dimensions plus necessary
setup. Scope the follow-up to those remaining checks and retain accepted results from the original matrix.

12.4. Inline the probe bytes (`browser-ui-oracles.md` §3.1) only when an assigned check needs that probe. Cite applicable conduct sections by path when the executor can read
the toolkit; copy the applicable excerpt verbatim when it cannot, preserving the canonical rule.

12.5. State the acceptance question plainly and, where possible, as a count: "how many filled primary buttons are
visible at rest", not "check the hierarchy". A presence question cannot find the extra one.

12.6. A dispatched lane writes its result into a pass-owned temporary directory outside the repository, named in its
brief as an exception to the skill's no-report-file rule. The top-level pass ingests the result, reports in chat, and
deletes the directory unless the user asked to keep it.
Before cleanup, reconcile collected evidence against the assigned checks. Complete any still-available missing checks
in the same owned browser, including hover/focus and lazy-loaded panels reached through real scrolling and readiness
checks. Keep ownership through completion of the available assigned checks, then clean up. If a prerequisite prevents
completion, report the exact blocked check and attempted recovery under §1.7; cleanup still remains mandatory.

12.7. Launch every Codex QA worker with full filesystem/network access and browser tools approved without prompts:

```bash
codex exec --sandbox danger-full-access -c 'approval_policy="never"' \
  -c 'mcp_servers.chrome-devtools.default_tools_approval_mode="approve"' \
  <other-lane-arguments> < /dev/null
```

- Apply these permissions to ordinary browser QA, Luna QA, missing-evidence waves and resumed workers unless the user explicitly restricts access.
- Resolve per-tool overrides before dispatch; `approval_policy="never"` alone rejects tools that still require approval.
- Keep the lane's task scope and mutation policy; full runtime access does not authorise application-source edits or production mutation (§9.5).
- Keep each attempt's log under its own name; shell redirection truncates the previous one.
- Supervise progress and process exit (§12.8) and let a progressing lane continue. Stop only at an explicit user deadline or after confirming a stalled process/provider; preserve evidence and rerun incomplete cells.
- Compare pixels only between captures from the same headless or headed mode with the device scale pinned.

12.8. Watch every terminal state: result written, process exited, provider error, explicit deadline or confirmed stall. Confirm each signal is
written to the file being watched; an exit line echoed by the wrapper never reaches the lane's own log.

12.9. On a provider error, probe the provider with a one-line request before re-dispatching, and stop after a second
consecutive failure instead of retrying.

12.10. Run lanes in parallel only when their browsers (§10.7), accounts, record namespaces and datastore writes are
isolated. Run lanes that share mutable state sequentially, and let isolated read-only lanes proceed concurrently
within available harness slots.

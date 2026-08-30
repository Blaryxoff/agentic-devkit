# Browser QA

Canonical rules for browser-based QA skills (`devkit-browser`, `devkit-browser-ralphex`). Skills cite sections here; do not duplicate these rules in skill bodies.

## 1. Scope

1.1. Input is always a scope: a feature name, a route/page set, or `whole project`.

1.2. Discover routes, roles, entities, and credentials from the codebase — never hardcode project-specific names or secrets.

1.3. Apply `plugins/core/conduct/inputs-grounding-gate.md` before mapping the QA surface.

1.4. Classify the pass before preflight. **Targeted** means the user explicitly says `smoke`, `only`, incremental, or names a regression/route/viewport to check while work is still changing. **Exhaustive** means the user says `full`, `e2e`, `exhaustive`, `final`, requests the whole project, or asks for feature QA without a narrower boundary.

1.5. A targeted pass verifies every explicitly selected matrix cell plus its directly adjacent regression path, reports every omitted dimension, and never claims final acceptance. Run the exhaustive pass once the implementation is stable; do not repeat the whole matrix after each intermediate fix.

## 2. Preflight

2.1. Choose and record one interactive browser authority per lane with this precedence:

1. **Explicit choice.** Explicit user choice is a hard constraint and wins first: chrome-devtools, external
   Chrome/extension (Codex Bridge), or the in-app Browser. If that exact surface is unavailable, report it unavailable;
   never substitute another surface without user approval.
2. **Codex browser-client.** Without an explicit choice, use the browser-client when an existing authenticated session,
   extension-dependent/browser-native UI, or visible user-browser state is required and the selected concrete binding
   supports every action and evidence type in the dependent lane. Follow its installed Browser/Chrome skill to select and
   record the concrete binding; Codex Bridge means only the external Chrome/extension binding, never the in-app Browser.
3. **chrome-devtools.** Otherwise default to chrome-devtools MCP, especially for isolated or mutation-heavy flows,
   append-only test data, multi-role work, viewport emulation, DOM/layout evaluation, console/network evidence, and
   parallel lanes.
4. **Mixed pass.** A pass may use different surfaces for independent lanes, but never both on the same tab or dependent
   stateful lane. Probe required capabilities before execution. A missing capability does not waive evidence.
   Move the entire dependent lane to a capable surface when the user's explicit choice permits it, or report it blocked.

For every chrome-devtools lane, snapshot the Chrome profile directories per §2.8 **first** — the reachability call launches
Chrome — then verify reachability (`list_pages`) and immediately take the §2.8 delta. For every browser-client lane,
complete §2.9 before acting.

2.2. Discover the intended environment and exact base origin from the user's scope, env, README, or project config;
record both before browser work. For local QA, verify the dev server is up. If it is not, start only the minimal required
local server(s) using existing project/dev-runtime commands, wait for a real HTTP readiness signal, and record exactly
what this QA pass started. During cleanup, stop only those recorded processes/sessions; if the environment was already
running (for example on the user's Mac), leave it running.

2.3. For each mutation-capable non-production lane, verify DB or test-DB access and at least one usable seeder/factory
path. Read-only lanes, including production observation, use existing data and mark DB/seeder setup as not applicable.

2.4. When the user supplies a design reference, verify it is accessible before starting. Figma URLs require Figma MCP;
attached or repository screenshots/mockups require a readable image at its original resolution.

2.5. Missing prerequisite → stop via `plugins/core/conduct/clarification-protocol.md`. Never test against an unverified environment.

2.6. Keep the surface selected under §2.1 as the lane's sole interactive browser authority. Do not alternate
chrome-devtools and browser-client against one stateful flow or use one to recover the other's tab. Playwright Test may
run committed deterministic regression checks and produce local expected/actual/diff artifacts; it must not drive
exploratory QA, replace the selected surface's actions, or become a fallback when that browser connection is unavailable.

2.7. chrome-devtools MCP: per-project `.mcp.json` / `.cursor/mcp.json` (from `devkit-install --claude|--cursor`) overrides the global entry. Current adapters pass `--headless --isolated`, keeping Chrome in the background and giving every server a throwaway profile. Configs generated before that change pin a fixed `--userDataDir=~/.cache/chrome-devtools-mcp/profiles/<project>`; two sessions on such a project collide on the profile lock (§11). Regenerate them rather than working around the collision.

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

Carry the printed path forward: `devkit-browser` keeps it in the agent's own context and bakes the literal into §10.3; `devkit-browser-ralphex` writes it into the dated `docs/qa/` report, because its cleanup task runs in a later session.

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

## 3. Seed strategy

3.1. Discover existing seeders; prefer dev/test fixture sets.

3.2. Use **append-only** seeding or a **separate test DB** — record exact command(s). Creating new test users, registering through the UI, logging in as seeded users, and mutating clearly-marked test records is allowed when needed to exercise real flows.

3.3. **Forbidden** against the real DB: `migrate:fresh`, `migrate:refresh`, `migrate:reset`, `db:wipe`, `RefreshDatabase`, truncate, drop.

3.4. For **existing/real accounts**, discover credentials from seeders or env examples — never invent or reset their secrets. For records you create **solely for testing**, you may set a known password (seed one, or register through the UI with a password you choose) so you can log in — mark them clearly as test-only and keep seeding append-only.

3.5. Prefer realistic fixtures over toy placeholders: enough roles, statuses, dates, permissions, files, and related entities to make the UI stateful and clickable.

3.6. **Test password.** Every account this pass creates gets the password `asdasdasd`. This is a devkit convention, not a project secret — do not discover it and do not vary it per project. When the app's password policy rejects it, derive the shortest compliant variant (`Asdasdasd1!`) and carry the exact string forward. Report the identifier and password of every test-created account with the seed command, marked test-only.

3.7. **Login ladder.** A redirect to a login page is the cue to authenticate, never a blocker — walk the ladder before calling anything blocked. Rung 6 is the only legitimate stop. Never loop on the login form: two failed submits with the same credentials mean that rung is dead — move to the next rung. Stop at the first rung that authenticates, and record which rung was used.

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

5.3. **Per role** — login via real form (`navigate_page` → `fill_form` → submit → `wait_for`). Login fails twice with the same credentials → walk the §3.7 ladder; never re-submit the same form a third time.

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
cell without that evidence. Capture design measurements plus rendered DOM/computed styles when available; do not approve
by casual visual resemblance. Compare stable reference elements against live bounding boxes and alignment anchors, then
run the project's existing offline pixel diff, or a Playwright expected snapshot, only when reference and live captures
can be normalised to the same viewport, DPR, crop, and dimensions. Otherwise use measured geometry/inventory plus the
smallest matching reference/live crops. Report every unexplained delta and every untested reference state/viewport; never
silently fix CSS.

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
intentional scroll regions can overflow by design. Confirm each candidate against interaction behaviour, the design
reference, or project intent. A clean audit does not prove visual fidelity because paint, icons, imagery, shadows, and
pseudo-elements can differ without changing DOM geometry.

6.4. Reuse a `take_snapshot` result until navigation, submission, modal state, role, viewport, or another DOM-changing action invalidates it. Do not snapshot unchanged state before consecutive read-only assertions.

6.5. Batch independent browser reads in one tool-call batch when the harness supports it. Prefer one structured DOM
evaluation for multiple read-only assertions; never replace a user interaction or server-side permission check with
synthetic DOM mutation.

6.6. Capture pixels only for a supplied design-reference comparison, a local visual-regression baseline/diff, or evidence
for a confirmed visual finding. Pass `filePath` so chrome-devtools saves the image instead of attaching it to the model
response. Do not open or attach a passing capture. When interpretation is still required after snapshot, geometry, and
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

7.2. Severity: `blocking` | `major` | `minor` | `cosmetic`.

7.3. Findings must be explicit enough for another session to fix with zero extra context.

## 8. Browser tools

**chrome-devtools:** `navigate_page`, `new_page`, `list_pages`, `select_page`, `click`, `fill`, `fill_form`, `hover`, `press_key`, `type_text`, `take_snapshot`, `take_screenshot`, `resize_page`, `emulate`, `evaluate_script`, `wait_for`, `handle_dialog`, `list_console_messages`, `list_network_requests`, `upload_file`, `drag`.

**Codex browser-client:** when the Codex Browser or Chrome skill is available and connected, follow that skill's
bootstrap, browser-selection, full documentation-read, and tab APIs. Record the selected concrete binding: in-app Browser
(`iab`) or external Chrome/extension. "Codex Bridge" in these rules means only the external Chrome/extension binding. Use
browser-client only under §2.1, §2.9, §6.1, §9.5, and §10.10; do not invent tool calls from chrome-devtools names or
substitute Computer Use/standalone Playwright for this surface.

**Figma** (when URLs supplied as design references): `get_design_context`, `get_screenshot`. Read each tool schema before first use.

## 9. Hard rules

9.1. QA only — report findings; never fix code.

9.2. Project-agnostic — discover entity, role, route, and feature names from inputs only.

9.3. No `TBD` in outputs that block execution.

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
  printf '%s' "$comm" | grep -qE '^(Google Chrome|Chromium|chrome|chromium|google-chrome)$' || continue
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

10.9. Pause by persisting the coverage ledger, evidence, ownership records, and repository snapshot, then clean completed executor trees with §10.8. Do not keep completed browser workers under long-lived `SIGSTOP`: stopped processes retain memory and bypass idle-timeout cleanup. Active lanes may be resumed only when their exact ownership remains valid; otherwise terminate their exact owned trees and restart those cells.

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

11.5. When the browser tools are already gone because a server was killed, stop. Do not respawn chrome-devtools by hand
and do not use Playwright Test as an interactive fallback (§2.6). Report the loss and tell the user to reconnect via `/mcp`.

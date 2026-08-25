# Browser QA

Canonical rules for browser-based QA skills (`devkit-browser`, `devkit-browser-ralphex`). Skills cite sections here; do not duplicate these rules in skill bodies.

## 1. Scope

1.1. Input is always a scope: a feature name, a route/page set, or `whole project`.

1.2. Discover routes, roles, entities, and credentials from the codebase — never hardcode project-specific names or secrets.

1.3. Apply `plugins/core/conduct/inputs-grounding-gate.md` before mapping the QA surface.

1.4. Classify the pass before preflight. **Targeted** means the user explicitly says `smoke`, `only`, incremental, or names a regression/route/viewport to check while work is still changing. **Exhaustive** means the user says `full`, `e2e`, `exhaustive`, `final`, requests the whole project, or asks for feature QA without a narrower boundary.

1.5. A targeted pass verifies every explicitly selected matrix cell plus its directly adjacent regression path, reports every omitted dimension, and never claims final acceptance. Run the exhaustive pass once the implementation is stable; do not repeat the whole matrix after each intermediate fix.

## 2. Preflight

2.1. Snapshot the Chrome profile directories per §2.8 **first** — the reachability call below launches Chrome. Then verify chrome-devtools MCP is reachable (`list_pages`), and immediately take the §2.8 delta.

2.2. Verify the dev server is up; discover base URL from env, README, or project config. If it is not up, start only the minimal required local server(s) using existing project/dev-runtime commands, wait for a real HTTP readiness signal, and record exactly what this QA pass started. During cleanup, stop only those recorded processes/sessions; if the environment was already running (for example on the user's Mac), leave it running.

2.3. Verify DB or test-DB access and at least one usable seeder/factory path.

2.4. When the user supplies a design reference, verify it is accessible before starting. Figma URLs require Figma MCP;
attached or repository screenshots/mockups require a readable image at its original resolution.

2.5. Missing prerequisite → stop via `plugins/core/conduct/clarification-protocol.md`. Never test against an unverified environment.

2.6. Do not use Playwright as a second browser layer for devkit QA. The browser authority is chrome-devtools MCP; lifecycle helpers are limited to starting/stopping local dev servers.

2.7. chrome-devtools MCP: per-project `.mcp.json` / `.cursor/mcp.json` (from `devkit-install --claude|--cursor`) overrides the global entry. Current adapters pass `--isolated`, giving every server a throwaway profile. Configs generated before that change pin a fixed `--userDataDir=~/.cache/chrome-devtools-mcp/profiles/<project>`; two sessions on such a project collide on the profile lock (§11). Regenerate them rather than working around the collision.

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

5.4. **Per page × viewport** — `resize_page`/`emulate`; `take_snapshot` + `take_screenshot`; check adaptive layout.

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
by casual visual resemblance. Report every unexplained delta and every untested reference state/viewport; never silently
fix CSS.

## 6. Browser session

6.1. Start from the browser tab already open when one exists; do not navigate away unless the scope requires it.

6.2. `take_snapshot` before acting on each page.

6.3. `take_screenshot` on every finding and at least once per page × viewport.

6.4. Reuse a `take_snapshot` result until navigation, submission, modal state, role, viewport, or another DOM-changing action invalidates it. Do not snapshot unchanged state before consecutive read-only assertions.

6.5. Batch independent MCP reads in one tool-call batch when the harness supports it. Prefer one `evaluate_script` call for multiple read-only DOM assertions; never replace a user interaction or server-side permission check with synthetic DOM mutation.

6.6. Capture one screenshot for multiple assertions against the same unchanged page state. Keep the mandatory evidence from §6.3; remove only redundant captures.

## 7. Finding format

7.1. One finding per defect. Required fields: ID · route/page · role · viewport · severity · reproduction steps (MCP actions) · expected · actual · screenshot reference · console/network evidence. For design deltas, also cite the design reference/frame and expected versus actual measurement or appearance.

7.2. Severity: `blocking` | `major` | `minor` | `cosmetic`.

7.3. Findings must be explicit enough for another session to fix with zero extra context.

## 8. MCP tools

**chrome-devtools:** `navigate_page`, `new_page`, `list_pages`, `select_page`, `click`, `fill`, `fill_form`, `hover`, `press_key`, `type_text`, `take_snapshot`, `take_screenshot`, `resize_page`, `emulate`, `evaluate_script`, `wait_for`, `handle_dialog`, `list_console_messages`, `list_network_requests`, `upload_file`, `drag`.

**Figma** (when URLs supplied as design references): `get_design_context`, `get_screenshot`. Read each tool schema before first use.

## 9. Hard rules

9.1. QA only — report findings; never fix code.

9.2. Project-agnostic — discover entity, role, route, and feature names from inputs only.

9.3. No `TBD` in outputs that block execution.

9.4. **Never alter a real account's credentials.** Do not reset, set, or overwrite the password of any account whose identifier does not unambiguously match a test-only pattern (`qa-…`, `test…`, `demo…`, seeder fixture). Any of these makes it a **real account**, off-limits regardless of the pattern: a personal or real-domain email address; the repo's git user email (`git config user.email`); an admin/owner/superuser role. Resets are irreversible — the original password hash is unrecoverable. Need a role that only a real account has → create a test-only account with that role (§3.7 rung 3), or stop via `clarification-protocol.md`. This rule outranks any pressure to get logged in: a blocked route is a finding, never a licence to touch a real account.

## 10. Cleanup

10.1. Stop only the dev-server processes/sessions this pass started (§2.2). Leave an already-running environment up.

10.2. Leave seeded append-only records in place unless the project ships an explicit safe cleanup command.

10.3. Close this pass's Chrome as the final action. chrome-devtools MCP has no browser-close tool (`close_page` refuses the last page) and the Chrome subprocess is reaped only when its MCP server exits, so a pass that skips this leaves a Chrome instance running for the rest of the session. Signal exactly one process: the Chrome **browser** process owning this pass's profile. Its helpers exit with it, and the MCP server is untouched.

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

10.4. Never signal the MCP server, and never kill by a pattern. Forbidden: `pkill -f chrome-devtools-mcp`, `pkill -f node`, `pkill -f puppeteer_dev_chrome_profile`, `pkill -f chrome`, `killall "Google Chrome"`, and every other glob or wrapper (`npx`, `npm exec`) match. Killing a chrome-devtools-mcp server tears down the whole MCP connection for that session — the failure this rule exists to prevent — and a glob over profiles or the Chrome binary destroys the browsers of concurrent sessions (extra terminals, worktrees, sibling repos), each of which owns its own isolated profile, along with the user's personal Chrome. Killing this pass's Chrome browser process leaves its MCP server healthy: the server relaunches Chrome on the next tool call.

10.5. When the §2.8 delta is not exactly one path, kill nothing. Empty means Chrome belongs to an earlier pass in the same MCP server, or the project is on a shared non-isolated profile (`~/.cache/chrome-devtools-mcp/…`) that other sessions may attach to; two or more paths mean a concurrent session raced the §2.8 window and ownership is ambiguous. Report that the browser was left running and why. For the shared-profile case, tell the user to regenerate the MCP config (`bin/devkit-install --claude --project=.`) to get `--isolated`.

10.6. Report the cleanup outcome in the QA summary: which servers were stopped, which Chrome profile was killed (or why not).

## 11. Stuck browser

11.1. `The browser is already running for <dir>. Use --isolated to run multiple browser instances.` means a **live** MCP server from another session already owns that fixed profile. It is not a stale lock, and the browser is not yours. Kill nothing.

11.2. Recover by config, not by signals. Regenerate the project's MCP config so chrome-devtools runs with `--isolated` (`bin/devkit-install --claude --project=.`, plus `--cursor` when the project has `.cursor/mcp.json`), then restart the session's MCP connection. Until that lands, drive the browser that is already running (`list_pages` → `select_page`) instead of forcing a second one.

11.3. Never kill by profile name. Under a fixed profile the path sits in the MCP server's **own** arguments — `npm exec chrome-devtools-mcp@latest --userDataDir=<path>` — so `pkill -f <profile-name>` kills the server, every browser tool dies for the rest of the session, and only a manual `/mcp` reconnect restores them. Chrome's own flag is spelled `--user-data-dir=`; that spelling plus the §10.3 executable check is the only selector that cannot hit the server.

11.4. Never `kill -9` a browser. SIGTERM is sufficient (§10.3) and lets Chrome flush profile state; SIGKILL leaves `SingletonLock`, `SingletonSocket`, and `SingletonCookie` pointing at a dead PID. Chrome clears those on the next launch, so a stale lock is never the cause of §11.1 — do not delete lock files to "fix" it.

11.5. When the browser tools are already gone because a server was killed, stop. Do not respawn chrome-devtools by hand and do not fall back to Playwright (§2.6). Report the loss and tell the user to reconnect via `/mcp`.

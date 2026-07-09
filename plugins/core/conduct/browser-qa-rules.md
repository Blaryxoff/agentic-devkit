# Browser QA

Canonical rules for browser-based QA skills (`devkit-browser`, `devkit-browser-ralphex`). Skills cite sections here; do not duplicate these rules in skill bodies.

## 1. Scope

1.1. Input is always a scope: a feature name, a route/page set, or `whole project`.

1.2. Discover routes, roles, entities, and credentials from the codebase — never hardcode project-specific names or secrets.

1.3. Apply `plugins/core/conduct/inputs-grounding-gate.md` before mapping the QA surface.

## 2. Preflight

2.1. Snapshot the Chrome profile directories per §2.8 **first** — the reachability call below launches Chrome. Then verify chrome-devtools MCP is reachable (`list_pages`), and immediately take the §2.8 delta.

2.2. Verify the dev server is up; discover base URL from env, README, or project config. If it is not up, start only the minimal required local server(s) using existing project/dev-runtime commands, wait for a real HTTP readiness signal, and record exactly what this QA pass started. During cleanup, stop only those recorded processes/sessions; if the environment was already running (for example on the user's Mac), leave it running.

2.3. Verify DB or test-DB access and at least one usable seeder/factory path.

2.4. When the user attaches Figma URLs, verify Figma MCP is available before starting.

2.5. Missing prerequisite → stop via `plugins/core/conduct/clarification-protocol.md`. Never test against an unverified environment.

2.6. Do not use Playwright as a second browser layer for devkit QA. The browser authority is chrome-devtools MCP; lifecycle helpers are limited to starting/stopping local dev servers.

2.7. chrome-devtools MCP: per-project `.cursor/mcp.json` (from `devkit-install --cursor`) overrides global `~/.cursor/mcp.json` and uses an isolated profile at `.cursor/chrome-profile/`. Projects without local config fall back to the global entry.

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

## 4. QA surface map

Discover everything below from the codebase before testing or planning.

4.1. **Routes/pages** in scope — protected and public/unauthenticated.

4.2. **Roles**, including unauthenticated visitor, and how to authenticate each.

4.3. **Entity types** exposed by the project (models/routes/forms). Per entity: full lifecycle (create → read → update → delete) plus state transitions.

4.4. **Forms, fields, validation rules** per entity.

4.5. **Permission matrix**: each role × each entity/resource type.

4.6. **Viewport breakpoints** — from project CSS/Tailwind config or `visual/config.json`; fall back to `plugins/frontend/conduct/visual-implementation.md` defaults (mobile 390×844, tablet 768×1024, desktop 1440×1200).

4.7. **Regression surface** — adjacent behaviour reachable from in-scope navigation; discover from routing, not from memory.

## 5. Scenario matrix

Full coverage requires all dimensions below. Neither skill may skip a dimension to save time.

5.1. **Unauthed protected routes** — `navigate_page`; assert redirect/403.

5.2. **Unauthed public routes** — load anonymously; probe IDOR, exposed data, missing auth on actions/links, reflected input.

5.3. **Per role** — login via real form (`navigate_page` → `fill_form` → submit → `wait_for`).

5.4. **Per page × viewport** — `resize_page`/`emulate`; `take_snapshot` + `take_screenshot`; check adaptive layout.

5.5. **Entity lifecycle** — create/read/update/delete + state transitions (`fill_form`, `click`, `handle_dialog`).

5.6. **Field/validation** — invalid and boundary values; assert inline errors and blocked submits.

5.7. **Interaction depth** — varied value sets (empty, min, max, special chars, each enum/option, dependent-field combinations); every toggle, filter, sort, pagination, search, modal, tab, drag/reorder.

5.8. **Cross-role access propagation** — grant then revoke access per controllable section/feature/instance; re-login as affected user; verify UI visibility and route-level block in both directions.

5.9. **Permission matrix** — each role × each resource: access granted/denied correctly.

5.10. **Regression** — re-test adjacent happy paths discovered in §4.7.

5.11. **Console/network** — `list_console_messages` + `list_network_requests` after substantive actions.

5.12. **Figma** (when URLs provided) — `get_design_context` or `get_screenshot`; compare layout, spacing, typography, colors, component presence against live page; report deltas, never silently fix CSS.

## 6. Browser session

6.1. Start from the browser tab already open when one exists; do not navigate away unless the scope requires it.

6.2. `take_snapshot` before acting on each page.

6.3. `take_screenshot` on every finding and at least once per page × viewport.

## 7. Finding format

7.1. One finding per defect. Required fields: ID · route/page · role · viewport · severity · reproduction steps (MCP actions) · expected · actual · screenshot reference · console/network evidence.

7.2. Severity: `blocking` | `major` | `minor` | `cosmetic`.

7.3. Findings must be explicit enough for another session to fix with zero extra context.

## 8. MCP tools

**chrome-devtools:** `navigate_page`, `new_page`, `list_pages`, `select_page`, `click`, `fill`, `fill_form`, `hover`, `press_key`, `type_text`, `take_snapshot`, `take_screenshot`, `resize_page`, `emulate`, `evaluate_script`, `wait_for`, `handle_dialog`, `list_console_messages`, `list_network_requests`, `upload_file`, `drag`.

**Figma** (when URLs attached): `get_design_context`, `get_screenshot`. Read each tool schema before first use.

## 9. Hard rules

9.1. QA only — report findings; never fix code.

9.2. Project-agnostic — discover entity, role, route, and feature names from inputs only.

9.3. No `TBD` in outputs that block execution.

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

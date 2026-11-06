---
name: devkit-migrate
description: >-
  move production between prepared hosts/providers. Use for “migrate production”, “switch S3 then DB”,
  “перенеси прод”, or “переезд продакшена”. Executes data and traffic cutover; docker-deploy owns
  infrastructure setup and deployment audits.
---

# Production Migration

**Data copied → quick manual destination check → quick switch → copy leftovers and check afterward.**
Use existing commands and configuration. Do not turn the move into a tooling or audit project.

## 1. Reuse the prepared environment

- Read the current handoff and identify the source, target, approved code/env, live writer and worker owner once.
- Continue from completed work. Preserve prepared infrastructure, existing storage layout, keys, privacy and domains.
- Preserve application identity, login/session keys and host-dependent cookie/callback settings through the existing env.
  Use the real production hostnames and legacy cookie domains, not assumptions copied from staging. If encryption keys
  differ, use the existing protected decrypt/rewrap path for copied secrets; never replace a shared application's key.
- Install the repo/artifact and protected env through the existing deployment path if not already done. Keep target
  workers, scheduler and other side effects off until ownership switches; keep source production serving.
- Distinguish moving an unchanged deployment from merging a school into a shared application. Use the existing scoped
  importer for consolidation; never restore a standalone dump over other tenants. Fix only a concrete incompatibility
  that prevents the existing application from using the target.
- Reuse the owner's migration authorization and availability preference. Preparation alone does not authorize live
  cutover, data loss or destructive cleanup. Route actual missing infrastructure to devkit-docker-deploy only as needed.

## 2. Copy while production stays live

- Start bulk S3 and consistent DB copies promptly using existing native tools, backup/restore commands or the project's
  importer. Transfer server-to-server; run independent copies concurrently when resources allow.
- Reuse the committed copy and existing job receipts. Retry failed items only; do not restart successful copies or add
  full inventories, repeated parity scans, new schemas or application redesigns.
- Prepare target serving configuration before any live storage flip. Object copy does not copy bucket CORS. Merge
  actual serving production origins into the target's existing CORS policy without dropping other tenants' origins or
  making private files public. Do this while the source still serves, alongside the copy.
- Prepare the short sequence of existing switch and recovery commands while copying. Do not wait for the copy to finish
  before discovering how to connect to the target or switch writers.
  Give each command its own input: a capture/container command must not consume the remaining outer SSH script. Use
  noninteractive invocation or explicit input redirection where no input is needed. Match helper assumptions to the
  actual destination tenant, including an already-active school; do not deactivate it to satisfy a staging-only check.
- Resolve the actual app/CLI config and runtime user once while live, using the existing command's read-only path.
  Fix a concrete connection, permission or missing-class error before pausing; do not build a separate validator.
- Keep required local uploads, sessions and durable queue state available through the project's existing mechanism.
  Rebuild ordinary caches afterward; do not replay jobs twice or blindly replace a live shared Redis instance.

## 3. One quick manual destination check, then switch

- Manually confirm the application can connect to the intended target and read representative copied data. Check a
  known file through its intended access path. Reuse recent results; fix an observed failure, not hypothetical risks.
- Use a real JavaScript-enabled browser for this quick check. Open an existing destination preview/direct route and
  confirm the application renders, using the intended public origin where existing routing supports it. Check changed
  cross-origin theme modules/styles/fonts from the still-live production origin; another preview origin cannot prove
  production CORS. Curl, HTML 200 and Inertia JSON do not exercise the frontend. If preview is unavailable, keep the
  target connection/file checks and production-origin asset check; do not build a browser harness or full QA matrix.
- If a deployment lock already exists, hold it across this quick check and switch so another release cannot change
  the runtime between them. Release it afterward; do not build a new lock or coordination system.
- Resolve current service/container addresses through existing deployment commands. A replaced container ID or stale
  receipt binding does not invalidate copied data. Refresh only the changed reference; do not recopy or redeploy merely
  to satisfy custom proofs. Deploy a different revision only for an observed compatibility failure or approved release.
- Once this check passes, switch. Do not add a rehearsal, benchmark, broad audit, independent review or another capture
  as a new gate. Run mandatory release checks once only when actual code/config changes require them.

### S3 first

- Change the existing storage config for all serving web/worker/scheduler roles and reload through the existing path.
  Preserve object keys, metadata and privacy. Keep original buckets intact.
- Reload the actual public-origin page in the same browser immediately after switching. Confirm the theme loads and
  the app renders before proceeding; a readable logo or server-side file request does not establish frontend access.
  Repair an observed serving-config failure immediately, before tails or unrelated work.
- Run the existing incremental copy after switching to collect remaining objects, late old-config uploads and in-flight
  presigned/multipart completions. Use existing receipts to avoid overwriting newer target data or resurrecting target
  deletes/renames; skip and report ambiguous conflicts rather than inventing a tracking system.
- Do not build read fallbacks, dual writes, routing abstractions or new storage helpers. If already installed, leave them
  alone; their removal or refinement is not a cutover prerequisite. Continue the independent file tail after DB cutover.

### Database and workers second

- Let long-running scheduler/worker jobs drain while the source site stays available, using existing controls to
  prevent new starts and preserve queued work. Do not gate users first and then wait for those jobs to finish.
  Stop new scheduling without freezing the child jobs expected to finish; a suspended process cannot drain.
- Keep one authoritative writer. Briefly drain/fence old writers when needed, apply the small essential last-write
  handoff through the existing mechanism, switch connections/runtime, and enable one target worker/scheduler owner.
- **Take the final delta once and switch immediately.** “Свежую дельту можно снимать бесконечно. Один раз переключи,
  потом хоть обсверяйся.” Reuse the initial import; do not rewrite unchanged rows or fully reconcile the graph again.
  A new capture is needed only if the prior one failed or source writes resumed.
- Copy supported leftovers and run full checks after reopening. Bring required payments, orders, access grants and
  dependencies across before serving affected writes; do not blindly apply old source rows over new target writes.
  Use native replication/change receipts or the existing scoped importer; timestamps and maximum IDs alone miss
  updates/deletes. If the existing path replays the whole import, keep source live and state that concrete limitation
  before pausing. Do not disguise a full replay as a small delta or invent a new migration framework to avoid saying so.
- Repoint the old application only if it is compatible with the target schema and tenant model. Otherwise use the
  already prepared runtime/ingress switch; never attach an incompatible standalone app to a shared tenant database.

### Domains last

- Change only the intended DNS/ingress records after target data and runtime are usable. Keep old ingress serving or
  forwarding to the current runtime through propagation. Retain source data and recovery copies for the retention window;
  destructive deletion requires its own authorization.
- Preserve redirect-only aliases as redirects. Keep them out of backend peer-route probes that expect an application
  response; an intended redirect is not a failed backend. Use the existing canonical route for that probe.

## Keep the cutover simple and brief

- Do not write custom controllers, carrier frameworks, sealed proof packets, timing manifests, validators or a general
  migration system for this task. Use native/existing tools and ordinary command output. A short shell sequence is enough;
  no new application behavior or test framework is required for an unchanged deployment move.
- Honor an explicitly agreed interruption limit using existing operational controls. Do not invent a five-second default,
  optimize artificial per-phase allocations, or build tooling to prove a synthetic budget. If the owner changes the
  approach, do not keep superseded restrictions as blockers. Do not infer permission for an unbounded outage.
- Treat an estimated pause as an estimate, not an automatic rollback deadline. Recover on an actual command failure
  or the owner's still-current hard limit; do not restore merely because an invented phase allowance expired.
- Count the whole interruption from first impaired access to restored normal use, including failures and recovery.
  Stop the clock only after the affected public-origin browser path works, with the frontend loaded and normal signed-in
  access restored. Route-open time is a separate milestone, not the outage end. Report observed times and uncertainty;
  never backdate recovery from an HTTP 200 or restart the clock to hide an overrun.
- If the switch fails before promotion, stop target mutators and confirm source authority before restoring source service.
  After target promotion or live writes, keep target authoritative and recover forward; do not resume a stale source.
- Restore access before debugging or preparing another attempt. During a pause, do only the switch or necessary recovery;
  no optional checks, branding work, unrelated tasks or new tooling. Make only the recovery repair needed if recovery fails.
- Treat an owner report of unavailable access as an incident immediately, even when HTTP probes pass. Open the affected
  URL in the browser and inspect its actual error and failed asset requests before calling it available. Prioritize the
  existing serving-config/routing repair over optional fixes, retirement and unrelated CI; retain required release checks
  for code repairs. After promotion, restore the target's access forward rather than waiting on unrelated deployments.
- Keep one cutover operator. Delegate independent transfers or post-switch work, not a serial chain of readiness reviews.
  If stopped on a real blocker, name the failing command and smallest remedy; do not keep saying “almost ready”.
- Execute the next existing command once its prerequisites pass. After a failed attempt, repair its concrete cause
  with access restored; repeat only the affected step. After two failures on the same assumption, change the method
  or report the exact missing capability. Do not loop through capture → timeout → recovery with unchanged inputs.

## Finish

- After switching, use the actual public-origin browser to sign in with authorized test data and open the expected
  cabinet/course, then confirm the required reversible write and single worker owner. Include existing legacy-cookie
  behavior when relevant; do not hide a returning-user failure by clearing cookies. A generic error screen is a failed
  check even if the login POST, JSON component name and page response all passed.
  Keep any observed broken cabinet/profile route open as an access defect even if another page works; an optional
  widget failing the whole page is not merely a probe mismatch. Report partial access accurately and repair forward.
  Copy remaining files/data and do broader audits while the service works; repeat a check only for an observed failure.
- Inspect the current page after a navigation-related browser-tool error. Confirm the actual login/course result before
  calling authentication broken. When normal access works but a custom probe disagrees, diagnose that probe afterward;
  do not recapture, roll back, reset customer passwords or weaken authentication to make the probe pass.
- Finish once the target is authoritative, routes are open, the public-origin browser check passes and the target worker
  owner is active. If browser access is unverified, say so; do not substitute HTTP receipts for a completion result.
  Report optional tails separately; do not keep the migration open for proof formatting, probe cleanup or broad audits.
- When supervising, stay through that result or a genuine owner decision. A started switch, a skill deployment or
  another agent's “ready” report does not finish supervision. Relay changed owner constraints to the cutover operator.
- Report the active runtime/DB/storage, remaining tail, actual interruption, retained source and next action. State any
  unavailable source or recovery gap explicitly; never claim recovered data beyond the available checkpoint.

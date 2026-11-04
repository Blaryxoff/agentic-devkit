---
name: devkit-migrate
description: >-
  move production between prepared hosts/providers. Use for “migrate production”, “switch S3 then DB”,
  “перенеси прод”, or “переезд продакшена”. Executes data and traffic cutover; docker-deploy owns
  infrastructure setup and deployment audits.
---

# Production Migration

Execute this order: **repo/code/env → bulk S3 and DB copies → S3 catch-up and switch → DB catch-up and switch
→ domains → retire the old runtime after propagation**. Continue from the last proven stage.

## 1. Establish the migration boundary once

- Read the project's migration handoff, deployment entry point and current source/target configuration first.
- Reuse prepared infrastructure and yesterday's evidence; recheck only expired or changed facts needed for the next action.
- Record source and target, code/image revision, env source, storage mapping, DB engine/version, traffic route,
  worker/scheduler owner, and required availability in one short stage ledger.
- Define availability through normal signed-in reads, login and required writes. A public page or branded login HTML
  returning 200 does not establish working service when course access, purchases or progress updates are disabled.
- Preserve existing keys, file paths, bucket privacy, application identity, branding and integration behavior.
- Distinguish a host/provider move from application consolidation, schema conversion or a bucket redesign. If required,
  name the exact compatibility work and its time cost before proceeding; keep optional redesign outside the migration.
- Resolve missing cutover authorization and availability requirements early. Reuse explicit authorization already given;
  preparation alone does not authorize switching live writers or domains.
- For unavailable sources or backups, state the last recoverable checkpoint and data-loss boundary. Obtain approval for
  any loss before promotion; use the reachable authoritative source rather than waiting indefinitely for an old provider.
- Load `devkit-docker-deploy` only for a concrete missing infrastructure prerequisite. Return here when it is resolved;
  do not turn a prepared-host move into a full deployment audit.

## 2. Install repo, code and env

- Deploy the approved revision using existing release tooling; reuse a matching built artifact.
- Install secrets through the project's protected env mechanism. Preserve source keys and integration credentials unless
  the target requires an authorized replacement; never print secrets.
- Map hostname-dependent app URLs, session/cookie settings, callbacks, realtime endpoints and health probes together.
  Deploy the matching configuration before activating a new hostname; preserve working authentication during overlap.
- Start target web services isolated from live writes and external side effects. Keep target workers and scheduler off.
- Check target resources, storage quota, DB compatibility, network access from actual app containers, and required
  integration IP allowlists once. Repair only failures that block this migration.
- Probe dependencies from the actual target runtime over their real protocol. An HTTP egress check does not establish
  SSH/UDP connectivity or the source IP seen by an allowlisted service; verify changed egress before removing old paths.
- Confirm target readiness through its direct route with the production Host/TLS name. Keep source traffic running.

## 3. Start bulk copies immediately

- Copy S3 objects and take a consistent DB snapshot while source production continues serving traffic. Run independent
  transfers concurrently only when source/target capacity permits; perform transfers server-to-server.
- Use existing copy tools and durable jobs with progress logs. Record checkpoint, bytes/objects, failures and throughput;
  estimate remaining time from observed progress instead of repeatedly restarting copies or listing whole stores.
- Assemble the runnable fence → final capture → apply → activate → route → reopen command while the bulk copy runs.
  Prove its source-DB read path works independently of source web/workers with a bounded read-only probe, not another
  capture. Reuse the existing operator path; do not start building a new carrier after the initial copy passes.
- Call the switch ready only when that command is runnable. If command assembly still blocks it, name the missing
  executable step and resolve only that step; do not call another capture or readiness audit “the remaining step”.
- Preserve S3 object keys, metadata, content types and private/public access behavior. Keep source data intact; obtain
  explicit authorization for destructive mirroring or target replacement.
- Restore the DB into the isolated target; keep its previous recoverable state. Prefer the engine's existing hot-backup,
  replication or incremental tooling for a large live database. Use a logical restore when it fits capacity and timing.
- Establish how post-snapshot inserts, updates and deletes reach the target before calling the base copy ready.
  Copying rows by timestamp or maximum ID is not a general DB catch-up mechanism.
- For tenant consolidation, use the existing scoped importer rather than restoring over a shared database. Prove tenant
  mapping, ID/unique-key collision handling, timezone normalization, idempotency and lock scope on an isolated copy;
  preserve unrelated tenants and keep callbacks on a compatible route throughout the switch.
- Copy required local uploads, sessions, queues or Redis state using the project's semantics. Identify authoritative
  durable data separately from rebuildable caches; avoid a blind Redis replacement or replaying jobs twice.
- Retry failed items from their manifest. Keep historical recovery/backfill running independently when live requests
  do not depend on it; report the incomplete range and fallback rather than gating the whole move on optional recovery.
- If a restore fails, inspect its concrete error and resource usage before retrying. After two failures on the same
  assumption, change the method or report the specific blocker; stop repeating full imports with speculative tuning.

## 4. Catch up S3 and switch storage first

- Run an incremental copy while the source remains active; include changed objects and reconcile deletions under the
  agreed retention policy. Keep the initial-copy manifest as the baseline.
- Establish one storage write destination across web, workers, scheduler and background jobs. Use an existing upload
  fence, dual-write/catch-up protocol, or drain old-config writers before the final pass. A scan of a changing bucket is
  not a final checkpoint.
- Account for issued presigned uploads and in-progress multipart uploads when the app uses them. Drain/reconcile their
  completions or retain catch-up and read fallback through their expiry; switching server env does not stop client writes.
- Apply the remaining delta and switch all serving runtimes to target storage through the existing graceful reload path.
  Keep old storage readable or use an existing fallback until outstanding old-source objects are reconciled.
- Prevent a stale copy from overwriting newer target objects; account for in-flight overwrites and deletes explicitly.
- Verify the final manifest has no unexplained misses, one existing public/private read behaves correctly, and a
  disposable upload reaches target storage. Remove only the probe object created by this run.
- Record storage as switched and advance to DB. Reopen storage checks only for a new failure or changed dependency.

## 5. Catch up DB and switch connections second

- Keep old web production serving. Prepare a private target-DB connection from every runtime that will remain live,
  including the old host; test it before switching traffic or freezing writers.
- Bring the target DB close to current through the prepared catch-up path: native replication/incrementals for compatible
  databases, or the proven scoped importer/change log for consolidation. Keep schema and app revision compatible;
  a host migration does not authorize unrelated application migrations.
- **Take the final delta once, switch immediately, then verify.** Treat “Свежую дельту можно снимать бесконечно.
  Один раз переключи, потом хоть обсверяйся” as the execution rule: fence source writers, capture/apply the final
  committed delta, then promote the target and repoint connections in the same bounded handoff. Do not insert another
  snapshot, freshness refresh, broad comparison or optional probe between that delta and the switch. Run those checks
  after target writes reopen; their failure is not an automatic reason to restore source authority.
- Capture another final delta only if source writes actually resumed or the prior capture failed or became unusable.
  Record that cause instead of repeating catch-up merely because time passed or another check was added.
- Reuse the committed consolidation import and its mappings/checksums; mutate only changed/new rows and supported
  deletions during catch-up. Rewriting unchanged rows and fully reconciling the entire graph is a replay, not a small
  delta. If that is the only implemented path, state its measured outage cost before fencing; keep the source live
  while preparing the minimal delta path or obtaining the owner's acceptance of that maintenance window.
- Apply business-critical changes and referenced records before enabling target writers/workers. Backfill optional
  history/media and run full audits afterward; reconcile late source data against new target writes without overwriting
  them or duplicating payments, orders or access grants.
- Define the last-write boundary, measured final-delta duration, maximum request wait, abort condition and recovery
  action before the switch. Complete bulk transfer, restore and broad validation before entering this boundary.
- Separate cutover-critical dependencies from optional diagnostics before fencing writers. Probe the critical paths
  before the hold; defer auxiliary read-only accounts, analytics and backfill unless the release contract requires them.
- Track the write-pause start and budget explicitly. While writes are paused, prioritize final reconciliation and
  reopening the authoritative target; defer checks that can safely follow activation. If the budget expires before
  target live writes, take the established abort path. After target live writes, preserve target authority and recover
  forward rather than reopening a stale source. Report a prolonged pause immediately with the failing step and recovery.
- Preserve one authoritative writable DB. Drain/fence every source writer, including workers, scheduler, webhooks and
  long-lived connections; apply the final committed changes and verify the native position/checkpoint is caught up.
- Keep HTTP ingress available. Use an existing bounded request hold/drain only if it fits the authorized availability
  contract; do not claim zero downtime when requests can fail or exceed their deadlines. If the available method
  requires an unapproved outage, state the exact limitation and seek the decision before starting it.
- Point compatible old and new app runtimes at the target DB, refresh connection pools, and reopen writes on the target.
  For consolidation, prove old-runtime schema and tenant compatibility first; otherwise proxy old HTTP ingress to the
  new compatible runtime. Never connect an incompatible standalone app directly to a shared tenant database.
- Transfer worker/scheduler ownership at the DB switch and drain/disable the old owner then; keep HTTP ingress available
  independently. Never run duplicate consumers against independent databases.
- Verify one representative read and one authorized reversible write through each serving ingress, plus the active
  worker owner. Use designated test data; do not alter customer records for a probe.
- Treat the first authoritative live application write after target promotion as the rollback boundary. Restore,
  replication and isolated probe writes do not cross it. Before it, source can resume after the target is fenced;
  afterward, preserve target authority and repair forward or reconcile changes before any DB failback. Never resume a
  stale source DB or overwrite a target that has accepted live writes.

## 6. Switch domains last and retain old ingress

- Change DNS/load-balancer routes only after both serving paths use target S3 and the same current target DB.
- Use the verified service-to-domain mapping for record changes. A shared old IP alone does not establish ownership;
  preserve unrelated services, landing pages, wildcard records and non-HTTP routes outside the authorized scope.
- Keep the old IP serving with target dependencies or proxying to the new web runtime through DNS propagation.
- Verify one end-to-end path through the public domain and each still-serving IP; check new errors and worker health.
- Observe propagation against the recorded TTL and old-ingress traffic. Keep the old ingress available for clients
  still reaching it; retire old web ingress only after the agreed drain criterion and existing authorization permit it.
- Retain old DB/storage and recovery artifacts for the project's retention window. Request separate approval before
  destructive cleanup; report DNS switched and old ingress retained separately from full retirement.

## Keep execution bounded

- Attach each check to a stage exit criterion, a command and a pass/fail consequence. Once it passes, advance.
- Reuse unchanged results. Repeat a check only after its inputs changed, a failure, or expiry relevant to the switch.
- Check transfer progress from its existing job at a cadence justified by its ETA; stay available for user input.
- After 10 minutes of preparation/checking without a stage advance or measurable transfer progress, state the exact
  blocker, time spent and next action. Continue safe independent stages while an external approval is pending.
- Prefer existing operational commands. Add only missing migration-critical glue; keep the switch sequence short and
  reviewable instead of building a general migration framework during the move.
- Delegate only independent bounded work with a clear output and available executor. If an agent has not started,
  reclaim the critical-path action instead of layering more waiting agents or serial peer reviews onto it.
- Run mandatory project release checks once for the actual code/config revision. Use focused checks for migration glue;
  do not repeatedly rebuild, run full suites, audit unrelated subsystems or repair unrelated CI during data movement.
- Verify config with isolated paths and the correct runtime user. A validation command that changes permissions,
  caches, mounts or process ownership is a production mutation; inspect its effect before using it on the serving host.

## Report progress and completion

Keep one ledger: `stage | source/target authority | checkpoint/evidence | elapsed | next action/blocker`.
Report transfer time, external waiting, compatibility fixes and repeated work separately; elapsed time is not active
engineering time. At handoff include switched dependencies, serving ingress, worker owner, remaining backfill,
rollback boundary and retained resources. Declare completion only for stages whose observable exit criteria passed.

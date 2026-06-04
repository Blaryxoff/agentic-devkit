---
name: devkit-docker-deploy
description: bootstrap or audit a project's Docker / docker-compose production deployment against the org's docker-deployment conduct. Single-node prod+test is the default shape (Laravel + optional Nuxt + mysql + redis); multi-node fleets are an opt-in appendix. Use when starting a new dockerized service, hardening an existing one, or reviewing the docker setup of an existing project.
---

# Docker Deployment — Setup & Audit

> Paths like `plugins/<plugin>/conduct/…` resolve under the devkit clone root (`~/.claude/agentic-devkit` — this skill's symlink target), not the project root.

You are acting as a **deployment engineer** working against
[`plugins/core/conduct/docker-deployment.md`](../../conduct/docker-deployment.md).
That document is the source of truth — read it before doing anything else.

**Baseline assumption: single-node, two-environment (prod + test).**
Multi-node / LB / brand-multiplexed setups are §14 of the conduct, an
opt-in appendix. Don't push fleet machinery into a single-node project.

## Modes

Pick one. If unclear, ask once and proceed.

- **`setup`** — no Docker deploy yet (or a stub); scaffold one.
- **`audit`** — Docker deploy exists; review and report findings, don't
  apply changes.
- **`harden`** — Docker deploy exists; apply prioritised changes.

State the mode in your first reply.

## Grounding (do first, regardless of mode)

1. Read `plugins/core/conduct/docker-deployment.md` once, in full. Cite
   section numbers in your findings.
2. Read the project's existing surface (whichever exist):
   - `Dockerfile*`, `docker/`, `docker-compose*.y*ml`, `compose*.y*ml`
   - `bin/deploy*.sh`, `Makefile`
   - `.github/workflows/{deploy-*,build-images,ci}.y*ml`
   - `docker/INFRASTRUCTURE.md` or `INFRASTRUCTURE.md`
   - `config/backup.php`, `routes/console.php` (Laravel backup schedule)
   - `.env.example`, `.env.frontend.example`
3. Determine the **shape**: single-node single-app (default), single-node
   with multiple envs on one VM (still default), or multi-node behind LB
   (opt into §14). Most projects are the first or second.
4. Determine the **stack**: Laravel API only, or Laravel + Nuxt SSR via
   Inertia or as separate apps, or other. The Makefile shape and
   container set follow.
5. If anything material is ambiguous, resolve once via
   [`clarification-protocol`](../../conduct/clarification-protocol.md).
   Don't open 12 questions.

## The single-node checklist

The audit + harden modes walk this. The setup mode produces it as the
output structure. Cite the conduct section for every item.

### A. Image build (§1)

- A1. Multi-stage Dockerfile: node-assets → composer-vendor → fpm runtime
      → nginx stage that `COPY --from=runtime /var/www/html/public …`.
- A2. PHP extensions installed via `mlocati/docker-php-extension-installer`.
- A3. Non-root `www` user with `uid=1000` in **every** image including
      nginx (so the shared `app-logs` volume has consistent ownership).
- A4. `public/build/` baked into the nginx image — never shared via a
      volume.
- A5. Image tags: `${env}-${sha}` immutable + `${env}-latest` rolling.
      Registry hardcoded lowercase (`ghcr.io/<lowercase-owner>`).
- A6. Base images pinned (`php:8.4-fpm-alpine`, not `latest`).
- A7. Runtime stage strips dev-only files; no `.env` copied into image.
- A8. Asset stage sets `NODE_OPTIONS=--max-old-space-size=…`; test builds
      gate minify off via build-arg; build stage uses `node:<LTS>-slim`. (§1.8)
- A9. **Build-host swap.** If the deploy path builds the image **on the
      serving node** (e.g. `bin/deploy.sh` / `bin/gp.sh` runs `docker build`
      / `buildx build` on the same host it deploys to), that host MUST have
      swap, or the Vite heap spike can freeze a memory-oversubscribed box
      (§1.8). This is host state, not a repo file — **verify it live**:
      `ssh <build-host> 'swapon --show; free -h'`. Empty `swapon` output on a
      build-on-serving node is a **critical** finding. Recommend a persistent
      `/swapfile` (fstab + `vm.swappiness=10`) sized to overcommit-gap + build
      heap, or moving the build off-box.

### B. Volumes (§2)

- B1. Every mount is a **leaf** path (`storage/app/public`,
      `storage/app/private`, `storage/logs`, `database/data` for sqlite).
      Never the parent.
- B2. nginx mounts `app-public` read-only and serves `/storage/` from it.
- B3. No host bind mounts to source paths in production.

### C. Logging (§3)

- C1. `app-logs` named volume mounted in app + worker + scheduler + nginx
      at `/var/www/html/storage/logs`.
- C2. PHP, PHP-FPM, nginx all `error_log` into that path; Laravel's
      default `storage/logs/laravel.log` lands there too. A single
      log-viewer can read everything.
- C3. Per-service `logging:` with `max-size` + `max-file` (50m × 5 for
      app services, 20m × 3 for redis/mysql).
- C4. Deploy script captures `docker logs --tail=120` into
      `storage/logs/container/` on healthcheck failure.

### D. Networking (§4)

- D1. Host port bindings on `127.0.0.1` for everything except the host
      reverse proxy (mysql/redis never on `0.0.0.0`).
- D2. If sharing infra (e.g. one redis instance across tenants): host-level
      network declared `external: true`; `REDIS_HOST` pinned in service
      `environment:` (overrides any stray `.env`); keys namespaced.
- D3. (Cloud only) IMDS (`169.254.169.254`) blocked from containers by a
      persistent systemd unit.

### E. Environment (§5)

- E1. `.env*` gitignored; only `.env.example` checked in.
- E2. Deploy script sources `$ENV_FILE` into its shell before
      `compose up` on any stateful service whose `environment:` block
      references `${MYSQL_ROOT_PASSWORD}` / `${DB_PASSWORD}` / etc.
      Otherwise mysql initialises with empty creds on first deploy and
      you have to drop the volume.
- E3. Makefile's `compose_body` macro sources both
      `.deploy/compose.env` (image refs + ports + hosts written by
      `bin/deploy.sh`) and `.env` (Laravel creds), so ad-hoc compose
      commands resolve substitution the same way.
- E4. `env_file:` is documented as start-frozen;
      `make reload-env-{test,prod}` exists.

### F. Healthchecks (§6)

- F1. Every service has a `healthcheck:`.
- F2. FPM image has `apk add --no-cache fcgi`; FPM healthcheck uses
      `cgi-fcgi -bind -connect 127.0.0.1:9000` against `ping.path=/ping`,
      or a plain TCP probe.
- F3. `start_period` is set (90s for FPM, 15–30s for SSR).
- F4. `depends_on: { ...: { condition: service_healthy } }` for anything
      that calls into the dependency at boot; one-shot migrate uses
      `service_completed_successfully`.
- F5. Laravel `/up` (and `/healthz` if used) is wired and verified.

### G. Deploy script as single source of truth (§7)

- G1. `bin/deploy.sh` is the **only** place deploy logic lives. Makefile
      and workflows are thin wrappers that call it. No `docker compose`
      lines in workflow YAML, no deploy logic in Makefile recipes.
- G2. Two-account host model: `user` (interactive, sudo, file ownership)
      for Makefile ops; `deploy` (CI-only, docker group, no sudo) for
      workflows.
- G3. Script algorithm: flock → pull images → diff against
      `.deploy/<image>.digest` → exit 0 if unchanged → source env →
      stateful deps up + wait healthy → pre-flight migrate one-shot →
      compose up → wait healthy → persist digests → write
      `.deploy/compose.env` → `queue:restart` if backend moved.
- G4. Pre-flight migrate runs as `docker run --rm` against the **new**
      image before recreating live containers. Failure aborts with old
      containers still serving.
- G5. `FORCE_RECREATE=true` is the explicit override.
- G6. Rollback recipe documented (re-tag previous immutable sha as
      `latest`, wipe digests, redeploy with force).

### H. Makefile — canonical commands (§7.5)

The contract (commands + semantics) is what matters. Verify all are
present and behave as documented.

- H0. **`-test` / `-prod` is always the suffix** for env-bound recipes.
      No `env=…` parameter, no prefixed or mid-name env tokens. Each
      env-bound recipe is a separate target ending in `-test` or `-prod`;
      share bodies via a pattern rule or macro.
- H1. Deploy: `make deploy-test`, `make deploy-prod`,
      `make deploy-force-test`, `make deploy-force-prod`,
      `make build-images`. Each is one line:
      `gh workflow run … [-f force_recreate=true]`.
- H2. Env: `make reload-env-{test,prod}`,
      `make sync-env-{test,prod} from=…`,
      `make render-compose-{test,prod}`.
- H3. Smoke (local curl, no SSH): `make smoke-test`, `make smoke-prod`.
- H4. Inspect: `make ps-{test,prod}`,
      `make logs-{test,prod} [service=…] [tail=…]`, per-service
      `logs-backend-{test,prod} / logs-frontend-{test,prod} /
      logs-nginx-{test,prod} / logs-worker-{test,prod} /
      logs-scheduler-{test,prod}`.
- H5. Container: `make shell-{test,prod}`, `make tinker-{test,prod}`,
      `make artisan-{test,prod} cmd='about'`, `make migrate-{test,prod}`,
      `make queue-restart-{test,prod}`, `make db-shell-{test,prod}`,
      `make redis-shell-{test,prod}`, `make wait-healthy-{test,prod}`.
- H6. Quality: `make pint`, `make pint-fix` (Laravel) — not env-bound, no
      suffix.
- H7. Mechanics: hosts resolved per target (`-prod` → `APP_PROD_HOST`,
      `-test` → `APP_TEST_HOST`), each overridable in shell rc; SSH
      identity pinned to `~/.ssh/<app>_deploy`; `-t` for log streaming,
      `-tt` for `shell-*` / `tinker-*` / `db-shell-*`; `compose_body`
      sources both env files (§E3).
- H8. **No `docker compose restart` recipe anywhere**.

### I. Workflows — thin SSH orchestrators (§7.6, §7.7)

- I1. `deploy-test.yml` + `deploy-prod.yml` exist; both
      `workflow_dispatch` only (prod), or dispatch + auto-trigger from
      `build-images` for test.
- I2. Each workflow does only: checkout → set up SSH key + known_hosts
      → `install -m … /dev/stdin` to ship `bin/deploy.sh` + `docker/compose.yml`
      → ssh + env-var passthrough + run script.
- I3. `concurrency: { group: deploy-<env>, cancel-in-progress: false }`.
- I4. `environment: <env>` (so protection rules apply).
- I5. `permissions: { contents: read, packages: read }`.
- I6. Registry namespace lowercased in the workflow (`tr '[:upper:]' '[:lower:]'`).
- I7. Secrets per env: `DEPLOY_<ENV>_SSH_PRIVATE_KEY`, `_SSH_USER`,
      `_HOST`, `_API_HOST`, `_FRONTEND_HOST`, optional `_HTTP_PORT`,
      `_GHCR_USERNAME`, `_GHCR_TOKEN` (fallback to `secrets.GITHUB_TOKEN`).
- I8. `build-images.yml` uses `dorny/paths-filter@v3`; **backend changes
      trigger nginx rebuild**; two tags per image; registry-mode cache;
      on dev-branch success optionally dispatches `deploy-test.yml`.

### J. TLS (§8)

- J1. Termination on the host (Caddy preferred for single-node), not in
      the app's nginx sidecar.
- J2. `/etc/caddy/Caddyfile` exists and is hand-edited (not shipped by
      deploy). Reload via `sudo systemctl reload caddy`.
- J3. Adding a host: A record at the DNS provider, then site block, then
      reload. Cert issued on first request.

### K. Resilience & security (§9)

- K1. `restart: unless-stopped` on every long-running service;
      `restart: "no"` only for one-shot migrate.
- K2. Memory / CPU limits set per service.
- K3. `read_only: true` where feasible (nginx, frontend), with `tmpfs:`
      for `/tmp`, `/var/run`, etc.
- K4. No docker.sock mounted into any container.

### L. Backups (§10)

- L1. `spatie/laravel-backup` (or equivalent) configured to S3.
- L2. Schedule **gated to `APP_ENV=production`** in `routes/console.php`.
- L3. Retention defined; bucket hard cap configured.
- L4. Restore drill documented and scheduled.

### M. INFRASTRUCTURE.md (§11)

- M1. `docker/INFRASTRUCTURE.md` exists.
- M2. Covers topology, source-of-truth table, primary vs fallback
      operator paths, layout, containers, deploy flow, rollback,
      env-only changes, TLS, backups, day-to-day commands, debug
      checklist, common failure modes, operational notes.

### Multi-node addendum (§14) — skip unless project is actually multi-node

Only add to the checklist if there's more than one app node. NLB drain,
asset-manifest gate, watchdog timer, smoke/drift/prune crons,
multi-node cert distribution, brand multiplexing.

## `setup` mode — workflow

For a brand-new dockerization:

1. Confirm the shape (single-node, two-env, Laravel + optional Nuxt) and
   the host (Selectel / Yandex / Hetzner / self-hosted) — one
   clarification round if needed.
2. Use `TaskCreate` to put the checklist sections (A–M) into a task list.
3. Generate files in this order so each layer compiles before the next:
   1. `docker/php/{php.ini,opcache.ini,php-fpm.conf}` with
      `error_log` pointing into `storage/logs` (C2).
   2. `docker/nginx/nginx.conf` + `docker/nginx/conf.d/default.conf` —
      user `www`, error/access log into `storage/logs`, FastCGI to
      `app:9000`, `/storage/` alias, security headers, gzip.
   3. `docker/scripts/entrypoint.sh` — role dispatcher (`app`, `queue`,
      `scheduler`, `migrate`).
   4. `Dockerfile` (and `Dockerfile.frontend` if Nuxt is separate) — A1–A7.
   5. `docker-compose.yml` — leaf-only volume mounts (B), shared
      `app-logs` (C1), healthchecks with `start_period` (F),
      `restart: unless-stopped` (K1), `logging:` caps (C3), host ports on
      `127.0.0.1` (D1), `external: true` for any shared network (D2).
   6. `bin/deploy.sh` — G3 algorithm. Write
      `.deploy/compose.env` at the end so the Makefile macros work.
   7. `Makefile` — all of §H. Keep it under ~250 lines.
   8. `.github/workflows/deploy-test.yml`, `deploy-prod.yml`,
      `build-images.yml` — §I. Thin wrappers, no logic.
   9. `docker/INFRASTRUCTURE.md` — §M.
   10. (Only if cloud / multi-node-curious) `bin/server-setup/` host
       scaffolding.
4. Hand the user a short "first-time host bootstrap" checklist:
   - Create the two accounts (`user`, `deploy`) and groups.
   - `mkdir -p /var/www/<app>/{bin,docker,.deploy}`, mode `2775`, group
     `<app>`.
   - `scp .env` into `/var/www/<app>/.env`, mode `0640`.
   - Install Caddy + initial `Caddyfile`.
   - Add DNS A records for the API and frontend hosts.
   - Configure GitHub repo secrets per §I7.
   - First `make build-images && make deploy-test` to confirm the loop.
5. Run [`devkit-verify`](../verify/SKILL.md) on the new files where
   applicable (shellcheck, yamllint, dockerfile lint).

## `audit` mode — workflow

1. Walk A–M against the project. For each item, classify
   ✅ ok / ⚠️ partial / ❌ missing.
2. For every ⚠️/❌, report:
   - **Where** — file path + line range.
   - **Why it matters** — cite the conduct section and the failure mode
     it produces (e.g. "named volume shadows fresh image content on every
     deploy" for non-leaf mounts; "mysql initialises with empty root
     password on first deploy" for missing `set -a; source $ENV_FILE`).
   - **Severity** — `critical` / `important` / `nit`.
3. Special focus areas — these are the most frequently broken on existing
   projects:
   - **G1** — deploy logic leaked into the workflow YAML or the Makefile.
   - **H** — Makefile present but not the full canonical command set, so
     operators reach for ad-hoc SSH + docker compose lines.
   - **A4 / §1.4** — public/build via a volume.
   - **E2** — first-deploy mysql with empty creds.
   - **B1** — non-leaf volume mount.
   - **C** — log fragmentation; nginx logs going to stdout while PHP logs
     go to `storage/logs`, so log-viewer only sees half the story.
   - **A9** — build-on-serving node with no swap. Detect it: grep the deploy
     path (`bin/deploy.sh`, `bin/gp.sh`, Makefile) for a `docker build` /
     `buildx build` that runs on the deploy host rather than CI; if found,
     `ssh <build-host> 'swapon --show'` and flag empty output as critical.
4. Group findings by severity, then by section. Don't reorder by file.
5. Use the format from
   [`review-findings-format`](../../conduct/review-findings-format.md).
6. End with "what I'd tackle first" (max 3 items) and offer to switch to
   `harden` mode.

## `harden` mode — workflow

1. Same checklist as audit; you may apply changes.
2. Order changes by **risk-first then leverage**:
   1. Data-loss / security gaps (containers reaching IMDS, secrets in
      image, mysql on `0.0.0.0`).
   2. Mount-safety (§B) and `public/build` shadowing (§A4) — silent until
      deploy day.
   3. Env handling (§E) and deploy-script correctness (§G).
   4. Operator-UX gaps in Makefile / workflow (§H, §I).
   5. Observability + TLS robustness (§J, plus §14.5–14.6 if multi-node).
   6. Cosmetic / nit items last.
3. For any change that affects running production, list the exact ops
   sequence and pause for confirmation before running it. Never silently
   reorder operator steps.
4. After each meaningful change, update `docker/INFRASTRUCTURE.md` so the
   operator map stays in sync.

## Reporting

End every invocation with:

1. **Summary** — 3–6 bullets of what changed (setup/harden) or what's
   broken (audit).
2. **Highest-leverage next step** — one sentence.
3. **Known gaps** — anything deferred, with the reason (e.g. "no off-host
   backup destination provisioned yet — deferred until S3 bucket exists").

## Boundaries

- Don't recommend multi-node patterns (§14) unless the project is
  actually multi-node. A single-node Laravel app does not need a watchdog
  timer, an LB drain loop, or a cert-distribute hook.
- Don't make architectural changes to a working non-canonical setup just
  because the canonical one is what the conduct documents. If a project
  uses (say) Cloudflare Tunnel instead of host Caddy, audit it for
  internal consistency rather than rewriting.
- Don't run destructive ops (`docker volume rm`, `docker compose down -v`,
  anything touching `/var/lib/docker/`) without explicit per-command
  confirmation. The
  [readiness-gate](../../conduct/readiness-gate.md) applies.
- Don't treat the conduct as complete. If you discover a real
  production-grade rule that isn't in it, **propose adding it** to
  `plugins/core/conduct/docker-deployment.md` rather than encoding it
  one-off in a project.

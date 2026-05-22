# Docker Deployment — Conduct

How dockerized projects in this org are built, deployed, and operated.

The **baseline is single-node, two-environment** (prod + test), with the test
env optionally on the same VM as prod. Most projects (Laravel API, optional
Nuxt SSR, mysql, redis) fit this shape.

The multi-node / load-balanced / brand-multiplexed shape is a separate
appendix at the bottom (§14). **Do not pull those rules into a single-node
setup** — they trade simplicity for resilience you don't need at one box.

Skill `devkit-docker-deploy` enforces this document when bootstrapping a new
stack or auditing an existing one.

---

## 1. Image build

### 1.1 Multi-stage builds

Laravel runtime image: three stages — **(a)** `node:*-alpine` builds Vite
assets, **(b)** `composer:2` resolves vendor + dumps optimized autoloader,
**(c)** `php:*-fpm-alpine` runtime copies vendor + built assets in via
`COPY --from=…`. A small fourth stage `FROM nginx:1.27-alpine` copies the
runtime stage's `public/` into itself for the sidecar.

Nuxt SSR image: separate `Dockerfile.frontend` — deps → build (`.output/`)
→ `node:22-alpine` runtime serving on `:3000`.

**Why**: per-stage layer cache; vendor changes don't bust asset cache;
runtime image stays free of node/composer toolchains.

### 1.2 PHP extensions via `mlocati/docker-php-extension-installer`

```dockerfile
ADD --chmod=0755 https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions /usr/local/bin/
RUN install-php-extensions pdo_mysql gd exif zip intl mbstring bcmath pcntl opcache redis
```

Pulls precompiled extensions when available, falls back to building only for
the rest. Cuts build time by an order of magnitude vs. `docker-php-ext-install`.

### 1.3 Non-root, pin the UID across every stack image

Create a `www` user with `uid=1000` **in every image that touches shared
log/asset volumes**, including the nginx sidecar:

```dockerfile
RUN addgroup -g 1000 -S www && adduser -u 1000 -S www -G www
```

**Why**: the shared `app-logs` volume mounted into nginx + app + worker +
scheduler needs consistent ownership. Default nginx images run as uid 101;
without alignment, nginx-written logs become unreadable to the app's `www`
user (and to log-viewer).

### 1.4 Bake fingerprinted assets into the nginx image — do **not** share
       `public/build/` via a volume

```dockerfile
FROM nginx:1.27-alpine AS nginx
COPY --from=production /var/www/html/public /var/www/html/public
```

A Vite-fingerprinted manifest in the app image must match exactly the files
nginx serves. A named volume mounted at `/var/www/html/public/build/`
freezes on first deploy and shadows fresh image content on every subsequent
deploy (see §2.1) — every release degrades to "manifest references hashed
assets that don't exist". Baking guarantees app + nginx ship as a matched
pair.

**Build-trigger rule (workflow path filter)**: any backend change must
rebuild the nginx image too, because the nginx image `COPY`s the backend
image's `public/`. Backend-only change with a stale nginx image = 404s on
hashed Vite files in production.

### 1.5 Image tagging

- Immutable: `${env}-${sha}` (e.g. `prod-abc1234`). Never overwritten — this
  is the rollback target.
- Rolling: `${env}-latest` — what `deploy.sh` pulls.
- On-disk markers: `/var/www/<app>/.deploy/<image>.digest` record the local
  image ID after a successful deploy. Next deploy compares against these and
  **exits 0 with "nothing to do"** when nothing moved.

Three images per project (Laravel + Nuxt + nginx): backend / frontend /
nginx. Each gets its own digest marker.

### 1.6 Registry namespace must be lowercase, hardcoded

GHCR rejects uppercase in the namespace path. The workflow must
**hardcode** `REGISTRY=ghcr.io/<lowercase-owner>` — do not interpolate
`${{ github.repository_owner }}` because GitHub usernames can be mixed-case
(e.g. `Blaryxoff`). The remote `bin/deploy.sh` receives `REGISTRY` as an env
var, lowercased.

### 1.7 Slim the runtime image

Remove dev-only files **as a final layer in the runtime stage**:
```dockerfile
RUN rm -rf tests/ node_modules/ .git/ docker/ docs/ toolkits/ visual/ \
    .env.example phpunit.xml pint.json eslint.config.js \
    vite.config.ts tsconfig.json components.json \
    resources/js/ resources/css/ storage/logs/*.log
```

Never copy `.env` or any secret material into the image.

---

## 2. Volumes — mount-safety

### 2.1 Mount **leaf** paths only

The single most important Docker rule on this fleet.

> Named volumes seed from the image on **first creation only**. After that,
> the frozen volume contents shadow whatever the image ships at the same
> path on every subsequent deploy.

Wrong:
```yaml
volumes:
  - app-storage:/var/www/html/storage      # ❌ shadows framework/cache, framework/sessions, …
```

Right:
```yaml
volumes:
  - app-public:/var/www/html/storage/app/public    # ✅ leaf
  - app-private:/var/www/html/storage/app/private  # ✅ leaf
  - app-logs:/var/www/html/storage/logs            # ✅ leaf
```

If you mount the parent, adding a new sibling dir
(`storage/app/exports`, `storage/framework/cache/data`, …) in a later image
build is invisible to the running container — the first-deploy volume wins.
Leaf-mount and the image's `Dockerfile` can `mkdir -p` whatever it needs.

### 2.2 Public-asset shadowing — the same trap, separately

Do not share `public/build/` between nginx and app (see §1.4). The
`app-public` volume is **only** for user uploads. nginx serves user uploads
read-only from it:

```yaml
nginx:
  volumes:
    - app-public:/var/www/html/storage/app/public:ro
    - app-logs:/var/www/html/storage/logs
```
```nginx
location /storage/ {
    alias /var/www/html/storage/app/public/;
}
```
(There is no `public/storage` symlink in the nginx image — `php artisan
storage:link` doesn't reach across containers.)

### 2.3 Named volumes are fragile — back them up off-host

Volumes live in `/var/lib/docker/volumes/`. `docker compose down -v`, disk
failure, or a careless `docker volume prune` deletes them. See §11.

### 2.4 No host bind-mounts to source paths in production

All persistent data in **named volumes**, not `./storage:/var/www/...` bind
mounts. Bind mounts couple containers to host paths and break the image's
ownership/permission contract.

---

## 3. Logging — single discoverable funnel

### 3.1 Funnel every log into `storage/logs/` via a shared volume

Mount the same `app-logs` named volume at `/var/www/html/storage/logs` in
**every** app-stack container (app / worker / scheduler / nginx). Then
configure each component to write there:

- **Laravel**: `storage/logs/laravel.log` (default).
- **PHP**: `php.ini` → `error_log = /var/www/html/storage/logs/php-error.log`.
- **PHP-FPM**: `php-fpm.conf` `[global]` → `error_log = /var/www/html/storage/logs/php-fpm-error.log`.
- **nginx**: `nginx.conf` → `error_log /var/www/html/storage/logs/nginx-error.log warn;`
  + `access_log /var/www/html/storage/logs/nginx-access.log main;`.

**Why**: a single in-app `log-viewer` (laravel/log-viewer or similar) reads
**every** layer's log without operator SSH. Ops keep one path to grep. Logs
survive container recreation (they're on the volume).

This is the reason §1.3 pins uid 1000 across the nginx image — the nginx
worker must write to a directory the app's `www:1000` will also write to,
or log-viewer ends up with permission errors.

### 3.2 Docker json-file rotation — **mandatory**

The default json-file driver is unbounded and will fill the disk. Set
per-service:
```yaml
logging:
  driver: json-file
  options:
    max-size: "50m"
    max-file: "5"
```
or, better, in `/etc/docker/daemon.json` for fleet-wide defaults. Use
smaller caps for chatty stateful services (`max-size: "20m", max-file: "3"`
for redis/mysql).

Independent of §3.1: `storage/logs/*` files are not rotated by Docker. Use
Laravel's daily channel + a logrotate or app-level cleanup if they matter
long-term.

### 3.3 Capture container logs on deploy failure

When a healthcheck fails inside the deploy loop:
```bash
docker logs --tail=120 "$container" \
  > "/var/www/<app>/storage/logs/container/$container.log"
```
The file survives the container's removal and is the first thing on-call
reads.

---

## 4. Networking

### 4.1 Host port bindings on `127.0.0.1` for everything except the host
       reverse proxy

```yaml
nginx:
  ports:
    - "127.0.0.1:${HTTP_PORT:-8080}:80"
mysql:
  ports:
    - "127.0.0.1:3306:3306"  # only if you need SSH-tunnel access
```

Defence-in-depth on top of cloud-firewall security groups. A misconfigured
firewall change must not expose mysql to the internet.

The only listener on `0.0.0.0:{80,443}` is the host's reverse proxy (Caddy
or host nginx — see §9).

### 4.2 Shared external network for cross-tenant infrastructure

When several apps on the same host share an instance of redis/postgres,
create one host-level network and declare it `external: true` in each app's
compose:

```yaml
networks:
  shared:
    name: lemp-shared
    external: true
```

Provisioned once on the host:
```bash
docker network create lemp-shared
docker network connect lemp-shared redis
```

Apps come and go independently of the shared infra.

### 4.3 Pin cross-network env vars in compose, not just `.env`

```yaml
services:
  app:
    environment:
      REDIS_HOST: redis        # pinned, overrides .env
```

A stray `REDIS_HOST=127.0.0.1` in `.env` can't break this — the compose
`environment:` value wins.

Multi-tenant safety: namespace your keys (`REDIS_PREFIX=<app>-database-`,
`<app>-cache-`) — never assume the redis instance is yours alone.

### 4.4 Block container access to cloud IMDS

Cloud metadata services (`169.254.169.254`) can mint short-lived IAM
tokens. **Containers must not be able to reach them**, even if the host VM
can:

```bash
iptables -I DOCKER-USER -d 169.254.169.254 -j DROP
```

Track as a systemd unit so it re-applies after reboot. Without this any
tenant container can mint host IAM tokens and exfiltrate cloud resources.

---

## 5. Environment variables

### 5.1 `env_file:` is frozen at container start

`env_file:` injects into the container's environment **once**, at start.
Editing `/var/www/<app>/.env` on the host doesn't reach a running container.
`docker compose restart` does **not** re-read `env_file`. Always recreate
the affected services. Provide a `make reload-env env=<env>` target (see
§7.5) so operators never reach for `docker compose restart` muscle-memory.

### 5.2 `env_file:` doesn't populate compose's own substitution scope

This trips up every first deploy. If `compose.yml` substitutes
`${MYSQL_ROOT_PASSWORD}` into a service's `environment:` block, compose
evaluates that against its own **shell env**, not against `env_file:`
values.

A fresh `docker compose up -d` for a stateful service therefore boots
mysql with **empty creds**, initialises the volume with no root password,
and you have to drop the volume and start over.

Fix: the deploy script sources the env file into its own shell **before**
running `compose up` on any stateful service that needs creds in
`environment:`:

```bash
set -a; source "$ENV_FILE"; set +a
docker compose up -d --pull never mysql redis
```

The Makefile's day-to-day compose targets (ps, logs, ad-hoc up --no-deps)
must do the same so substitution resolves the same way:

```make
compose_body = cd $(remote_dir) \
 && set -a && . ./.deploy/compose.env && . ./.env && set +a \
 && docker compose -f $(compose_file)
```

Where `.deploy/compose.env` is a file `bin/deploy.sh` writes after every
deploy with the resolved `BACKEND_IMAGE`/`FRONTEND_IMAGE`/`NGINX_IMAGE` +
`API_HOST`/`FRONTEND_HOST`/`HTTP_PORT`. Both layers source both files →
substitution is reproducible from any operator path.

### 5.3 Never commit secrets

`.gitignore` `.env*` (with `.env.example` checked in as documentation).
Same for `*.json` SA keys, `letsencrypt/.secrets/`, mail API keys. A
pre-commit hook is preferable to discipline.

### 5.4 Secrets distribution

`.env` lives on the host at `/var/www/<app>/.env`, mode `0640`, owned by
the interactive operator account (see §7.1). One-time `scp` by hand on
first provision; subsequent ops use `make sync-env env=… from=.env.test`.

---

## 6. Healthchecks

### 6.1 Every service has a healthcheck

| Component | Healthcheck |
|---|---|
| PHP-FPM | `cgi-fcgi -bind -connect 127.0.0.1:9000` with `SCRIPT_NAME=/ping SCRIPT_FILENAME=/ping REQUEST_METHOD=GET` against FPM's built-in `ping.path=/ping`. **Requires `apk add fcgi` in the runtime image.** Or a plain TCP probe. |
| nginx sidecar | `wget --spider http://127.0.0.1/healthz` against a Laravel route that returns 200. |
| Queue worker | `pgrep -f 'queue:work'`. Pair with `--max-time=3600` so the worker self-recycles. |
| Scheduler | `pgrep -f 'schedule:work'` (long-running with a stable PID — `withoutOverlapping`/`onOneServer` mutexes still cover safety). |
| MySQL | `mysqladmin ping -h 127.0.0.1` with creds from env. |
| Redis | `redis-cli ping` returns `PONG`. |
| Frontend SSR | `wget --spider http://127.0.0.1:3000/`. |

### 6.2 `start_period`

Always set `start_period`. FPM-based PHP apps need ~90s for the cold-start
artisan caches (`config:cache`, `route:cache`, `view:cache`, `event:cache`).
Frontend SSR needs 15–30s. Without it, the first compose-up flips through
"unhealthy" and trips the deploy-failure path.

### 6.3 Orchestrated startup with `depends_on`

```yaml
depends_on:
  app:
    condition: service_healthy
```

Use `service_healthy` (not `service_started`) for anything that calls into
the dependency at boot. One-shot migrations:
`condition: service_completed_successfully`.

### 6.4 `/up` and `/healthz` routes

Laravel ships `/up` since 11.x. Define `/healthz` as a peer that returns
200 unconditionally (used by the nginx-container healthcheck) and, when
the project has a real readiness contract, `/healthz/ready` that verifies
DB + Redis reachability. The latter only matters on multi-node setups
(LB drains the unready node — see §14); on single-node, `/up` is enough.

---

## 7. Deploy script — the single source of truth

### 7.1 One script, called from anywhere

```
.github/workflows/deploy-<env>.yml      Makefile target            Operator SSH
              \                              |                          /
               \                             |                         /
                \____________________________v________________________/
                                  bin/deploy.sh (on the host)
                                              |
                                              v
                                  docker compose up -d …
```

The deploy logic lives in **one file** — `bin/deploy.sh` on the host (or
`bin/gp.sh deploy` for fleets). GitHub Actions wraps it via SSH; the
Makefile wraps it via `gh workflow run` (or via direct SSH as a fallback).
**Same code path, three entry points.**

This is non-negotiable: never put deploy logic inside the workflow YAML or
inside the Makefile recipe. Both must remain **thin wrappers** that pass
env vars and call the script.

The script + `docker/compose.yml` are scp'd to the host by the workflow on
every run (via `install -m 755 /dev/stdin /var/www/<app>/bin/deploy.sh` to
get a clean ownership rewrite). So the SSH-fallback path stays usable as
long as at least one CI deploy ever ran.

### 7.2 Two-account model on the host

| Account | Used by | Permissions |
|---|---|---|
| `user` (interactive) | Makefile targets (`reload-env`, `sync-env`, `ps`, `logs`, `shell`, …). | sudo, owns `/var/www/<app>/` (mode `2775`, group `<app>`), in `docker` group. |
| `deploy` (CI-only) | `.github/workflows/deploy-*.yml`. | no sudo, no file ownership, in `docker` and `<app>` groups (group-writable on `/var/www/<app>/`). |

The CI account never needs `sudo` because `2775` on `/var/www/<app>/` lets
the group `<app>` write into it, and the deploy account is in that group.

### 7.3 The script's algorithm

```
1. flock -n /var/lock/<app>-deploy-${DEPLOY_ENV}.lock  → concurrent deploys fail fast
2. docker pull every image; resolve new local image IDs
3. Compare against /var/www/<app>/.deploy/<image>.digest
   → if nothing moved and FORCE_RECREATE unset, exit 0 "nothing to do"
4. set -a; source $ENV_FILE; set +a   (§5.2)
5. compose up -d --pull never mysql redis   → wait for healthy (180s max)
6. If backend image moved (or FORCE_RECREATE): docker run --rm migrate
   one-shot against the NEW image — failure aborts WITHOUT touching live
   containers
7. compose up -d --pull never --remove-orphans [--force-recreate]
8. Wait for backend/frontend/nginx to report healthy; dump last 120 log
   lines per container into storage/logs/container/ on failure
9. Write new image IDs to .deploy/*.digest
10. Write .deploy/compose.env with the resolved image refs + hosts so
    the Makefile's compose_body sees the same substitution scope
11. If backend image moved: docker exec backend php artisan queue:restart
    (nudge long-running workers to pick up new code)
```

Idempotent end-to-end: re-running with no image changes exits at step 3.

### 7.4 No first-class rollback on single-node, but the recipe is documented

```bash
# pick the previous immutable sha from GHCR
docker pull ghcr.io/<owner>/<app>-backend:<env>-<prev-sha>
docker tag  ghcr.io/<owner>/<app>-backend:<env>-<prev-sha> \
            ghcr.io/<owner>/<app>-backend:<env>-latest
# (repeat for frontend / nginx if they moved)
sudo rm /var/www/<app>/.deploy/*.digest
FORCE_RECREATE=true /var/www/<app>/bin/deploy.sh
```

If the rollback needs a schema down-migration, run that manually first —
`entrypoint.sh migrate` only runs `migrate --force --isolated`.

### 7.5 Canonical operator commands

Every project ships **this** Makefile + workflow shape. The commands and
their semantics are the contract; the implementation may differ slightly.

#### Deploy (GitHub Actions primary, SSH fallback)

| Make target | What it does | Underlying call |
|---|---|---|
| `make deploy-test [force=true]` | Trigger `deploy-test.yml`. | `gh workflow run deploy-test.yml [-f force_recreate=true]` |
| `make deploy-prod [force=true]` | Trigger `deploy-prod.yml`. | `gh workflow run deploy-prod.yml [-f force_recreate=true]` |
| `make build-images` | Trigger image build. | `gh workflow run build-images.yml` |

The deploy workflows are `workflow_dispatch` only (no auto-deploy on
push), so a merge to `master` doesn't deploy until you explicitly say so.
Optionally: `build-images.yml` auto-triggers `deploy-test.yml` on a
successful `dev`-branch build, so test stays current.

SSH fallback when CI is broken:
```bash
ssh user@<host>
sudo -u <ci-user> DEPLOY_ENV=test REGISTRY=ghcr.io/<owner> \
  API_HOST=api.test.example.com FRONTEND_HOST=test.example.com \
  /var/www/<app>/bin/deploy.sh
```

#### Env / config refresh (no image bump)

| Make target | What it does |
|---|---|
| `make reload-env [env=test\|prod]` | `compose up -d --force-recreate --no-deps backend worker scheduler` so env_file is re-read (§5.1). |
| `make sync-env env=… from=.env.test` | `scp` local env file to the host's `.env`, then `reload-env`. |
| `make render-compose [env=…]` | `cat` the live compose file on the host. |

#### Smoke (local curl, no SSH)

| Make target | What it does |
|---|---|
| `make smoke-test` | `curl -fsS` the frontend and `/up` on the API. Exits non-zero on failure. |
| `make smoke-prod` | Same, against prod hosts. |

#### Inspect / day-to-day (auto-SSH to env host)

| Make target | Equivalent on the host |
|---|---|
| `make ps [env=…]` | `docker compose ps` |
| `make logs [env=…] [service=backend] [tail=100]` | `docker compose logs -f --tail=$tail $service` |
| `make logs-backend [env=…]` | `… logs -f backend` (shortcut) |
| `make logs-frontend / -nginx / -worker / -scheduler [env=…]` | per-service shortcuts |
| `make shell [env=…]` | `docker exec -it <app>-backend bash` |
| `make tinker [env=…]` | `docker exec -it <app>-backend php artisan tinker` |
| `make artisan [env=…] cmd='about'` | `docker exec -i <app>-backend php artisan $cmd` |
| `make migrate [env=…]` | `docker exec -i <app>-backend php artisan migrate --force` |
| `make queue-restart [env=…]` | `docker exec -i <app>-backend php artisan queue:restart` |
| `make db-shell [env=…]` | `docker exec -it <app>-mysql mysql -uroot -p"$MYSQL_ROOT_PASSWORD"` |
| `make redis-shell [env=…]` | `docker exec -it <app>-redis redis-cli` |
| `make wait-healthy [env=…]` | poll `docker inspect --format '{{.State.Health.Status}}'` until healthy or 3 min. |

Conventions:

- `env` defaults to `test`; targets that take it have a `require-env` guard
  that rejects anything other than `test|prod`.
- The host is resolved by `host ?= $(if $(filter prod,$(env)),$(APP_PROD_HOST),$(APP_TEST_HOST))`,
  each overridable via shell env. Set `APP_PROD_HOST` etc. in `~/.zshrc`,
  not in the Makefile.
- SSH identity is pinned to a project-specific key
  (`ssh_key ?= $(HOME)/.ssh/<app>_deploy`) so behaviour doesn't depend on
  the user's `ssh-agent` state.
- TTY flags: `-t` for log streaming (line-buffered), `-tt` for `shell` /
  `tinker` / `db-shell` (real TTY).
- The `compose_body` macro sources `.deploy/compose.env` + `.env` so
  ad-hoc compose commands resolve substitution exactly the way `deploy.sh`
  does (§5.2).
- One `pint` / `pint-fix` target (Laravel) for pre-push linting. Cheap
  feedback before CI.

### 7.6 Workflow shape — thin SSH orchestrators

`deploy-test.yml` and `deploy-prod.yml` do **only** four things:

1. `actions/checkout@v4` (`ref: master` for prod; `ref: ${{ inputs.ref || 'dev' }}` for test).
2. Set up an SSH key from `secrets.DEPLOY_<ENV>_SSH_PRIVATE_KEY`,
   `ssh-keyscan` the host into `known_hosts`.
3. `ssh "$REMOTE" 'install -m 755 /dev/stdin /var/www/<app>/bin/deploy.sh' < bin/deploy.sh`
   (and same for `docker/compose.yml`). `install` rewrites ownership and
   mode atomically, regardless of any prior file owner.
4. Pass env vars (`DEPLOY_ENV`, `REGISTRY`, `API_HOST`, `FRONTEND_HOST`,
   `HTTP_PORT`, `FORCE_RECREATE`) over SSH and run
   `/var/www/<app>/bin/deploy.sh`.

Required secrets per env:
- `DEPLOY_<ENV>_SSH_PRIVATE_KEY` — SSH key authorised on the box.
- `DEPLOY_<ENV>_SSH_USER` — usually `deploy`.
- `DEPLOY_<ENV>_HOST` — IP or hostname.
- `DEPLOY_<ENV>_API_HOST`, `DEPLOY_<ENV>_FRONTEND_HOST`.
- `DEPLOY_<ENV>_HTTP_PORT` (optional, default 80).
- `DEPLOY_<ENV>_GHCR_USERNAME` / `_GHCR_TOKEN` (optional — fall back to
  `secrets.GITHUB_TOKEN` for public packages).

Other required fields in the workflow:
```yaml
concurrency:
  group: deploy-<env>
  cancel-in-progress: false   # serialise, never cancel a deploy mid-flight

permissions:
  contents: read
  packages: read              # docker login ghcr.io with GITHUB_TOKEN

environment: <env>            # so reviewers + protection rules apply
timeout-minutes: 20           # or 30 for prod
```

Lowercase the registry namespace inside the workflow:
```bash
REGISTRY="ghcr.io/$(printf '%s' "$OWNER_RAW" | tr '[:upper:]' '[:lower:]')"
```

### 7.7 `build-images.yml` shape

Builds + pushes `<app>-backend`, `<app>-frontend`, `<app>-nginx` to GHCR.

- Use `dorny/paths-filter@v3` to skip rebuilds when nothing image-relevant
  changed (`app/**`, `composer.*`, `resources/**`, `docker/Dockerfile`,
  `docker/php/**` for backend; etc.). `workflow_dispatch.inputs.force_all`
  overrides.
- **Nginx must rebuild whenever backend rebuilds** (§1.4): wire the path
  filter accordingly.
- Two tags per image: `${env}-${sha}` (immutable, used for rollback) +
  `${env}-latest` (rolling, what deploy pulls).
- `env` is `prod` on `master` pushes, `test` on `dev` pushes.
- `cache-to: type=registry,mode=max` so every layer is cached across
  runs/branches.
- On successful `dev` build, optionally `workflow_dispatch` `deploy-test.yml`
  via `gh api /repos/.../actions/workflows/.../dispatches`. Keeps test
  current without manual ops.
- `concurrency.group: build-images-${{ github.ref }}` + `cancel-in-progress: true`
  — older builds on the same branch are cancelled by a newer commit (the
  newer wins). Deploys are NOT cancelled (they have their own concurrency
  group).

### 7.8 Plain `docker compose restart` is forbidden

It does not reload `env_file:` (§5.1), it does not pull new images, and it
recreates nothing. Operators reach for it because it sounds right; the
Makefile shape (`reload-env`, `deploy-…`) is the only sanctioned way.

---

## 8. TLS

### 8.1 Termination on the host, not in the app's nginx sidecar

The sidecar listens on plain HTTP on loopback; the host proxy does TLS,
ACME, HSTS. Cert renewal is then independent of container churn.

### 8.2 Caddy is the default for single-node

Caddy 2 on the host, `:80` (ACME HTTP-01 + redirect) and `:443`. Auto-LE,
auto-renew, certs survive Caddy restarts. Zero cron, zero hooks.

`/etc/caddy/Caddyfile` is **not** shipped by the deploy script — it's
host config. Edit by hand, `sudo systemctl reload caddy`.

Adding a host: add a site block, `dig +short <host>` to confirm the A
record exists, `sudo systemctl reload caddy`. Cert is issued on first
request.

### 8.3 certbot only when Caddy isn't an option

E.g. you need DNS-01 wildcards, or you're behind a fronting nginx config
the team owns. Then host nginx + certbot, `renew_hook = systemctl reload
nginx`. For multi-node cert distribution see §14.

---

## 9. Restart, resource limits, security

### 9.1 `restart: unless-stopped`, always

The default `restart: no` leaves containers down indefinitely after a
crash. `restart: always` restarts even after a deliberate `docker stop`,
which breaks ops. `unless-stopped` is the right answer.

One-shot containers (pre-flight migrate, db seed) use `restart: "no"` +
`condition: service_completed_successfully` on the dependants.

### 9.2 Memory / CPU limits

```yaml
deploy:
  resources:
    limits:
      memory: 1g
      cpus: '1.0'
    reservations:
      memory: 256m
```

For non-Swarm `docker compose`, the equivalent keys are `mem_limit:` /
`cpus:`. Same principle: one runaway container can't consume all host RAM.

MySQL: `innodb_buffer_pool_size ≈ 50–70%` of the limit. PostgreSQL:
`shared_buffers ≈ 25%`. Tune deliberately.

### 9.3 Read-only filesystems where possible

`read_only: true` + explicit `tmpfs:` for writable scratch. Reduces RCE
blast radius.

### 9.4 Pin base images, never `latest`

`FROM php:8.4-fpm-alpine`, never `FROM php:latest`. For greater paranoia
pin by digest (`@sha256:…`) and renew deliberately.

### 9.5 Never expose docker.sock to a container

If you think you need to, you don't. Use a proxy with explicit allowlisted
endpoints (e.g. `tecnativa/docker-socket-proxy`) and treat it as tier-1
attack surface.

---

## 10. Backup & restore

### 10.1 Logical DB backups

`spatie/laravel-backup` (or `pg_dump | gzip`) on a schedule, **gated to
`APP_ENV=production`** so test envs don't paginate S3 with junk:

```php
// routes/console.php
if (app()->environment('production')) {
    Schedule::command('backup:clean')->dailyAt('01:30');
    Schedule::command('backup:run')->dailyAt('02:00');
    Schedule::command('backup:monitor')->dailyAt('07:00');
}
```

Retention: 7d keep-all → 16d daily → 8w weekly → 4m monthly → 2y yearly.
Hard cap (e.g. 5 GB), oldest-first deletion past the cap.

### 10.2 Off-host destination

S3 / Selectel S3 / B2 — anything but `/var/backups/` on the same host. A
disk failure must not be the same incident as a backup loss.

### 10.3 Validate restores

Monthly, restore the latest archive into a throwaway env and verify the
app boots with the expected last-write. An untested backup is not a backup.

### 10.4 Wire failure alerts

`BACKUP_NOTIFICATION_EMAIL` (or equivalent Telegram via a scheduled
`backup:monitor` failing) — a backup that silently breaks 3 weeks ago is
the standard incident.

---

## 11. INFRASTRUCTURE.md — the operator map

Every project ships `docker/INFRASTRUCTURE.md` covering, at minimum:

1. **Topology** — Mermaid `flowchart LR` of DNS → host proxy → containers
   → datastores.
2. **Source of truth** — table of `bin/deploy.sh`, `docker/compose.yml`,
   `Dockerfile*`, `Makefile`, every workflow YAML, with a one-line role.
3. **Operator paths** — primary (GitHub Actions) vs fallback (direct SSH).
   The fallback **must** be self-sufficient.
4. **Layout** — registry, image tags, hostnames, host paths
   (`/var/www/<app>/{.env,.env.frontend,docker/compose.yml,bin/deploy.sh,.deploy/}`),
   named volumes, ports + bind addresses.
5. **Containers** — table: name, role, healthcheck, restart policy.
6. **Deploy flow** — the §7.3 algorithm, project-specific.
7. **Rollback** — the §7.4 recipe.
8. **Env-only changes** — `reload-env` recipe with the §5.1 reminder.
9. **TLS** — Caddy config or certbot inventory.
10. **Backups** — destination, schedule, retention, restore drill.
11. **Day-to-day commands** — the §7.5 catalogue.
12. **Debug checklist** — 5–10 commands from "is the container up" to
    "is the app's DB reachable from inside the container".
13. **Common failure modes** — symptom → fix recipe, grown over time.
14. **Operational notes** — "never commit X", "image rebuild triggers Y",
    "compose restart does not Z".

Without this document, only the person who wrote the deploy can operate
it. With it, anyone with SSH can.

---

## 12. Anti-patterns (catalogue)

- ❌ Mounting `/var/www/html/storage` as a single named volume — shadows
  framework/cache subdirs forever (§2.1).
- ❌ Sharing `public/build/` between app and nginx via a volume — stale
  assets vs. fingerprinted manifest (§1.4, §2.2).
- ❌ Backend rebuild without nginx rebuild — same shadowing, via the
  workflow this time (§1.4, §7.7).
- ❌ `docker compose restart` after editing `.env` — env_file is frozen at
  start (§5.1, §7.8).
- ❌ Bare `docker compose up -d mysql` on first deploy when compose
  substitutes creds — mysql initialises with empty root password (§5.2).
- ❌ Putting deploy logic in the workflow YAML or the Makefile recipe — both
  must be thin wrappers around `bin/deploy.sh` (§7.1).
- ❌ Containers reachable to cloud IMDS (`169.254.169.254`) on cloud VMs
  (§4.4).
- ❌ `0.0.0.0:3306:3306` on the host (§4.1).
- ❌ Default json-file driver, no rotation — disk fills (§3.2).
- ❌ `FROM php:latest` — unreproducible (§9.4).
- ❌ Skipping `start_period` — first deploy spuriously "unhealthy" (§6.2).
- ❌ Local-only backups (§10.2).
- ❌ `${{ github.repository_owner }}` in image tags — uppercase breaks GHCR
  (§1.6).

---

## 13. Quick checklist — single-node baseline

Use this when bootstrapping or auditing the **standard** Laravel + Nuxt
single-node project. Each item maps to a section above.

- [ ] Multi-stage Dockerfile (node → composer → fpm + nginx stage); mlocati
      installer; non-root uid 1000; nginx stage has uid 1000 too. (§1.1–§1.3)
- [ ] `public/build/` baked into the nginx image (not shared via a
      volume); backend changes trigger nginx rebuild in the workflow. (§1.4)
- [ ] Image tags: `${env}-${sha}` immutable + `${env}-latest` rolling;
      digest markers under `/var/www/<app>/.deploy/`; registry hardcoded
      lowercase in workflow. (§1.5, §1.6)
- [ ] Every volume mount is a **leaf** path. (§2.1)
- [ ] `app-logs` shared across app/worker/scheduler/nginx; PHP / PHP-FPM
      / nginx all `error_log` into `storage/logs/`. (§3.1)
- [ ] Per-service `logging:` with `max-size`/`max-file`. (§3.2)
- [ ] Host ports bind `127.0.0.1`; mysql/redis never `0.0.0.0`. (§4.1)
- [ ] `REDIS_HOST` pinned in service `environment:` if redis is on a
      shared network. (§4.2, §4.3)
- [ ] (Cloud only) IMDS blocked from containers. (§4.4)
- [ ] `env_file:` documented as start-frozen; `reload-env` target exists.
      (§5.1, §7.5)
- [ ] `bin/deploy.sh` sources `$ENV_FILE` before `compose up` on stateful
      services with creds in `environment:`. (§5.2)
- [ ] Healthcheck on every service; `start_period` set; FPM image has
      `apk add fcgi`; `/up` (and `/healthz` if used) wired. (§6)
- [ ] `bin/deploy.sh` is the single source of truth; Makefile + workflows
      are thin wrappers. (§7.1)
- [ ] Two-account host model (`user` for ops, `deploy` for CI). (§7.2)
- [ ] Deploy script: flock, idempotent digest markers, source env, pre-
      flight migrate one-shot, force-recreate flag, post-deploy
      `queue:restart`. (§7.3)
- [ ] Makefile commands match §7.5 catalogue (deploy-test/prod,
      reload-env, sync-env, render-compose, smoke-test/prod, ps, logs,
      per-service logs, shell, tinker, artisan, migrate, queue-restart,
      db-shell, redis-shell, wait-healthy).
- [ ] Workflow shape per §7.6: `workflow_dispatch`, `concurrency.group =
      deploy-<env>` with `cancel-in-progress: false`, `environment: <env>`,
      `install -m … /dev/stdin` for atomic file rewrite.
- [ ] `build-images.yml` uses paths-filter; backend change triggers nginx
      rebuild; two tags per image; registry-mode cache. (§7.7)
- [ ] TLS terminated on the host (Caddy preferred). (§8)
- [ ] `restart: unless-stopped`; resource limits set; base images pinned;
      no docker.sock exposure. (§9)
- [ ] Backups to off-host S3, gated to `APP_ENV=production`, retention +
      cap, restore drill scheduled. (§10)
- [ ] `docker/INFRASTRUCTURE.md` exists and covers all §11 sections.

---

## 14. Appendix — multi-node fleet add-on

**Only apply this section if the project really has more than one app
node behind a network load balancer.** For 99% of projects, skip it.

### 14.1 NLB drain/restore around per-node recreate

```
for node in $NODES; do
  nlb drain $node
  ssh $node 'compose up -d --pull always --force-recreate'
  ssh $node 'wait-healthy'
  validate-asset-manifest
  nlb restore $node
done
```

On failure inside the loop, **the drained node stays drained**. Alert
fires. Recovery is explicit (rollback or fix-forward + redeploy). There
must be an env-var override (`PROD_AUTO_RESTORE_ON_FAILURE=true`) for true
emergencies, never the default.

### 14.2 `/healthz/ready` is the NLB target

Laravel-side endpoint that verifies DB + Redis + (Typesense / etc.)
reachability **from the container's vantage point**. A node that loses a
dependency drains itself automatically.

### 14.3 Asset-manifest validation gate

After the new nginx image is up but **before** restoring NLB traffic, walk
every entry in `public/build/manifest.json` and assert each file exists in
the nginx image. Failed assertion → abort, no restore. Catches the
"frontend build dropped a file" class of bug.

### 14.4 Deploy-in-progress marker suppresses the watchdog

Touch `/var/www/<app>/.deploy-in-progress.d/<brand>` at the start of the
per-node loop; remove on exit. The watchdog ignores `unhealthy` events
while the marker exists, so a mid-deploy container restart doesn't fire a
false-positive alert.

### 14.5 Per-node watchdog (systemd timer, 1 min cadence)

Catches `unhealthy` events, restarts the container. Per-key cooldowns:
`FAILURES_BEFORE_ALERT=2` consecutive failures → **one** alert, then
`ALERT_COOLDOWN_SECONDS=1800` silence before the same key can re-alert.
Without cooldowns you get pager storms.

### 14.6 Smoke + drift + prune crons — on a host you control

```cron
*/30 * * * * user gp-cron-alert.sh smoke /var/www/<app>/bin/gp.sh smoke prod
17 6   * * * user gp-cron-alert.sh nlb-drift /var/www/<app>/bin/gp.sh nlb expected
23 4   * * * user gp-cron-alert.sh prod-docker-cleanup /var/www/<app>/bin/server-setup/prod-docker-cleanup.sh
```

Not from a "test box", not from GitHub Actions — both are out of your
control. The prod build node already has registry creds, LB CLI auth, and
env files with Telegram creds; cron is a one-file change. Set `MAILTO=""`.

### 14.7 Multi-node cert distribution (certbot)

One canonical node (A) runs certbot. Other nodes (B, C, …) proxy
`^~ /.well-known/acme-challenge/` back to A so LE validation reaches A
regardless of which node the LB picks. A `renew_hook` + a deploy hook
`/etc/letsencrypt/renewal-hooks/deploy/<app>-distribute` `tar -czhf`s the
new cert and pipes it to a restricted SSH command on each receiver:

```
command="/usr/local/sbin/<app>-cert-receiver-wrap.sh",no-port-forwarding,...
```

with a dedicated ed25519 key + `NOPASSWD` sudo only for the receiver
script. The receiver validates cert/key pubkey match, swaps with
timestamped backups, `nginx -t`, reloads nginx.

**Gotcha**: `certbot certonly` (first-time issuance) does NOT fire
`renewal-hooks/deploy/`. Only `renew` does. After the first issue,
manually fire:
```bash
sudo RENEWED_LINEAGE=/etc/letsencrypt/live/<name> \
  /usr/local/sbin/<app>-cert-distribute.sh
```
Document this loudly in INFRASTRUCTURE.md.

### 14.8 Brand multiplexing (only if you actually need it)

A brand-multiplexed setup runs N brands on the same nodes via per-brand
loopback ports and per-brand compose projects (`docker compose -p <brand>`).
This is a real tax on operator UX (`brand=<brand>` on every command,
per-brand env files, per-brand cert SANs). Don't replicate it unless the
business actually demands it; a separate VM per brand is usually simpler.

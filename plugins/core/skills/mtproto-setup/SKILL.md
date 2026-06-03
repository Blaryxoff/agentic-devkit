---
name: devkit-mtproto-setup
description: deploy a Telemt (MTProto) Telegram proxy in Docker on a server that already serves websites on port 443, using nginx stream SNI routing to share the port without breaking existing vhosts or SSL. Use when the user wants to add a Telegram MTProto proxy to a Linux box without losing their web sites.
---

# MTProto (Telemt) — safe setup on a shared 443

> Paths like `plugins/<plugin>/conduct/…` resolve under the devkit clone root (`~/.claude/agentic-devkit` — this skill's symlink target), not the project root.

You are acting as a **server operator** bringing up a Telemt MTProto proxy
on a Linux box that **already runs Nginx + Certbot websites on 443**. The
existing sites must keep working. The proxy must coexist on 443 via
`nginx stream` SNI preread.

## Hard rules (non-negotiable)

1. Step-by-step. **One step → wait for verification → next step.** Never
   batch multiple mutating steps before the previous one is confirmed
   green.
2. **Backup before edit.** Any file you touch under `/etc/nginx`, snapshot
   first with a timestamped `.bak-YYYY-MM-DD-HHMMSS` sibling.
3. After every change run the relevant probe: `nginx -t`, `ss -tulpn`,
   `docker ps`, `docker logs --tail`.
4. No mass edits without a prior read-only diagnosis.
5. When in doubt, run read-only commands first.
6. **No fabrication.** Don't invent flags, paths, package names, or
   service names. If unsure, run a probe or ask.

## Phase 0 — Choose execution mode

Ask the user **once**, before doing anything else:

> Do you want me to run commands directly via SSH (provide host + auth),
> or operate in **CLI-loop** mode where I emit copy-paste-ready batches
> and you run them locally and paste the output back?

- **SSH mode** — user provides connection details. You execute commands
  yourself via `Bash`. Still respect the step-by-step rule: one logical
  step per batch, verify, then continue.
- **CLI-loop mode** — follow
  [`plugins/core/skills/cli-loop/SKILL.md`](../cli-loop/SKILL.md) and
  [`plugins/core/conduct/context-management.md`](../../conduct/context-management.md)
  CLI-loop session state. You emit commands; the user runs them; you
  wait for output.

State the chosen mode in your first reply and keep a running **State
block** with:

- mode (SSH / CLI-loop)
- proxy domain
- main vhost path
- FakeTLS domain (default `mail.ru` — do not substitute without explicit
  user direction)
- Telemt user secret (after Phase 4)
- which steps are done

## Phase 1 — Collect inputs

Ask the user (once, batched):

1. Proxy domain (e.g. `proxy.example.com`). Must already resolve to this
   server.
2. Path to the main Nginx vhost file (e.g.
   `/etc/nginx/sites-available/example.com`).
3. Confirm FakeTLS fronting domain — default `mail.ru`. Use that unless
   the user explicitly overrides.
4. Confirm proxy will share the same IP as existing sites (typical: yes).
5. OS / distro and whether Docker, Nginx, Certbot are already installed.

Record answers in the State block. Do not proceed with placeholders.

## Phase 2 — Preflight (read-only)

```bash
sudo -i
set -euo pipefail
date
uname -a
nginx -t
ss -tulpn | grep -E ':80|:443|:8443|:2443|:19091' || true
ls -la /etc/nginx/modules-enabled/*stream* 2>/dev/null || true
```

Confirm with the user before continuing:

- `nginx -t` is clean.
- It is clear which process owns `:443`.
- It is clear whether the `stream` module is loaded.

## Phase 3 — Backup the main vhost

```bash
ts=$(date +%F-%H%M%S)
MAIN_SITE_CONF="<main-vhost-path>"
cp -a "$MAIN_SITE_CONF" "${MAIN_SITE_CONF}.bak-$ts"
echo "Backup: ${MAIN_SITE_CONF}.bak-$ts"
```

Record the backup path in the State block (needed for Phase 10
rollback).

## Phase 4 — Install Docker (skip if already present)

```bash
apt update
apt install -y ca-certificates curl gnupg lsb-release
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo $VERSION_CODENAME) stable" > /etc/apt/sources.list.d/docker.list
apt update
apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
docker --version
docker compose version
```

(For Debian, swap the `ubuntu` path segments to `debian` — verify with
the user first.)

## Phase 5 — Telemt config

```bash
mkdir -p /opt/telemt
cd /opt/telemt
TG_USER_SECRET=$(openssl rand -hex 16)
echo "$TG_USER_SECRET"
```

Save `$TG_USER_SECRET` in the State block. Write
`/opt/telemt/telemt.toml`:

```toml
[general]
use_middle_proxy = true
log_level = "normal"

[general.modes]
classic = false
secure = false
tls = true

[general.links]
public_host = "<proxy-domain>"
public_port = 443
show = "*"

[server]
port = 443

[server.api]
enabled = true
listen = "0.0.0.0:9091"
whitelist = ["127.0.0.0/8", "::1/128", "172.18.0.0/16"]

[[server.listeners]]
ip = "0.0.0.0"

[censorship]
tls_domain = "mail.ru"
mask = true
tls_emulation = true
tls_front_dir = "tlsfront"

[access.users]
main = "PUT_32_HEX_SECRET_HERE"

[dc_overrides]
"201" = "149.154.167.51:443"
"203" = "91.105.192.100:443"
```

Substitutions:

- `public_host` ← proxy domain from State.
- `tls_domain` ← FakeTLS domain (default `mail.ru`).
- `access.users.main` ← `$TG_USER_SECRET`.

## Phase 6 — docker-compose for Telemt

Write `/opt/telemt/docker-compose.yml`:

```yaml
services:
  telemt:
    image: whn0thacked/telemt-docker:latest
    container_name: telemt-proxy
    restart: unless-stopped
    environment:
      RUST_LOG: info
    volumes:
      - /opt/telemt/telemt.toml:/etc/telemt.toml:ro
    ports:
      - "127.0.0.1:2443:443/tcp"
      - "127.0.0.1:19091:9091/tcp"
    security_opt:
      - no-new-privileges:true
    cap_drop:
      - ALL
    cap_add:
      - NET_BIND_SERVICE
    read_only: true
    tmpfs:
      - /tmp:rw,nosuid,nodev,noexec,size=16m
    ulimits:
      nofile:
        soft: 65536
        hard: 65536
```

Start and verify:

```bash
cd /opt/telemt
docker compose up -d
docker ps --filter name=telemt-proxy
ss -tulpn | grep -E ':2443|:19091' || true
docker logs --tail 120 telemt-proxy
```

Container must be `Up`, ports `2443` and `19091` must be bound on
loopback. If logs show startup errors, **stop** and diagnose before
touching Nginx.

## Phase 7 — Nginx for shared 443

### 7.1 Stream module

```bash
ls -la /etc/nginx/modules-enabled/*stream* 2>/dev/null || true
nginx -t
```

If stream is not loaded:

```bash
apt update
apt install -y libnginx-mod-stream
if [ ! -f /etc/nginx/modules-enabled/50-mod-stream.conf ]; then
  echo 'load_module modules/ngx_stream_module.so;' > /etc/nginx/modules-enabled/50-mod-stream.conf
fi
nginx -t
```

### 7.2 Move every HTTPS vhost from `:443` to `127.0.0.1:8443`

Goal: nothing in `sites-enabled` / `conf.d` should still bind `:443 ssl`
on the public interface — the stream block will own `:443`.

```bash
grep -RInE 'listen .*443.*ssl' /etc/nginx/sites-enabled /etc/nginx/conf.d 2>/dev/null || true
```

For each match, replace:

```nginx
listen 443 ssl;
```

with:

```nginx
listen 127.0.0.1:8443 ssl;
```

Preserve `http2` / `ipv6only` / `default_server` flags if present.
Backup each touched file before editing. Verify:

```bash
nginx -t
```

### 7.3 Enable stream and add the SNI router

Ensure `/etc/nginx/nginx.conf` contains, at top level:

```nginx
include /etc/nginx/modules-enabled/*.conf;

stream {
    include /etc/nginx/stream.d/*.conf;
}
```

If the `stream` block is missing, append it:

```bash
if ! grep -qE '^\s*stream\s*\{' /etc/nginx/nginx.conf; then
cat >> /etc/nginx/nginx.conf <<'EOF'

stream {
    include /etc/nginx/stream.d/*.conf;
}
EOF
fi
mkdir -p /etc/nginx/stream.d
```

Write `/etc/nginx/stream.d/mtproto-router.conf`:

```nginx
map $ssl_preread_server_name $tls_backend {
    mail.ru mtproto_backend;
    default web_backend;
}

upstream mtproto_backend {
    server 127.0.0.1:2443;
}

upstream web_backend {
    server 127.0.0.1:8443;
}

server {
    listen 443 reuseport;
    proxy_pass $tls_backend;
    ssl_preread on;
    proxy_connect_timeout 5s;
    proxy_timeout 10m;
}
```

If the user picked a non-default FakeTLS domain, the `map` key must
match it.

Apply:

```bash
nginx -t
systemctl reload nginx
ss -tulpn | grep -E ':443|:8443|:2443|:19091' || true
```

Expected listeners: nginx on `:443`, nginx on `127.0.0.1:8443`, telemt
on `127.0.0.1:2443` and `127.0.0.1:19091`.

## Phase 8 — Get the user link

```bash
curl -s http://127.0.0.1:19091/v1/users
```

If the API returns `forbidden`, the whitelist blocked the local fetch.
Temporarily widen it:

```toml
whitelist = ["0.0.0.0/0", "::/0"]
```

Restart Telemt (`docker compose restart telemt`), grab the link, **then
restore** the original whitelist and restart again. Do not leave the API
open.

## Phase 9 — Verify

**Websites:**

```bash
curl -Ik https://<web-domain-1>
curl -Ik https://<web-domain-2>
```

Expect `200 / 301 / 302`. Any TLS error here means Phase 7.2 missed a
vhost.

**MTProto:**

- Remove old proxies from Telegram client.
- Add the new link from Phase 8.
- Disable auto-switch during the test.
- Verify text, images, video, and media in a large public channel.

## Phase 10 — Quick diagnostics

```bash
docker ps --filter name=telemt-proxy
docker logs --tail 150 telemt-proxy
nginx -t
ss -tulpn | grep -E ':443|:8443|:2443|:19091' || true
```

Common failures:

- **`proxy unavailable`** — wrong `server` in the link, proxy DNS not
  pointing to this host, or `tls_domain` mismatched with the stream
  `map`.
- **`non-standard DC ... fallback` or broken large-channel media** —
  ensure `dc_overrides` contains at least `201` and `203`.
- **Telegram handshake timeout** — flaky route to Telegram DC; keep
  `use_middle_proxy = true` and re-check overrides.
- **`unknown directive "stream"` on `nginx -t`** — Phase 7.1 was
  skipped; install `libnginx-mod-stream` and reload.

## Phase 11 — Rollback

Restore the main vhost backup:

```bash
cp -a <main-vhost-path>.bak-<timestamp> <main-vhost-path>
nginx -t && systemctl reload nginx
```

If the failure is `unknown directive "stream"`:

```bash
rm -f /etc/nginx/stream.d/mtproto-router.conf
# remove or comment the stream { ... } block in /etc/nginx/nginx.conf
nginx -t && systemctl reload nginx
```

To swap proxy backend in the stream router (e.g. moving Telemt off
`2443`):

```nginx
upstream mtproto_backend {
    server 127.0.0.1:<new-port>;
}
```

## Capacity notes (informational)

For a 4 vCPU / 4 GB VM:

- Comfortable: ~150–500 concurrent users on mixed traffic.
- Heavy media / large channels: ~80–250 concurrent.

Final capacity is determined by load testing on the actual network.

## References

- Habr FakeTLS MTProxy: https://habr.com/ru/articles/994934/
- Telemt Docker: https://github.com/An0nX/telemt-docker
- Telemt: https://github.com/telemt/telemt
- Telegram MTProxy: https://core.telegram.org/proxy

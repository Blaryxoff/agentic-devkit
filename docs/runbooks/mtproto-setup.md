# MTProto fleet setup and recovery runbook

This is an operational reference, not an invokable agent skill. It describes the Telemt fleet used by nn99 and
Platforma. Keep secrets and live private keys out of Git.

Last checked against all three reachable Yandex nodes over SSH: **2026-09-13**.

## Source of truth

The maintained deployment artifacts live in the sibling `domovoy` repository:

- `deploy/mtproto/` — checksum-pinned Telemt image and Compose definitions;
- `deploy/mtproto-watchdog/` — end-to-end FakeTLS and MTProto watchdog;
- `facts.md` — current fleet topology;
- `decisions.md` — routing history and rejected alternatives.

Do not rebuild live definitions from examples in this runbook. Copy the matching `domovoy/deploy/mtproto` artifact,
inspect the current host, and preserve its secret-bearing `telemt.toml`.

## Verified fleet

| Node | Public host | Container | Live directory | Telemt port | AWG source |
|---|---|---|---|---:|---|
| `platforma-test` / nn99 | `connect.nn99.ru` | `telemt-proxy` | `/opt/telemt/` | `127.0.0.1:2443` | `10.78.0.4` |
| `platforma-primary` | `connect.kochfit.ru` | `grow-place-mtproto` | `/var/www/env/mtproto/` | `127.0.0.1:9443` | `10.78.0.2` |
| `platforma-secondary` | `connect.kochfit.ru` | `grow-place-mtproto` | `/var/www/env/mtproto/` | `127.0.0.1:9443` | `10.78.0.3` |
| Hetzner duplicate | deployment artifact only; not probed in the 2026-09-13 check | `telemt-proxy` | `/opt/telemt/` | `127.0.0.1:2443` | exit node |

All three probed nodes were running `domovoy/telemt:3.5.5`, returned a successful
`telemt healthcheck /etc/telemt.toml --mode ready`, and routed Telegram destinations through `awg-telemt`.

## Invariants

- Pin both the Telemt version and release checksum. Never deploy `latest`.
- Keep the API on `127.0.0.1:19091`; never expose it publicly or use `0.0.0.0/0` in its whitelist.
- Keep FakeTLS on `mail.ru` unless the nginx SNI map and every client link are changed together.
- Keep `middle_proxy_nat_ip` equal to the stable public IP Telegram sees at the AWG exit. It is currently
  `95.217.0.87`; verify before changing it.
- Keep Telegram CIDR routes on the separate `awg-telemt` interface. Do not merge it with the general `awg0` fault
  domain.
- Preserve `me2dc_fallback = true`, the `201` and `203` DC overrides, and the TLS-front assets.
- Back up every live Compose, Telemt, nginx, route, or firewall file before editing it.
- Change one node first, verify the real client path, then roll through the remaining nodes one at a time.

## Common Telemt settings

The secret-bearing live config is `/opt/telemt/telemt.toml` on nn99/Hetzner and
`/var/www/env/mtproto/telemt.toml` on Platforma. The verified non-secret settings are:

```toml
[general]
use_middle_proxy = true
middle_proxy_nat_ip = "95.217.0.87"
middle_proxy_nat_probe = true
me2dc_fallback = true

[general.modes]
classic = false
secure = false
tls = true

[general.links]
public_host = "<connect.nn99.ru-or-connect.kochfit.ru>"
public_port = 443

[server]
port = 443

[server.api]
enabled = true
listen = "0.0.0.0:9091"
whitelist = ["127.0.0.0/8", "::1/128", "<actual-compose-bridge-subnets>"]

[censorship]
tls_domain = "mail.ru"
mask = true
tls_emulation = true
tls_front_dir = "tlsfront"

[access.users]
main = "<32-hex-secret; never commit>"

[dc_overrides]
"201" = "149.154.167.51:443"
"203" = "91.105.192.100:443"
```

The bridge whitelist is node-specific. Inspect the actual Docker networks rather than copying a subnet from another
node.

## Compose variants

Use `domovoy/deploy/mtproto/docker-compose.yml` for nn99 and Hetzner. It provides:

- container `telemt-proxy`;
- config `/opt/telemt/telemt.toml`;
- loopback ports `2443` and `19091`;
- a read-only container, dropped capabilities, `no-new-privileges`, and a bounded `/tmp` tmpfs.

Use `domovoy/deploy/mtproto/docker-compose.platforma.yml` for both Platforma nodes. It preserves:

- container `grow-place-mtproto`;
- config and TLS-front files under `/var/www/env/mtproto/`;
- loopback ports `9443` and `19091`;
- the existing log rotation and file-descriptor limits.

The two definitions are deliberately different. Do not normalize the Platforma nodes to the nn99 layout during an
image upgrade.

## Shared port 443

### nn99

The active router is `/etc/nginx/stream.d/mtproto-router.conf`:

```nginx
map $ssl_preread_server_name $tls_backend {
    mail.ru mtproto_backend;
    edge.nn99.ru xray_backend;
    default web_backend;
}

upstream mtproto_backend { server 127.0.0.1:2443; }
upstream xray_backend { server 127.0.0.1:10443; }
upstream web_backend { server 127.0.0.1:8443; }

server {
    listen 443 reuseport;
    proxy_pass $tls_backend;
    ssl_preread on;
    proxy_connect_timeout 5s;
    proxy_timeout 10m;
}
```

Do not replace this with a two-route example: `edge.nn99.ru` still needs the Xray backend.

### Platforma primary and secondary

The active router is `/etc/nginx/stream-conf.d/grow-place-stream.conf`:

```nginx
map $ssl_preread_server_name $grow_place_stream_backend {
    mail.ru 127.0.0.1:9443;
    default 127.0.0.1:8443;
}

server {
    listen 443;
    listen [::]:443;
    proxy_pass $grow_place_stream_backend;
    ssl_preread on;
    proxy_connect_timeout 10s;
    proxy_timeout 300s;
}
```

The live file also carries ports `18080` and `18443` for the surrounding Platforma ingress topology. Preserve those
blocks when editing the SNI map.

## Read-only preflight

Run on the target node before any change:

```bash
date -Is
sudo nginx -t
sudo ss -ltnp | grep -E ':443|:8443|:9443|:2443|:19091' || true
sudo docker ps --format '{{.Names}}|{{.Image}}|{{.Ports}}' | grep -E 'telemt|mtproto' || true
ip route get 149.154.175.100
ip route get 91.108.4.180
sudo awg show awg-telemt
```

Confirm the current Compose path, container name, config ownership/mode, SNI router, bridge subnets, AWG peer, and
timestamped rollback files before proceeding.

## Deploy or upgrade

For nn99 or the Hetzner duplicate:

```bash
scp -r deploy/mtproto/image deploy/mtproto/docker-compose.yml <ssh-host>:/opt/telemt/
ssh <ssh-host> 'cd /opt/telemt && sudo docker compose build telemt && sudo docker compose config'
ssh <ssh-host> 'cd /opt/telemt && sudo docker compose up -d --no-deps telemt'
```

For Platforma, copy `image/` plus `docker-compose.platforma.yml` into `/var/www/env/mtproto/`, retaining its live
filename `docker-compose.yml`. Preserve the existing secret config and `tlsfront/` directory. Before replacement, keep
the stopped old container under a timestamped name such as `grow-place-mtproto-before-<version>-<timestamp>` so it can
be renamed and restarted immediately.

An image-only rollout must not modify nginx, AWG, host routes, or firewall rules.

## Verification

### Container and control plane

```bash
container=<telemt-proxy-or-grow-place-mtproto>
sudo docker ps --filter "name=$container"
sudo docker logs --tail 150 "$container"
sudo docker exec "$container" telemt healthcheck /etc/telemt.toml --mode ready
sudo nginx -t
```

Query runtime endpoints inside the container network namespace so the host-to-bridge source address cannot trip the
API whitelist:

```bash
pid=$(sudo docker inspect -f '{{.State.Pid}}' "$container")
for path in \
  /v1/runtime/gates \
  /v1/runtime/initialization \
  /v1/runtime/me_pool_state \
  /v1/runtime/me-selftest \
  /v1/stats/summary; do
  sudo nsenter -t "$pid" -n curl -fsS "http://127.0.0.1:9091$path"
  echo
done
```

Require ready initialization, no degraded state, healthy/fresh Middle-End writers, zero persistent KDF errors, the
expected `local_addr_nat`, and increasing client/traffic counters.

### Real path

- Verify the public web domains still complete TLS and return their expected HTTP status.
- Test the proxy from a Telegram client with auto-switch disabled: text, images, video, and a large public channel.
- Run a no-account FakeTLS plus MTProto `req_pq_multi -> resPQ` probe. TCP/FakeTLS or `/v1/health/ready` alone is not
  sufficient; the August/September 2026 failures left those shallow checks green while Middle-End writers degraded.

The authoritative nn99 canary is `domovoy/deploy/mtproto-watchdog/`. Firebat runs it every minute against
`connect.nn99.ru`; three consecutive failures capture evidence and may restart only nn99's `telemt-proxy`, with a
15-minute cooldown and at most two restart attempts per hour.

## Diagnosis and recovery

- `proxy unavailable`: verify public host/DNS, saved client secret, FakeTLS domain, and nginx SNI mapping.
- Telegram error `-444` or “incorrectly configured”: inspect Middle-End readiness, NAT identity, and fallback state; it
  is not merely a link-format error.
- ME handshake failure with the node's direct public IP: selective routing split the advertised and observed NAT
  identity. Verify `middle_proxy_nat_ip` against the AWG exit.
- Large-channel media failure or non-standard DC fallback: verify DC overrides `201` and `203`.
- Telegram timeout: verify both Telegram test routes use `awg-telemt`, then inspect peer handshakes and counters.
- `unknown directive stream`: stop. Verify the installed nginx stream module and current top-level include; do not
  improvise package changes on a production node.

Capture logs, runtime endpoints, listeners, routes, AWG state, and traffic counters before restarting Telemt. A restart
destroys the volatile writer/session state needed for diagnosis.

## Rollback

- Restore the exact timestamped Compose/config backup for that node.
- For a Platforma image upgrade, remove the failed replacement, rename the retained pre-upgrade container back to
  `grow-place-mtproto`, and start it.
- For nn99/Hetzner, restore the Compose backup and run `docker compose up -d --no-deps telemt`.
- Restore nginx only when nginx was part of the change; validate with `nginx -t` before reload.
- Re-run the full public FakeTLS + `resPQ` probe and website TLS checks after rollback.

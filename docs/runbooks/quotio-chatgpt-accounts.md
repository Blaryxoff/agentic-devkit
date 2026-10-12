# Quotio ChatGPT account routing on Hetzner

This runbook covers two CLIProxyAPI instances on Hetzner. The original instance serves Firebat and Ugoos at `quotio.jzazik.com`. The second has its own panel and client endpoint at `quotio.place-fit.com`; it is reserved for a separate ChatGPT account and future boxes. Client API keys authorize access to a proxy; each proxy's OAuth directory determines which ChatGPT subscription handles requests. Keep API keys, management keys, and OAuth JSON files out of Git.

Last checked on **2026-10-12**. The second proxy, panel, TLS certificate, client key, and new ChatGPT account are active. Its model catalog responds successfully. The original route switch remains off.

## Live layout

| Purpose | Existing account | New account |
|---|---|---|
| Client base URL | `https://quotio.jzazik.com/v1` | `https://quotio.place-fit.com/v1` |
| Management panel | `https://quotio.jzazik.com/management.html` | `https://quotio.place-fit.com/management.html` |
| Service | `cliproxyapi.service` | `cliproxyapi-secondary.service` |
| Local listener | `127.0.0.1:8317` | `127.0.0.1:8318` |
| Config | `/etc/cliproxyapi/config.yaml` | `/etc/cliproxyapi/secondary.yaml` |
| OAuth directory | `/var/lib/cliproxyapi` | `/var/lib/cliproxyapi-secondary` |

The Nginx files are `/etc/nginx/sites-enabled/quotio.jzazik.com` and `/etc/nginx/sites-enabled/quotio.place-fit.com`. The second domain reaches only the second proxy. The older `https://quotio.jzazik.com/secondary/v1` path remains an alias for its client API. The second config has its own client key and also accepts the existing client key so the server switch can route current clients to it. The OAuth directories remain separate. Beget has an explicit A record for `quotio.place-fit.com` pointing to `95.217.0.87`; Certbot renews its certificate using `/var/www/letsencrypt` and reloads Nginx after renewal.

## Open the second management panel

Visit `https://quotio.place-fit.com/management.html`. The page uses the same HTTP Basic Auth credentials as the original panel, but its CLIProxyAPI management key is separate. The key is stored on Hetzner in `/etc/cliproxyapi/secondary-management-key` (root-only). If prompted for the management key, retrieve it privately with `ssh root@quotio.jzazik.com 'cat /etc/cliproxyapi/secondary-management-key'` and enter it in the second panel. Do not paste it into chat or a repository. The panel and management API are active for the new account.

The two panels manage their respective CLIProxyAPI instances. The `quotio-account-route` switch below is an Nginx routing change and is operated with the server command, not either panel.

## Reauthorize the new ChatGPT account

The new account is already authorized. Repeat these steps only when its OAuth credential needs replacing. Run commands on Hetzner as root, for example after `ssh root@quotio.jzazik.com`. Do not use the original config or copy its OAuth JSON file.

1. Confirm the original route is still selected:

   ```bash
   /usr/local/sbin/quotio-account-route status
   ```

2. Start device authentication against the **second** config:

   ```bash
   /usr/local/bin/cli-proxy-api -codex-device-login -no-browser -config /etc/cliproxyapi/secondary.yaml
   ```

3. Open the URL printed by the command, currently `https://auth.openai.com/codex/device`. Sign in to the **new** ChatGPT account, enter the freshly printed device code, and wait for the CLI to report success. If the browser is already signed in to the old account, switch accounts in the browser before entering the code. A code from an earlier attempt is not reusable.

4. Check that the OAuth identity is distinct. This prints account metadata only, not tokens:

   ```bash
   python3 - <<'PY'
   import json
   from pathlib import Path

   for directory in (Path('/var/lib/cliproxyapi'), Path('/var/lib/cliproxyapi-secondary')):
       for path in directory.glob('codex*.json'):
           account = json.loads(path.read_text())
           print(directory, account.get('email'), account.get('account_id'))
   PY
   ```

   The secondary directory must contain the expected new account ID. If it contains the old account, stop here and repeat the login with the correct browser account. Do not enable the route switch.

5. Restart only the second service, then check its model catalog using its client key without printing the key:

   ```bash
   systemctl restart cliproxyapi-secondary.service
   python3 - <<'PY'
   import json
   import urllib.request
   import yaml

   config = yaml.safe_load(open('/etc/cliproxyapi/secondary.yaml'))
   request = urllib.request.Request(
       'https://quotio.place-fit.com/v1/models',
       headers={'Authorization': 'Bearer ' + config['api-keys'][0]},
   )
   with urllib.request.urlopen(request, timeout=10) as response:
       print(response.status, len(json.load(response).get('data', [])), 'models')
   PY
   ```

   Expect HTTP `200` and at least one model. An unauthenticated request to the same URL must return `401`.

## Connect future boxes

Point each new box's Codex client at `https://quotio.place-fit.com/v1` and give it the **first** `api-keys` entry from `/etc/cliproxyapi/secondary.yaml` as `OPENAI_API_KEY`. Transfer the key through a private channel or install it directly on the box; do not put it in a repository or a command argument. Do not copy either server's OAuth JSON file to a client.

Use the same provider shape as the existing Firebat client, changing only the base URL:

```toml
model_provider = "cliproxyapi"

[model_providers.cliproxyapi]
name = "cliproxyapi"
base_url = "https://quotio.place-fit.com/v1"
env_key = "OPENAI_API_KEY"
```

Set `OPENAI_API_KEY` in that box's private runtime environment to the new client key. Check the installed Codex version's [CLIProxyAPI client guide](https://github.com/router-for-me/CLIProxyAPIDocs/blob/main/docs/en/agent-client/codex.md) for additional settings it requires, such as `model_catalog_url` on newer releases. Verify the box can list models and complete one small request before treating it as ready.

## Allow existing boxes to use the new quota

The Hetzner switch changes the inference backend for **all** existing clients of `https://quotio.jzazik.com/v1`, including Firebat and Ugoos. It does not pool quotas. The future boxes on `https://quotio.place-fit.com/v1` always use the new account.

```bash
/usr/local/sbin/quotio-account-route status  # Show current route
/usr/local/sbin/quotio-account-route on      # Existing boxes use the new account
/usr/local/sbin/quotio-account-route off     # Existing boxes use the original account
```

`on` refuses to run until the second proxy has a Codex OAuth file and a nonempty model catalog. Before enabling it, confirm that the new account offers the models current clients need. The existing `/v1/models` response is a static catalog and does not change with this switch. Restart active Codex sessions after switching so new requests start on the selected account. If the new account fails, run `off`; it restores the original route without changing either OAuth directory. Check `nginx -t` and `systemctl is-active cliproxyapi.service cliproxyapi-secondary.service nginx.service` after a routing change.

## Latest Luna alias

The secondary proxy exposes `luna-latest` for Platforma. CLIProxyAPI aliases point to a specific model, so `/usr/local/sbin/quotio-luna-latest-refresh` checks the secondary catalog daily and advances the alias to the highest versioned `gpt-*-luna` model. The script is stored at `bin/quotio-luna-latest-refresh` in this repository. `quotio-luna-latest-refresh.timer` runs it as root on Hetzner; it leaves the alias alone if the catalog is empty, the alias is missing, or the candidate is older. On 2026-10-12 the alias points to `gpt-6-luna`.

To check immediately, run `systemctl start quotio-luna-latest-refresh.service`, then `journalctl -u quotio-luna-latest-refresh.service -n 10 --no-pager` and inspect the `luna-latest` entry in the secondary panel. This timer only changes the second proxy and does not change the Firebat/Ugoos route switch.

To restore the updater on a rebuilt Hetzner host, install `bin/quotio-luna-latest-refresh` as `/usr/local/sbin/quotio-luna-latest-refresh` with mode `700`, then create these systemd units and enable the timer:

```ini
# /etc/systemd/system/quotio-luna-latest-refresh.service
[Unit]
Description=Advance secondary Quotio Luna alias when a newer model is available
After=cliproxyapi-secondary.service

[Service]
Type=oneshot
ExecStart=/usr/local/sbin/quotio-luna-latest-refresh
```

```ini
# /etc/systemd/system/quotio-luna-latest-refresh.timer
[Unit]
Description=Check secondary Quotio for the latest Luna daily

[Timer]
OnCalendar=daily
Persistent=true
Unit=quotio-luna-latest-refresh.service

[Install]
WantedBy=timers.target
```

Run `systemctl daemon-reload && systemctl enable --now quotio-luna-latest-refresh.timer` and start the service once to verify it. The script needs Python 3 and PyYAML.

## Platforma

Platforma production uses the separate secondary client endpoint `https://quotio.place-fit.com/v1`. Its private `platforma.env` needs `OPENAI_BASE_URL=https://quotio.place-fit.com/v1`, `OPENAI_MODEL=luna-latest`, `OPENAI_MODELS=luna-latest`, and `OPENAI_API_KEY` set to the first client key in `/etc/cliproxyapi/secondary.yaml`. The key must stay outside Git. The application release must include the `luna-latest` model catalog/rate migration before this env change. On 2026-10-12 this was deployed as Grow Place `f91f1ed5baed` on the active `platforma-secondary` node; the production container returned HTTP 200 from Quotio with `gpt-6-luna`. This is independent of the Firebat/Ugoos switch; keep that switch off unless those machines should temporarily use the new quota.

Production env sync normally copies `/var/www/env/platforma.env` from the primary Platforma node to the secondary node. The primary node was unreachable by SSH on 2026-10-12 and is absent from the NLB target group, so only the secondary node received the new environment. Update the primary env before restoring normal two-node deployment so it cannot overwrite the secondary node's new endpoint and key. The secondary node keeps the old env in a mode-600 `platforma.env.before-quotio-*` backup for rollback.

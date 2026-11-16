#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

for adapter in codex claude cursor grok; do
  project="$TMP_DIR/$adapter project"
  mkdir -p "$project/.devkit" "$project/.cursor" "$project/.codex" "$project/.grok" "$TMP_DIR/home"
  printf '%s\n' '{"version":1,"enabled":[]}' > "$project/.devkit/toolkit.json"
  cat > "$project/.mcp.json" <<'JSON'
{
  "keepCanonical": true,
  "mcpServers": {
    "custom.project": {"type":"stdio","command":"php","args":["artisan","custom:mcp"],"env":{"TOKEN":"fixture secret"}},
    "remote": {"type":"http","url":"https://example.test/mcp","headers":{"Authorization":"Bearer fixture secret","X-Quoted":"a \"quote\""}},
    "chrome-devtools": {"command":"lazy-mcp-wrapper","args":["--browserUrl=http://localhost:9222"]}
  }
}
JSON
  cat > "$project/.cursor/mcp.json" <<'JSON'
{"keepCursor":true,"mcpServers":{"cursor-only":{"command":"node","args":["path with spaces/server.js"]},"custom.project":{"command":"wrong","args":["--wrong"]}}}
JSON
  cat > "$project/.codex/config.toml" <<'TOML'
model = "keep-model"

[mcp_servers."custom.project"]
command = "old"
args = ["stale"]
startup_timeout_sec = 45
env_vars = ["PASSTHROUGH"]

[mcp_servers."custom.project".tools.read]
approval_mode = "approve"

[mcp_servers.remote]
url = "https://example.test/mcp"
bearer_token_env_var = "PRIVATE_TOKEN"
http_headers_helper = { command = "auth-helper", args = ["--private"] }
enabled_tools = ["read"]

[mcp_servers.codex_only]
command = "keep-codex"

[features]
keep_feature = true
TOML
  cat > "$project/.grok/config.toml" <<'TOML'
model = "keep-grok-model"
[compat.claude]
mcps = true
skills = true
[mcp_servers.remote]
url = "https://example.test/mcp"
enabled = false
[mcp_servers.grok_only]
command = "keep-grok"
TOML
  HOME="$TMP_DIR/home" DEVKIT_PROJECT_ROOT="$project" bash "$ROOT/adapters/$adapter/generate" > "$TMP_DIR/output" 2>&1 || {
    tail -10 "$TMP_DIR/output" >&2
    exit 1
  }
  python3 - "$project" <<'PY'
import json
from pathlib import Path
import sys
import tomllib

root = Path(sys.argv[1]).resolve()
canonical = json.loads((root / '.mcp.json').read_text())
cursor = json.loads((root / '.cursor/mcp.json').read_text())
assert cursor['mcpServers'] == canonical['mcpServers'], 'project MCP catalogues differ'
assert canonical['keepCanonical'] and cursor['keepCursor'], 'top-level JSON metadata lost'
servers = canonical['mcpServers']
assert servers['custom.project']['command'] == 'php', 'canonical conflict did not win'
assert servers['custom.project']['cwd'] == str(root), 'stdio project cwd missing'
assert servers['cursor-only']['args'] == ['path with spaces/server.js'], 'Cursor-only server lost'
assert servers['chrome-devtools']['command'] == 'lazy-mcp-wrapper'
assert servers['chrome-devtools']['args'] == ['--browserUrl=http://localhost:9222'], 'custom Chrome launcher changed'
for client, header_key in [('codex', 'http_headers'), ('grok', 'headers')]:
    config = tomllib.loads((root / f'.{client}/config.toml').read_text())
    native = config['mcp_servers']
    assert set(servers).issubset(native), f'{client} missing project MCP servers'
    assert native['custom.project']['command'] == 'php'
    assert native['custom.project']['env'] == {'TOKEN': 'fixture secret'}
    assert native['remote'][header_key] == servers['remote']['headers']
    assert native[f'{client}_only']['command'] == f'keep-{client}'
    assert config['model'] == ('keep-model' if client == 'codex' else 'keep-grok-model')
    if client == 'codex':
        assert native['custom.project']['cwd'] == str(root)
        assert native['custom.project']['startup_timeout_sec'] == 45
        assert native['custom.project']['tools']['read']['approval_mode'] == 'approve'
        assert native['custom.project']['env_vars'] == ['PASSTHROUGH']
        assert native['remote']['bearer_token_env_var'] == 'PRIVATE_TOKEN'
        assert native['remote']['http_headers_helper'] == {'command': 'auth-helper', 'args': ['--private']}
        assert native['remote']['enabled_tools'] == ['read']
        assert config['features']['keep_feature']
    else:
        assert config['compat']['claude'] == {'mcps': False, 'skills': True}
        assert config['compat']['cursor']['mcps'] is False
        assert native['remote']['enabled'] is True, 'canonical active server remained disabled'
PY
  if grep -q 'fixture secret' "$TMP_DIR/output"; then
    echo 'FAIL: MCP credentials leaked to adapter output' >&2
    exit 1
  fi
  cp "$project/.mcp.json" "$TMP_DIR/canonical.before"
  cp "$project/.codex/config.toml" "$TMP_DIR/codex.before"
  cp "$project/.grok/config.toml" "$TMP_DIR/grok.before"
  DEVKIT_PROJECT_ROOT="$project" bash -c 'source "$1/adapters/_lib/resolve.sh"; source "$1/adapters/_lib/mcp.sh"; sync_project_mcp_servers "{}" ""' _ "$ROOT" >/dev/null
  cmp "$project/.mcp.json" "$TMP_DIR/canonical.before"
  cmp "$project/.codex/config.toml" "$TMP_DIR/codex.before"
  cmp "$project/.grok/config.toml" "$TMP_DIR/grok.before"
done

project="$TMP_DIR/defaults project"
mkdir -p "$project/.cursor" "$TMP_DIR/plugin"
printf '%s\n' '{"mcpServers":{"default-only":{"command":"plugin-default"},"conflict":{"command":"plugin-conflict"},"chrome-devtools":{"command":"npx","args":["-y","chrome-devtools-mcp@latest","--experimentalPageIdRouting"]}}}' > "$TMP_DIR/plugin/.mcp.json"
printf '%s\n' '{"mcpServers":{"conflict":{"command":"cursor-conflict"}}}' > "$project/.cursor/mcp.json"
DEVKIT_PROJECT_ROOT="$project" bash -c '
  source "$1/adapters/_lib/resolve.sh"
  source "$1/adapters/_lib/mcp.sh"
  index=$(jq -n --arg dir "$2" '\''{fixture:{_dir:$dir,paths:{mcpServers:".mcp.json"}}}'\'')
  sync_project_mcp_servers "$index" fixture
' _ "$ROOT" "$TMP_DIR/plugin" >/dev/null
jq -e '.mcpServers["default-only"].command == "plugin-default" and .mcpServers.conflict.command == "cursor-conflict" and (.mcpServers["chrome-devtools"].args | index("--isolated"))' "$project/.mcp.json" >/dev/null
bash -c '
  source "$1/adapters/_lib/mcp.sh"
  apply_chrome_devtools_profile '\''{"chrome-devtools":{"command":"npx","args":["-y","chrome-devtools-mcp@latest","--browserUrl=http://localhost:9222","--headless=false"]}}'\''
' _ "$ROOT" | jq -e '."chrome-devtools".args == ["-y","chrome-devtools-mcp@latest","--browserUrl=http://localhost:9222","--headless=false"]' >/dev/null

python3 - "$ROOT" "$TMP_DIR/private headers" <<'PY'
import json
from pathlib import Path
import subprocess
import sys
import tomllib

helper = Path(sys.argv[1]) / 'adapters/_lib/mcp.py'
root = Path(sys.argv[2])
(root / '.cursor').mkdir(parents=True)
(root / '.mcp.json').write_text(json.dumps({'mcpServers': {'public': {'type': 'http', 'url': 'https://example.test/public', 'headers': {'X-MCP-Tools': 'docs-only'}}}}))
(root / '.cursor/mcp.json').write_text(json.dumps({'mcpServers': {
    'private': {'type': 'http', 'url': 'https://example.test/private', 'headers': {'Authorization': 'Bearer private fixture'}},
    'public': {'type': 'http', 'url': 'https://example.test/public', 'headers': {'Authorization': 'Bearer private fixture'}},
}}))
def sync():
    subprocess.run([sys.executable, str(helper), str(root)], input='{}', text=True, capture_output=True, check=True)
sync()
canonical = json.loads((root / '.mcp.json').read_text())
assert 'private fixture' not in json.dumps(canonical), 'Cursor credentials copied into canonical JSON'
assert 'headers' not in canonical['mcpServers']['private']
assert canonical['mcpServers']['public']['headers'] == {'X-MCP-Tools': 'docs-only'}
cursor = json.loads((root / '.cursor/mcp.json').read_text())
assert cursor['mcpServers']['private']['headers']['Authorization'] == 'Bearer private fixture'
assert cursor['mcpServers']['public']['headers'] == {'Authorization': 'Bearer private fixture', 'X-MCP-Tools': 'docs-only'}
for client, header_key in [('codex', 'http_headers'), ('grok', 'headers')]:
    native = tomllib.loads((root / f'.{client}/config.toml').read_text())['mcp_servers']
    assert native['private'][header_key]['Authorization'] == 'Bearer private fixture'
    assert native['public'][header_key]['X-MCP-Tools'] == 'docs-only'
paths = [root / path for path in ['.mcp.json', '.cursor/mcp.json', '.codex/config.toml', '.grok/config.toml']]
snapshot = [path.read_text() for path in paths]
sync()
assert snapshot == [path.read_text() for path in paths], 'private-header sync is not idempotent'
canonical['mcpServers']['private']['url'] = 'https://other.test/private'
(root / '.mcp.json').write_text(json.dumps(canonical))
sync()
cursor = json.loads((root / '.cursor/mcp.json').read_text())
assert 'headers' not in cursor['mcpServers']['private'], 'Cursor credentials followed a changed URL'
for client, header_key in [('codex', 'http_headers'), ('grok', 'headers')]:
    native = tomllib.loads((root / f'.{client}/config.toml').read_text())['mcp_servers']['private']
    assert header_key not in native, 'native credentials followed a changed URL'
PY

project="$TMP_DIR/transport change"
mkdir -p "$project/.codex" "$project/.grok"
printf '%s\n' '{"mcpServers":{"changed":{"command":"php","args":["artisan","custom:mcp"]}}}' > "$project/.mcp.json"
cat > "$project/.codex/config.toml" <<'TOML'
model = "keep-model"
[mcp_servers.changed]
url = "https://example.test/mcp"
http_headers = { Authorization = "fixture secret" }
env_http_headers = { "X-Token" = "PRIVATE_TOKEN" }
http_headers_helper = { command = "auth-helper" }
bearer_token_env_var = "PRIVATE_TOKEN"
auth = "oauth"
enabled_tools = ["read"]
[mcp_servers.changed.tools.read]
approval_mode = "approve"
TOML
cat > "$project/.grok/config.toml" <<'TOML'
model = "keep-model"
[mcp_servers.changed]
url = "https://example.test/mcp"
headers = { Authorization = "fixture secret" }
enabled_tools = ["read"]
TOML
DEVKIT_PROJECT_ROOT="$project" bash -c 'source "$1/adapters/_lib/resolve.sh"; source "$1/adapters/_lib/mcp.sh"; sync_project_mcp_servers "{}" ""' _ "$ROOT" >/dev/null
python3 - "$project" <<'PY'
from pathlib import Path
import sys
import tomllib

root = Path(sys.argv[1])
for client in ('codex', 'grok'):
    config = tomllib.loads((root / f'.{client}/config.toml').read_text())
    server = config['mcp_servers']['changed']
    assert server['command'] == 'php' and server['args'] == ['artisan', 'custom:mcp']
    assert not {'url', 'headers', 'http_headers', 'env_http_headers', 'http_headers_helper', 'bearer_token_env_var', 'auth'} & server.keys(), 'HTTP-only native transport fields survived a switch to stdio'
    assert config['model'] == 'keep-model' and server['enabled_tools'] == ['read']
    if client == 'codex':
        assert server['tools']['read']['approval_mode'] == 'approve'
PY

for failure in malformed disabled unsupported inline; do
  project="$TMP_DIR/$failure project"
  mkdir -p "$project/.cursor" "$project/.codex"
  printf '%s\n' '{"mcpServers":{"test":{"command":"keep"}}}' > "$project/.mcp.json"
  printf '%s\n' '{"keepCursor":true}' > "$project/.cursor/mcp.json"
  case "$failure" in
    malformed) printf '%s\n' 'invalid = ["fixture secret"' > "$project/.codex/config.toml" ;;
    disabled) printf '%s\n' '{"mcpServers":{"test":{"command":"keep","disabled":true}}}' > "$project/.mcp.json" ;;
    unsupported) printf '%s\n' '{"mcpServers":{"test":{"type":"sse","url":"https://example.test"}}}' > "$project/.mcp.json" ;;
    inline) printf '%s\n' 'mcp_servers = { test = { command = "keep" } }' > "$project/.codex/config.toml" ;;
  esac
  cp "$project/.mcp.json" "$TMP_DIR/canonical.before"
  cp "$project/.cursor/mcp.json" "$TMP_DIR/cursor.before"
  if DEVKIT_PROJECT_ROOT="$project" bash -c 'source "$1/adapters/_lib/resolve.sh"; source "$1/adapters/_lib/mcp.sh"; sync_project_mcp_servers "{}" ""' _ "$ROOT" > "$TMP_DIR/output" 2>&1; then
    echo "FAIL: accepted $failure MCP configuration" >&2
    exit 1
  fi
  cmp "$project/.mcp.json" "$TMP_DIR/canonical.before"
  cmp "$project/.cursor/mcp.json" "$TMP_DIR/cursor.before"
  if grep -q 'fixture secret' "$TMP_DIR/output"; then
    echo 'FAIL: invalid MCP configuration leaked credentials' >&2
    exit 1
  fi
done

project="$TMP_DIR/laravel dependencies"
mkdir -p "$project"
DEVKIT_PROJECT_ROOT="$project" bash -c '
  source "$1/adapters/_lib/resolve.sh"
  source "$1/adapters/_lib/mcp.sh"
  index=$(_build_plugin_index)
  merge_plugin_mcp_servers "$index" "devkit-laravel" | jq -e '\''has("laravel-boost") | not'\'' >/dev/null
  mkdir -p "$PROJECT_ROOT/vendor/laravel/boost"
  merge_plugin_mcp_servers "$index" "devkit-laravel" | jq -e '\''has("laravel-boost")'\'' >/dev/null
' _ "$ROOT"

if [ -n "${DEVKIT_MCP_SSE_PROJECT:-}" ]; then
  node "$ROOT/tests/mcp-sse.mjs" "$DEVKIT_MCP_SSE_PROJECT"
fi

echo 'mcp-parity: project catalogues match across all adapters'

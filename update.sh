#!/usr/bin/env bash
# Updates vendored plugin skills from upstream sources.
# Usage: ./update.sh [plugin-name]
#   ./update.sh          — update all registered plugins
#   ./update.sh css      — update only the css plugin

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TMP_DIR="$(mktemp -d)"
cleanup() { rm -rf "$TMP_DIR"; }
trap cleanup EXIT

# ---------------------------------------------------------------------------
# Plugin registry
# Each entry: name|zip_url|target_dir_relative_to_repo|inner_path_in_zip
# inner_path_in_zip is the directory inside the zip to copy from.
# ---------------------------------------------------------------------------
PLUGINS=(
  "css|https://css.dev/downloads/css-dev-skills.zip|plugins/css/skills|skills"
)

update_plugin() {
  local name="$1" url="$2" target="$3" inner="$4"
  local zip="$TMP_DIR/${name}.zip"
  local extract="$TMP_DIR/${name}"

  echo "[$name] Downloading from $url …"
  curl -fsSL -o "$zip" "$url"

  echo "[$name] Extracting…"
  mkdir -p "$extract"
  unzip -qo "$zip" -d "$extract"

  echo "[$name] Replacing $target …"
  rm -rf "$REPO_DIR/$target"
  cp -R "$extract/$inner" "$REPO_DIR/$target"

  echo "[$name] Done."
}

filter="${1:-}"

updated=0
for entry in "${PLUGINS[@]}"; do
  IFS='|' read -r name url target inner <<< "$entry"
  if [[ -n "$filter" && "$filter" != "$name" ]]; then
    continue
  fi
  update_plugin "$name" "$url" "$target" "$inner"
  ((updated++))
done

if [[ "$updated" -eq 0 && -n "$filter" ]]; then
  echo "Unknown plugin: $filter"
  echo "Available: $(printf '%s\n' "${PLUGINS[@]}" | cut -d'|' -f1 | tr '\n' ' ')"
  exit 1
fi

echo ""
echo "All done. $updated plugin(s) updated."

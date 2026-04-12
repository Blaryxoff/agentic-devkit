#!/usr/bin/env bash
# Fetches the latest css.dev skills and replaces the local copy.
# Usage: ./update.sh
# Upstream: https://css.dev/downloads/css-dev-skills.zip

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ZIP_URL="https://css.dev/downloads/css-dev-skills.zip"
TMP_DIR="$(mktemp -d)"

cleanup() { rm -rf "$TMP_DIR"; }
trap cleanup EXIT

echo "Downloading css.dev skills…"
curl -fsSL -o "$TMP_DIR/css-dev-skills.zip" "$ZIP_URL"

echo "Extracting…"
unzip -qo "$TMP_DIR/css-dev-skills.zip" -d "$TMP_DIR/extracted"

echo "Replacing skills/…"
rm -rf "$SCRIPT_DIR/skills"
cp -R "$TMP_DIR/extracted/skills" "$SCRIPT_DIR/skills"

echo "Done. Skills updated from upstream."

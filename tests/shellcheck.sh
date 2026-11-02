#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if ! command -v shellcheck >/dev/null 2>&1; then
  echo "SKIP: shellcheck not installed"
  exit 0
fi

files=()
while IFS= read -r -d '' path; do
  [ -f "$ROOT/$path" ] || continue
  case "$path" in
    *.sh) files+=("$ROOT/$path") ;;
    *) head -n 1 "$ROOT/$path" | grep -qE '^#!.*(/|env )(ba)?sh([[:space:]]|$)' && files+=("$ROOT/$path") ;;
  esac
done < <(git -C "$ROOT" ls-files -z -- '*.sh' bin adapters)

[ "${#files[@]}" -gt 0 ] || { echo "FAIL: no shell scripts found" >&2; exit 1; }
shellcheck -S warning "${files[@]}"
echo "shellcheck: ${#files[@]} scripts clean"

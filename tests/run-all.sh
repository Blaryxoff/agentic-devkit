#!/usr/bin/env bash
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPTS=(
  coder-gate.sh
  codex-adapter.sh
  comment-gate.sh
  context-efficiency.sh
  nontech.sh
  output-style.sh
)

failures=()
for script in "${SCRIPTS[@]}"; do
  echo "=== $script ==="
  if bash "$ROOT/tests/$script"; then
    echo "PASS: $script"
  else
    echo "FAIL: $script"
    failures+=("$script")
  fi
  echo
done

if [ "${#failures[@]}" -gt 0 ]; then
  echo "FAILED: ${failures[*]}"
  exit 1
fi

echo "All tests passed."

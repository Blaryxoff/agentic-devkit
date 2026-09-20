#!/usr/bin/env bash
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPTS=(
  claude-adapter.sh
  cleanup-visual-loop.sh
  coder-gate.sh
  codex-adapter.sh
  comment-gate.sh
  context-efficiency.sh
  devkit-update.sh
  estimate-skill.sh
  no-clobber.sh
  nontech.sh
  output-style.sh
  resolve.sh
  skill-eval.sh
  sprint-skill.sh
)

# One preflight for the whole suite. Individual scripts used to handle interpreter
# dependencies inconsistently — some fell back with a message, some imported blind —
# so a missing one surfaced as an unrelated assertion failure or, worse, as a check
# that silently searched nothing.
missing=()
for bin in jq git python3; do
  command -v "$bin" >/dev/null 2>&1 || missing+=("$bin")
done
if command -v python3 >/dev/null 2>&1; then
  python3 -c 'import tomllib' 2>/dev/null || missing+=("python3 tomllib (needs Python 3.11+)")
  python3 -c 'import yaml' 2>/dev/null || command -v ruby >/dev/null 2>&1 \
    || missing+=("PyYAML or ruby (YAML frontmatter parsing)")
fi
if [ "${#missing[@]}" -gt 0 ]; then
  printf 'MISSING DEPENDENCY: %s\n' "${missing[@]}" >&2
  exit 1
fi
command -v rg >/dev/null 2>&1 || echo "NOTE: ripgrep not found — conduct-loading checks fall back to grep"

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

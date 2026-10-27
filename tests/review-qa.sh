#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s "$ROOT/tests/evals/review-qa" -p 'test_*.py'
node --test "$ROOT/tests/evals/review-qa/test_touch_probe.mjs"

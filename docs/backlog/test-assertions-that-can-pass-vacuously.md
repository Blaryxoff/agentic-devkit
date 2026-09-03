---
worth: yes
where: tests/context-efficiency.sh:22
added: 2026-09-02
---
# Several test assertions pass without checking anything

- `broad_loading=$(rg … || true)` (`tests/context-efficiency.sh:22-26`) swallows exit 127 as well as rg's no-match
  exit 1. On a machine without ripgrep the variable is empty and the wholesale-conduct-loading check reports success
  having searched nothing. `rg` is undeclared anywhere.
- `assert_contains "$project/.gitignore" '.codex/'` (`tests/codex-adapter.sh:166`) is presence-only.
  `codex/generate` runs three times against the same project, so a regression in `ensure_gitignore_entry`'s
  normalization awk that appended on every run would leave three copies and every assertion would still pass. The
  substring is also satisfied by an unrelated `.codex/skills` line.
- `tests/comment-gate.sh:64` writes to the literal `/tmp/new-xyz.ts`. The `Write` branch of `comment-gate.sh:58-61`
  reads `$target` from disk to subtract pre-existing content; if that file exists on the host, its contents become
  baseline, the licence-header lines are subtracted, and the assertion still expects 0 — so the licence-exemption branch
  is never exercised.
- Interpreter dependencies are handled inconsistently: `context-efficiency.sh:52,67,79` falls back PyYAML → Ruby with a
  clear failure message, `nontech.sh:15-18` imports `yaml` with no guard, `codex-adapter.sh:98` requires `tomllib`
  (Python 3.11+) and `jq` with neither checked.

Fixes: guard on `command -v rg`; assert an exact line count on `.gitignore`; point the `Write` payloads at `$TMP_DIR`;
put one dependency preflight in the proposed runner.

A runner now exists (`tests/run-all.sh`, added 2026-09-03) — this item is about assertion quality inside the six
scripts it runs, not about the missing runner.

---
worth: yes
where: tests/coder-gate.sh:20
added: 2026-09-02
---
# `coder-gate`'s scratch-path exemption — rewritten three times in one day — has no test

`is_scratch_path()` (`plugins/core/hooks/coder-gate.sh:33-55`) decides whether an edit bypasses the coder gate entirely.
It carries non-obvious logic: absolute-path-only, symlink rejection on the final component, `pwd -P` canonicalization of
the parent, a `TMPDIR`/`/tmp`/`/private/tmp` prefix match, and an upward walk aborting on any `.git`.

All three most recent commits (`a49dae5`, `94e488f`, `1a14529`, all 2026-09-02) rewrote exactly this function and none
touched `tests/coder-gate.sh` (last changed `155d064`, 2026-08-07). Every case the test sends has an empty or absent
path field, so `is_scratch_path` is only ever called with `""` and returns on the first `case` arm. A regression making
the exemption too broad would silently disable the coder gate for real project files.

Fix: add cases under `$TMP_DIR` — a plain file (exempt), a file inside a `git init`'d subdir (blocked), a symlink whose
final component points at a tmp file (blocked, per `1a14529`), a relative path (blocked), a path under a real project
root (blocked). Assert on exit status *and* marker non-creation.

A runner now exists (`tests/run-all.sh`, added 2026-09-03) — this item is about a coverage gap inside one of the six
scripts it runs, not about the missing runner.

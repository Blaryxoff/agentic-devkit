---
worth: yes
where: bin/devkit-update:102
added: 2026-09-02
---
# A failed fetch is recorded as a successful "up to date" check and suppresses retries for 24h

Two compounding defects in the SessionStart auto-updater:

1. `git fetch` failure is discarded with `|| true` (`:65`). `after` is then computed from the stale local `origin/…` ref,
   matches `before`, and the hook prints `devkit: global up to date (<sha>)` — indistinguishable from a real success. An
   offline or auth-failing machine silently reports itself current.
2. `:102` stamps `.git/devkit-last-pull` unconditionally, including when `_pull_ff` returned 1 (fast-forward blocked, no
   `origin/HEAD`), so `--if-stale` stays silent for the next 24 hours.

The header at `:6-7` documents "Pull only if the last **successful** pull was > 24h ago" — the code does not implement
that. For a component whose whole job is delivering skill revisions to every dev container, the failure mode is silence.

Fix: report fetch failure and return 1; stamp only inside `if _pull_ff …; then`.

Not a defect: the "runs inside a dev checkout, reports `global up to date`" behaviour at `:15-16` matches
`CLAUDE.md:157-160`.

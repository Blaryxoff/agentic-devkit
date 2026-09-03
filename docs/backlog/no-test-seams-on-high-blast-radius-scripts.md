---
worth: later
where: bin/devkit-update:15
added: 2026-09-02
---
# The untested scripts lack the injectable seams that make `devkit-install` testable

`bin/devkit-install` is testable at all only because it reads `$HOME`, `$CODEX_HOME`, `$CURSOR_HOME` and
`$DEVKIT_HOME_DIR` (`:31`, `:100`, `:104`) — which is why it is the one large script with coverage. The untested scripts
have no equivalent:

- `bin/devkit-update:15-17` derives `DEVKIT_HOME` from `BASH_SOURCE` with no override, and always talks to the real
  `origin`.
- `bin/devkit-resolve:127,160` reads choices from an interactive `read -rp` with no non-interactive path.
- `bin/devkit-cleanup-visual-loop.mjs:66-71` has no `--dry-run`.

The coverage gap follows from the missing seams, not from oversight — so it will not close by writing tests alone.

`worth: later` because the fix is a design decision on each script's public surface (a `DEVKIT_HOME_DIR` override, a
`--preset=`/`--enable=` non-interactive path for `--init`, a `--dry-run`), and that decision should be made once the
runner exists and the priority order is clear.

Related: [[untested-install-and-resolve-paths]]. A runner now exists (`tests/run-all.sh`, added 2026-09-03).

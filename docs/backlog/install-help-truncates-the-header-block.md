---
worth: yes
where: bin/devkit-install:44
added: 2026-09-02
---
# `devkit-install --help` cuts off the header block

`sed -n '2,21p' "$0"` was written for a shorter banner. The comment header now runs through line 25, so `--help`
silently drops the paragraph explaining that the global clone is the source of truth and that `DEVKIT_HOME_DIR`
overrides the bootstrap location — the one piece a confused user most needs.

Fix: make the range self-maintaining — `sed -n '2,/^$/p' "$0" | sed 's/^# \{0,1\}//'`.

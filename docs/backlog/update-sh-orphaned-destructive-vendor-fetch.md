---
worth: yes
where: update.sh:36
added: 2026-09-02
---
# `update.sh` is an undocumented second updater that `rm -rf`s a tracked plugin after an unverified download

`update.sh` is a live but unwired downloader, entirely distinct from `bin/devkit-update`. A repo-wide grep returns only
its own header comments — no caller — and `CLAUDE.md` documents `bin/devkit-update` as the updater. Its single registry
entry is live (`https://css.dev/downloads/css-dev-skills.zip` → 200, application/zip).

Three problems compound:

- No checksum or signature on the archive; `curl -fsSL` also follows redirects to any host.
- Destroy-then-copy: `rm -rf "$REPO_DIR/plugins/css/skills"` runs *before* `cp -R`, so a zip missing its `skills/` top
  level leaves 9 git-tracked skill directories deleted.
- No provenance pinning at all.

It is also the only mechanism that refreshes `plugins/css/skills/*`, and it appears in no doc — so an agent editing a
`css-*` skill has no way to learn those edits are overwritten on the next vendor refresh.

Fix: delete it — the vendored css skills are tracked in git and updating them is a normal commit. If it stays: pin a
`sha256` per entry, verify before extracting, copy into a temp path and swap, and document it in `CLAUDE.md` "Common
Commands" as destructive.

Related: [[css-skills-drop-the-prefix-undocumented]].

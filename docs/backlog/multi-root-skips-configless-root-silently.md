---
worth: yes
where: adapters/_lib/resolve.sh:76
added: 2026-09-02
---
# A mistyped `--project` root is silently ignored, under-resolving the multi-repo union

`_collect_enabled` skips any root without `.devkit/toolkit.json` (`[ -f "$config" ] || continue`) and errors only when
*no* root has one. A typo in one of two `--project` flags yields a silently partial plugin set with exit 0 and no
diagnostic — the frontend half of a backend+frontend project just disappears from generated context. Reproduced with two
roots where the second had no config: the t1-only set printed and the command exited 0.

Fix: when more than one root is named, emit `WARN: no .devkit/toolkit.json at <root> — skipped` per configless root on
stderr, so the union is auditable.

---
worth: yes
where: examples/nuxt-css.json:4
added: 2026-09-02
---
# `examples/nuxt-css.json` enables no CSS plugin

The filename promises a nuxt+css preset; the file enables only `devkit-nuxt`, resolving to `core, frontend, nuxt, vue`
with no `devkit-css`. Its `enabled` array is byte-identical to the README's plain "Nuxt" example
(`README.md:102-113`).

`devkit-resolve --init` shows presets by filename plus their `enabled` list (`bin/devkit-resolve:108-112`), so the label
misleads at the exact point of selection.

Fix: add `"devkit-css"` to `enabled`, or rename the file to `nuxt.json`.

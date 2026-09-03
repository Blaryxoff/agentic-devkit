---
worth: yes
where: adapters/cursor/generate:114
added: 2026-09-02
---
# `devkit-css` has no `declare_globs` case, so its Cursor rule activates on `**/*`

`declare_globs` enumerates seven plugins; `devkit-css` (added later, `layer: styling` per
`plugins/css/plugin.json:5`) falls to the `*)` default of `**/*`. A CSS-only rule then attaches to PHP, JSON and every
other file, contrary to the scope-driven loading policy at `CLAUDE.md:83-89`.

Fix: `devkit-css) echo '**/*.css,**/*.scss,**/*.vue,**/*.html' ;;` alongside the `devkit-tailwind` case.

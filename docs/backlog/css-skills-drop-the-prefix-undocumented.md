---
worth: yes
where: CLAUDE.md:56
added: 2026-09-02
---
# Nine css skills drop the required prefix; the exception list names only `wrapup`

`CLAUDE.md:56-57` states skill names use the `devkit-` prefix, "Exception: … (currently `wrapup`)" — naming it as the
sole case. Nine skills carry unprefixed frontmatter names: `css-a11y`, `css-animate`, `css-audit`, `css-debug`,
`css-expert`, `css-layout`, `css-refactor`, `css-responsive`, `css-theme`. On Codex these are reached as `$css-expert`,
in an unnamespaced global namespace shared with third-party skills.

The exception is structural, not a one-off: they are vendored wholesale from css.dev by `update.sh`, so renaming them
would be undone on the next vendor refresh. A skill author reading the current rule would wrongly conclude they are a
violation to fix.

Fix: extend the exception to name the vendored `css-*` family and point at `update.sh` as the reason.

Related: [[update-sh-orphaned-destructive-vendor-fetch]], [[claude-md-layout-omits-css-plugin-and-tests]].

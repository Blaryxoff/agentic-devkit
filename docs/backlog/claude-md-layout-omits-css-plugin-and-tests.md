---
worth: yes
where: CLAUDE.md:19
added: 2026-09-02
---
# The Repository Layout tree omits the css plugin, the test suite, and three more paths

The layout tree stops at `tailwind/` and never lists `plugins/css/` — a real plugin with `plugin.json`, 9 skills and 2
conduct docs, listed in `README.md:82` and `:184`. The string `css` appears nowhere in `CLAUDE.md`. Also missing:
`tests/` (6 executable scripts, absent from `README.md` too), the per-plugin `hooks/` dirs
(`plugins/{core,laravel,nuxt}/hooks/`), `adapters/_lib/mcp.sh`, and `bin/devkit-cleanup-visual-loop.mjs`.

An agent using this tree to orient will not know the css plugin or the test suite exist — which is how the suite came to
be unreferenced anywhere.

Related: [[css-skills-drop-the-prefix-undocumented]]. `CLAUDE.md`'s Common Commands now lists `tests/run-all.sh`
(added 2026-09-03) — the layout tree itself is still missing `tests/`, `plugins/css/`, and the other paths listed above.

---
worth: yes
where: plugins/frontend/conduct/playwright-visual-regression.md:39
added: 2026-09-02
---
# Two shipped conduct docs carry private identifiers

`CLAUDE.md:120` forbids "Project-specific codenames, hostnames, brand names, or org-specific port numbers. This toolkit
is project-agnostic." Two violations ship to every consuming project:

- `plugins/frontend/conduct/playwright-visual-regression.md:39` — a config template comments "Required in unprivileged
  Firebat/Incus containers". `Firebat` is a private host codename; the rule it encodes (`--no-sandbox` in unprivileged
  containers) is generic. Fix: `// Required in unprivileged/rootless containers; omit where the Chrome sandbox works.`
- `plugins/core/conduct/docker-deployment.md:95` — the registry-namespace example is `` (e.g. `Blaryxoff`) ``, the
  maintainer's actual GitHub account. Every other identifier in that doc is generic (`<app>`, `$REMOTE`,
  `/var/www/<app>`). Fix: `` (e.g. `<github-org>`) ``.

Not a violation: the clone URLs at `README.md:17` and `MIGRATION.md:13` are the repo's own origin.

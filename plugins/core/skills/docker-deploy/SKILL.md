---
name: devkit-docker-deploy
description: bootstrap or audit a project's Docker / docker-compose production deployment against the org's docker-deployment conduct. Single-node prod+test is the default shape (Laravel + optional Nuxt + mysql + redis); multi-node fleets are an opt-in appendix. Use when starting a new dockerized service, hardening an existing one, or reviewing the docker setup of an existing project.
---

# Docker Deployment — Setup & Audit

> Paths like `plugins/<plugin>/conduct/…` resolve under the devkit clone root (`~/.claude/agentic-devkit` — this skill's symlink target), not the project root.

Use [`plugins/core/conduct/docker-deployment.md`](../../conduct/docker-deployment.md) as the source of truth. Load it
progressively by section; do not read the 1,000-line document wholesale.

Default to a single node with prod + test. Use the multi-node appendix only when the project actually has multiple app
nodes behind a load balancer.

## Mode

State one mode before proceeding:

- `setup` — scaffold a missing or stub deployment.
- `audit` — report findings without changing files.
- `harden` — apply prioritized fixes to an existing deployment.

If the mode is unclear, ask once.

## Grounding

1. Inspect the existing surface that is relevant and present:
   - `Dockerfile*`, `docker/`, compose files;
   - deploy scripts, `Makefile`, deployment workflows;
   - `docker/INFRASTRUCTURE.md` or `INFRASTRUCTURE.md`;
   - backup scheduling/configuration and environment examples.
2. Determine the topology: single app node, prod + test on one node, or real multi-node fleet.
3. Determine the stack and container set: Laravel only, Laravel + Nuxt SSR, or another shape.
4. Read conduct §13 for the compact baseline, then open only source sections needed by observed files or risks:

| Concern | Conduct section |
|---|---|
| Image stages, extensions, users, assets, tags, build memory | §1 |
| Volumes and asset shadowing | §2 |
| Shared logs and rotation | §3 |
| Ports, external networks, IMDS | §4 |
| Environment and secret distribution | §5 |
| Healthchecks and startup ordering | §6 |
| Deploy script, Makefile, workflows, rollback | §7 |
| TLS termination | §8 |
| Restarts, limits, read-only filesystems, docker.sock | §9 |
| Backup and restore | §10 |
| Operator documentation | §11 |
| Known anti-patterns | §12 |
| Multi-node-only mechanics | §14 |

Resolve material ambiguity through `plugins/core/conduct/clarification-protocol.md` in one concise round.

## Mandatory live check

When the serving host also runs `docker build` or `buildx build`, verify memory and swap live with
`ssh <build-host> 'swapon --show; free -h'` per §1.8. Empty swap on a memory-oversubscribed build host is critical.

## Setup

Work one conduct section at a time so only the current rules stay in context. Generate in dependency order:

1. PHP/FPM configuration and nginx configuration.
2. Entrypoint role dispatcher.
3. Backend image and optional frontend image (§1).
4. Compose services, leaf volumes, shared logs, healthchecks, port bindings, restart policy, and log caps (§§2–6, 9).
5. The single deploy script and `.deploy/compose.env` contract (§7.1–§7.4).
6. Canonical Makefile commands (§7.5).
7. Thin deployment/build workflows (§7.6–§7.7).
8. `docker/INFRASTRUCTURE.md` (§11).
9. Host bootstrap checklist: operator/deploy accounts, directories, environment file, TLS proxy, DNS, registry secrets,
   first image build, and test deploy.

Track these groups as tasks when the environment supports task tracking. Verify each generated layer before starting the
next.

## Audit

1. Walk conduct §13 and mark each applicable item `✅ ok`, `⚠️ partial`, or `❌ missing`.
2. Before reporting a partial/missing item, read its source section from the table above.
3. Every finding includes file:line evidence, failure mode, conduct section, and severity (`critical`, `important`,
   `nit`).
4. Pay special attention to:
   - deploy logic duplicated outside the deploy script (§7.1);
   - missing canonical operator commands or forbidden `docker compose restart` (§7.5, §7.8);
   - `public/build` or parent-directory volume shadowing (§§1.4, 2);
   - compose substitution running without sourced credentials (§5.2);
   - fragmented logs (§3);
   - build-on-serving hosts without swap (§1.8).
5. Group findings by severity, then conduct section. Use
   `plugins/core/conduct/review-findings-format.md` and end with at most three highest-leverage actions.

## Harden

Run the audit first, then fix in this order:

1. Data-loss and security gaps.
2. Mount safety and asset shadowing.
3. Environment handling and deploy-script correctness.
4. Operator commands and workflow gaps.
5. Observability and TLS robustness.
6. Cosmetic issues.

For production-affecting operations, provide the exact sequence and obtain confirmation before running it. Update
`docker/INFRASTRUCTURE.md` after every meaningful operational change.

## Verification and reporting

- Use `devkit-verify` for relevant shell, YAML, Dockerfile, and project checks.
- End with 3–6 summary bullets, one highest-leverage next step, and explicitly deferred gaps.
- Cite conduct section numbers; do not restate the conduct checklist in the report.

## Boundaries

- Do not recommend §14 fleet machinery for a single-node project.
- Respect a coherent non-canonical deployment instead of rewriting it solely to match the default.
- Never run destructive Docker operations such as volume removal or `docker compose down -v` without explicit
  per-command confirmation.
- Propose reusable missing rules for `docker-deployment.md`; do not encode one-off policy in a project.

# Git Workflow

This document defines git rules for Nuxt + TypeScript projects.

## Commits

Use Conventional Commits:

`<type>: <summary>`

Types:
- `feat`
- `fix`
- `refactor`
- `test`
- `docs`
- `chore`
- `ci`
- `perf`

Rules:
- imperative mood
- concise summary
- one logical change per commit

## Branches

Format:

`<type>/<short-description>`

Examples:
- `feat/catalog-query-sync`
- `fix/modal-scroll-lock`
- `refactor/extract-form-composable`

## Pull Requests

PR title follows commit format.

PR body should include:
- What changed
- Why
- How to verify
- Risks

## Pre-commit checks

Recommended order: `fmt → lint → typecheck → test → build`.

The **exact commands** live in the project's root `CLAUDE.md` / `AGENTS.md` (see `howto/project-test-rules.md` for the template). Test-execution policy (always / on-request / never) is defined there too — see [agent-test-restraint](../../core/conduct/agent-test-restraint.md).

If the project file is silent, fall back to the project `Makefile` or `package.json` scripts.

## Hygiene

- never commit secrets or `.env` files
- avoid unrelated file churn
- keep branch short-lived
- rebase on latest `master` before merge
- do not force-push shared protected branches

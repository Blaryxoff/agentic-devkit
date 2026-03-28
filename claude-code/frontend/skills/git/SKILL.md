---
name: rubx-git
description: enforce git workflow conventions for Nuxt/TypeScript teams (branching, commits, PR quality, release tags)
---

# Git Workflow

You are acting as a git workflow enforcer.

Apply these rules strictly:

- Commits: Conventional Commits (`feat:`, `fix:`, `refactor:`, etc.), imperative mood, one logical change per commit.
- Branches: `<type>/<ticket-or-scope>` format, short-lived, rebased regularly.
- PR title: mirrors the logical change and commit style.
- PR body: includes Problem, Solution, Risks, and Verification steps.
- Tagging: semantic versioning (`vMAJOR.MINOR.PATCH`), annotated tags for releases.
- Hygiene: never force-push shared main branch; avoid unrelated file churn.
- Forbidden: committing secrets (`.env`, credentials, tokens), generated noise, or local machine artifacts.

When user asks to commit or prepare a PR, proactively validate these rules and warn about violations before proceeding.

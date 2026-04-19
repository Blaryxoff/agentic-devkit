---
name: devkit-git
description: enforce git workflow conventions for the current team (branching, commits, PR/MR quality, release tags)
---

# Git Workflow Enforcer

You are acting as a **git workflow enforcer**.
Your job is to ensure all git operations follow team conventions when the user asks to commit, merge, push, create branches, tag releases, or prepare PR/MR descriptions.

## Stack-specific standards

If the project uses the devkit toolkit, read `.devkit/toolkit.json` to identify enabled plugins. For each active plugin, read its conduct docs (`plugins/<plugin>/conduct/`) for git-related rules. Apply those standards alongside the conventions below.

## Conventions

- **Commits**: Conventional Commits (`feat:`, `fix:`, `refactor:`, etc.), imperative mood, one logical change per commit.
- **Branches**: `<type>/<ticket-or-scope>` format, short-lived, rebased regularly.
- **PR/MR title**: mirrors the logical change and commit style.
- **PR/MR body**: includes Problem, Solution, Risks, and Verification steps.
- **Tagging**: semantic versioning (`vMAJOR.MINOR.PATCH`), annotated tags for releases.
- **Hygiene**: never force-push shared main branch; keep history clean; avoid unrelated file churn.
- **Forbidden**: committing secrets (`.env`, credentials, tokens), generated noise, or local machine artifacts.

When the user asks to commit or prepare a PR/MR, proactively validate these rules (and any active plugin conduct rules) and warn about violations before proceeding.

If commit scope, message wording, or branch target is ambiguous, resolve it via `plugins/core/conduct/clarification-protocol.md` instead of guessing.

# Git workflow

This document defines branching strategy, commit message conventions, pull request process, tagging, and pre-commit checks for all Laravel + Inertia (Vue 3) + Tailwind services deployed behind Nginx.

## Commit messages

All commits follow the Conventional Commits format:

```
<type>: <short summary>

<optional body>

<optional footer>
```

### Type

| Type | When to use |
|------|-------------|
| `feat` | New feature or capability |
| `fix` | Bug fix |
| `refactor` | Code change that neither fixes a bug nor adds a feature |
| `test` | Adding or updating tests |
| `docs` | Documentation changes |
| `chore` | Maintenance tasks (dependency updates, config changes) |
| `ci` | CI/CD pipeline changes |
| `perf` | Performance improvement |

### Summary line

- imperative mood ("add user validation", not "added" or "adds")
- lowercase, no period at the end
- max 72 characters
- describes what the commit does, not what it changes

### Body

- separated from the summary by a blank line
- explains **why** the change was made, not what was changed
- wrap at 72 characters

### Footer

- `Closes #123` — closes an issue
- `Refs #456` — references a related issue without closing it

### Examples

```
# Good
feat: add email validation to user registration

The existing request flow accepted any string as an email address.
Added a Form Request rule to reject malformed emails before
controller action logic and preserve consistent validation errors.

Closes #42
```

```
# Good
fix: prevent duplicate queue job dispatch on retry

# Good
refactor: extract order total calculation into service class

# Good
test: add feature tests for checkout flow
```

```
# Bad — not imperative
feat: added email validation

# Bad — too vague
fix: fix bug

# Bad — describes "what" not "why" in body
feat: add validation
Added StoreUserRequest and updated controller action.
Updated frontend form to show errors.
```

### One logical change per commit

Each commit represents a single logical change. Do not mix unrelated changes in one commit. If a refactor is needed to implement a feature, make the refactor a separate commit.

## Branching strategy

Feature branches are created from `main` and merged back into `main`.

### Branch naming

Format: `<type>/<short-description>`

- use the same types as commit messages: `feat`, `fix`, `refactor`, `test`, `docs`, `chore`, `ci`, `perf`
- lowercase, words separated by hyphens
- keep names short and descriptive

```
# Good
feat/user-email-validation
fix/inertia-form-error-state
refactor/extract-order-total-service
chore/update-php-8.3

# Bad
feature/Add_User_Email_Validation   # wrong prefix, uppercase, underscores
bugfix                               # too vague, wrong prefix
my-branch                            # no type prefix
```

### Branch lifecycle

- branches should be short-lived — ideally merged within 3 days
- delete the branch after merging
- never commit directly to `main`

## Pull requests

### PR title

Follows the same Conventional Commits format as commit messages:

```
feat: add email validation to user registration
```

### PR description

Every PR description must include:

```markdown
## What
Brief description of the change.

## Why
Business or technical reason for the change.

## How to test
Steps to verify the change works correctly.

## Checklist
- [ ] Reviewed with [fast code review checklist](./fast_code_review_checklist.md)
```

### Review rules

- at least one approval is required before merging
- resolve all discussion threads before merging
- CI pipeline must pass (format, lint, test, build)

## Pre-commit checks

Run these checks before every commit. The recommended order:

```
pint → lint → test → build
```

Run the checks using project commands:

```bash
vendor/bin/pint --dirty
pnpm exec eslint resources/js --ext .js,.vue
php artisan test
pnpm build
```

Additional checks before committing:

- no secrets, `.env` files, or credentials staged — see [security.md](./security.md)
- migrations are safe to run and roll back on shared environments

## Git hygiene

### Merge strategy

Squash merge is the default strategy. This keeps `main` history clean — one commit per PR.

### Rebase before merging

Rebase feature branches onto `main` before merging to avoid merge commits and resolve conflicts early:

```bash
git fetch origin
git rebase origin/main
```

### Clean up local commits

Do not push "fix lint", "oops", or "wip" commits. Amend or squash them locally before pushing:

```bash
# Amend the last commit
git commit --amend

# Interactive rebase to squash multiple commits
git rebase -i origin/main
```

### Never force-push to main

Force-pushing to `main` is strictly forbidden. Force-pushing to feature branches is acceptable after rebasing.

## Tagging and versioning

### Semantic versioning

All releases use semantic versioning: `vMAJOR.MINOR.PATCH`

| Component | When to increment |
|-----------|------------------|
| MAJOR | Breaking API or behavioral changes |
| MINOR | New features, backward-compatible |
| PATCH | Bug fixes, backward-compatible |

### Tag rules

- tags are created on `main` only
- use annotated tags with a message describing the release:

```bash
git tag -a v1.2.3 -m "Release v1.2.3: add email validation, fix duplicate messages"
git push origin v1.2.3
```

- pre-release versions use a suffix: `v1.2.3-rc.1`, `v1.2.3-beta.1`
- release metadata can use `git describe --tags --always --dirty` to derive the current version automatically

## DO / DO NOT

**DO:**

- write commit messages in imperative mood
- use the `<type>: <summary>` format for all commits and PR titles
- keep one logical change per commit
- rebase onto `main` before merging
- delete branches after merging
- use annotated tags for releases
- run pre-commit checks (`pint`, `eslint`, `test`, `build`) before pushing

**DO NOT:**

- commit directly to `main`
- force-push to `main`
- push "wip", "fix lint", or "oops" commits — amend locally
- mix unrelated changes in one commit
- leave stale branches after merging
- use lightweight tags — always use annotated tags
- commit secrets, `.env` files, or credentials
- add `Co-Authored-By` trailers (e.g., `Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>`) — the commit author is whoever pushes the code

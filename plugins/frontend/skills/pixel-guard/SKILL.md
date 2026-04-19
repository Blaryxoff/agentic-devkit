---
name: devkit-pixel-guard
description: modify frontend code safely with visual regression protection — uses visual-loop baselines as ground truth to catch unintended UI changes during refactoring, restyling, token extraction, or responsive fixes
---

# Pixel Guard — Safe Frontend Refactoring

You are acting as a **senior frontend developer focused on safe code evolution**.
Your job is to apply requested code changes (refactor, restyle, extract tokens, fix responsive, restructure) while ensuring the rendered UI does not regress.

The current visual baselines are the source of truth. Any visual change must be intentional and user-approved.

## Stack context

Before starting, detect the active stack and load the applicable conduct rules.

**Primary — `.devkit/toolkit.json`:**
Read the `enabled` list. For each active plugin that has a `conduct/` directory, read all docs in it. Focus on architecture, patterns, conventions, and anti-patterns docs; skip ops/infra docs (git workflow, logging, deployment commands). `plugins/frontend/conduct/` is always read.

**Fallback — `package.json`:**
If `.devkit/toolkit.json` is absent, read `package.json` (dependencies + devDependencies). Identify the core technologies in use, then read the conduct docs from the matching `plugins/<technology>/conduct/` directory.

Apply all loaded conduct rules throughout the implementation.

## Prerequisites

- Visual-loop CLI is bootstrapped (`visual/config.json` exists in the project root).
- Dev server is running (`pnpm dev`).
- Baselines exist for the affected pages.
- For authenticated routes: `auth` block configured in `visual/config.json` with login URL, field selectors, and credentials (or leave credentials empty to be prompted).

See `plugins/core/conduct/inputs-grounding-gate.md` for the general grounding rule.

If baselines are missing, capture and approve them before starting any changes:

```bash
pnpm ui:check -- --page <page>
pnpm ui:approve -- --page <page>
```

## Workflow

Copy this checklist and track progress:

```
Pixel Guard Progress:
- [ ] Step 0: Load stack context — detect active plugins and read their conduct
- [ ] Step 1: Verify baselines — ensure current state is captured
- [ ] Step 2: Plan changes — identify scope and risk
- [ ] Step 3: Apply changes — implement the refactoring
- [ ] Step 4: Check — run visual-loop to detect regressions
- [ ] Step 5: Triage — classify each diff as intentional or regression
- [ ] Step 6: Fix regressions — restore unintended visual changes
- [ ] Step 7: Approve intentional changes — with user confirmation
- [ ] Step 8: Report — summarize outcome
```

## Step 1: Verify Baselines

Before touching any code, confirm baselines exist for every page affected by the change:

```bash
pnpm ui:check -- --page <page>
```

If all viewports show `pass`, baselines are current and you can proceed.

If baselines are missing (100% mismatch), ask the user whether to approve the current state first. Never auto-approve.

## Step 2: Plan Changes

Identify:
- Which files will be modified
- Which pages and viewports are affected
- Whether the change is expected to be visually identical (pure refactor) or intentionally different (restyle, redesign)

Classify the task:

- **Pure refactor** (extract component, rename, restructure, consolidate CSS): zero visual change expected.
- **Token extraction** (replace hardcoded values with design tokens): zero visual change expected if tokens match current values.
- **Restyle** (change colors, spacing, typography): intentional visual change expected.
- **Responsive fix** (adjust breakpoints, layout at specific viewports): targeted visual change expected.

## Step 3: Apply Changes

Implement the requested modifications. Follow project conventions and the active plugin conduct docs.

Keep changes atomic — do not mix unrelated refactoring with the requested task.

## Step 4: Check

Run the visual check on every affected page:

```bash
pnpm ui:check -- --page <page>
```

Read the report for each viewport:

```
visual/output/<page>/<viewport>/report.json
```

The report contains: `mismatchPercent`, `status` (`pass`/`warn`/`fail`), `hotspots`, and file paths to `actual.png`, `diff.png`, `baseline.png`.

## Step 5: Triage

For each viewport with a non-zero mismatch, classify the diff:

### Intentional change

The diff is expected because the task explicitly calls for a visual change (restyle, responsive fix, layout change). The `diff.png` should show changes only in the areas you intended to modify.

### Regression

The diff is unexpected — an area you did not intend to change has shifted. Common causes:
- CSS specificity cascade side effects
- Removed a class or token that was inherited elsewhere
- Layout reflow from sizing changes
- Font rendering differences from weight/family changes

## Step 6: Fix Regressions

For any unintentional diff:

1. Open `diff.png` to locate the affected region.
2. Compare `actual.png` with `baseline.png` to understand what changed.
3. Trace the cause back to your code changes.
4. Fix the regression without reverting the intentional changes.
5. Re-run `pnpm ui:check -- --page <page>` and verify.

Repeat until all unintentional diffs are resolved.

Use the loop command for faster iteration:

```bash
pnpm ui:loop -- --page <page>
```

## Step 7: Approve Intentional Changes

When only intentional visual changes remain and the user confirms they are correct:

```bash
pnpm ui:approve -- --page <page>
```

**Never approve without explicit user confirmation.** Always show the user what changed and why before asking to approve.

If the task was a pure refactor, all viewports should pass without needing approval. If they do not, something regressed — go back to Step 6.

## Step 8: Report

Summarize:

- Files modified
- Final mismatch percentage per viewport
- Classification of each diff (intentional vs. regression, and resolution)
- Any remaining deltas and why they are acceptable
- Risks or side effects to watch for
- Follow-up suggestions if applicable

## Rules

- Current baselines are the source of truth. Every visual change must be justified.
- Never silently approve new baselines.
- Keep changes atomic. Do not mix unrelated refactoring.
- If a pure refactor produces any visual diff, treat it as a bug until proven otherwise.
- Keep all configured viewports passing; do not fix one viewport at the expense of another.
- Prefer design token / layout fixes over one-off pixel hacks.

---
name: devkit-pixel-build
description: build or refine frontend UI to match a Figma design — reads Figma via MCP, implements code, then runs the visual-loop CLI to verify pixel-level fidelity across all viewports
---

# Pixel Build — Implement UI from Figma

You are acting as a **senior frontend developer with pixel-perfect attention to detail**.
Your job is to translate a Figma design into production-ready code, then verify it visually using the visual-loop CLI.

The Figma design is the source of truth. Your goal is to make the rendered UI match it across all configured viewports.

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
- Figma MCP server is connected (for `get_design_context`).
- For authenticated routes: `auth` block configured in `visual/config.json` with login URL, field selectors, and credentials (or leave credentials empty to be prompted).

If any prerequisite is missing, tell the user what to set up before proceeding. See `plugins/core/conduct/inputs-grounding-gate.md` for the general grounding rule.

## Workflow

Copy this checklist and track progress:

```
Pixel Build Progress:
- [ ] Step 0: Load stack context — detect active plugins and read their conduct
- [ ] Step 1: Read Figma — extract design specs
- [ ] Step 2: Audit existing code — find reusable components/tokens
- [ ] Step 3: Implement — write or update code
- [ ] Step 4: Check — run visual-loop to capture and diff
- [ ] Step 5: Fix — resolve mismatches by hotspot priority
- [ ] Step 6: Iterate — repeat check/fix until all viewports pass
- [ ] Step 7: Report — summarize changes and final state
```

## Step 1: Read Figma

Obtain the design from the Figma URL the user provides.

- **Page-level URL** (frame): the user wants a full page or screen implemented.
- **Component-level URL** (node): the user wants a single component built or refined.

Use `get_design_context` with the extracted `fileKey` and `nodeId` to get code hints, a screenshot, and component metadata.

Extract from the design:
- Layout structure (flex/grid, direction, wrapping)
- Spacing (gaps, padding, margins) — map to project design tokens where possible
- Typography (font family, size, weight, line-height, letter-spacing)
- Colors and fills — use existing project tokens/variables, not raw hex
- Component structure and variants (hover, active, disabled states)
- Responsive behavior (auto-layout constraints, min/max widths)

## Step 2: Audit Existing Code

Before writing new code, search the project for:
- Existing components that match or overlap with the design
- Design tokens / CSS variables / Tailwind theme values that map to the design's colors, spacing, typography
- Layout patterns already in use (grid systems, container queries, breakpoints)

Reuse what exists. Only create new abstractions when nothing suitable is found.

## Step 3: Implement

### Page-level

- Scaffold the route if it does not exist.
- Create or update the page component.
- Break the design into logical sections; implement top-down.
- Import and compose existing components where possible.

### Component-level

- Locate the existing component file.
- Apply minimal, production-safe changes to match the design.
- Preserve existing props, events, and slots unless the design explicitly changes them.

### General rules

- Follow the project's existing patterns and conventions.
- Use design tokens and theme variables instead of hardcoded values.
- Ensure the page key exists in `visual/config.json` under `pages`. If not, add it with the correct `route`.

## Step 4: Check

Run the visual check to capture screenshots and diff against baselines:

```bash
pnpm ui:check -- --page <page>
```

If this is the first time checking this page (no baselines exist), expect 100% mismatch. This is normal — you will approve baselines after confirming the implementation looks correct.

Read the report for each viewport:

```
visual/output/<page>/<viewport>/report.json
```

The report contains: `mismatchPercent`, `status` (`pass`/`warn`/`fail`), `hotspots` (regions with highest diff), and file paths to `actual.png`, `diff.png`, `baseline.png`.

## Step 5: Fix

Address mismatches by hotspot priority:

1. **Layout** — wrong structure, missing elements, collapsed containers
2. **Spacing** — incorrect gaps, padding, margins
3. **Typography** — wrong font, size, weight, line-height
4. **Sizing** — elements too wide/narrow/tall/short
5. **Alignment** — off-center, wrong justify/align

Use `diff.png` to visually locate problem areas. Cross-reference with the Figma design to determine the correct fix.

Prefer design token / layout fixes over one-off pixel hacks.

## Step 6: Iterate

After fixing, re-run the check:

```bash
pnpm ui:check -- --page <page>
```

Alternatively, use the loop command which watches for file changes and re-checks automatically:

```bash
pnpm ui:loop -- --page <page>
```

Repeat until all viewports report `pass` status.

To check a single viewport during iteration:

```bash
pnpm ui:check -- --page <page> --viewport <name>
```

## Step 7: Report

When all viewports pass, summarize:

- Files created or modified
- Final mismatch percentage per viewport
- Any remaining deltas and why they are acceptable
- Components or tokens that were reused vs. newly created
- Follow-up suggestions (e.g., missing states, responsive edge cases, accessibility)

## Baseline Approval

**Never approve baselines without explicit user confirmation.**

When the user confirms the UI is correct and ready to become the new baseline:

```bash
pnpm ui:approve -- --page <page>
```

This copies `actual.png` to `baselines/<page>/<viewport>.png` for all viewports.

## Rules

- The Figma design is the source of truth. Do not deviate from it unless instructed.
- Keep all configured viewports passing; do not optimize for only one breakpoint.
- Do not silently update baseline files.
- Do not introduce new dependencies without user approval.
- If the design references components or tokens that do not exist in the project, flag this to the user rather than inventing replacements.

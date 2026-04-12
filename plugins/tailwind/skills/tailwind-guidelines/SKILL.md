---
name: devkit-tailwind-guidelines
description: Tailwind-specific utility and tokenization rules
---

# Tailwind Guidelines

You are acting as a Tailwind specialist.

## Ownership scope

This skill owns Tailwind-specific conventions. Generic CSS best practices belong to frontend base guidance.

## Tailwind rules

1. Prefer semantic tokenized values from config/theme over repeating arbitrary values.
2. Avoid repeated arbitrary values like `[#e2e7ef]` across multiple components.
3. When a Tailwind arbitrary value repeats, move it into Tailwind config or a shared token.
4. Keep utility class usage consistent with project conventions and readable groupings.
5. Reuse existing UI primitives/components before introducing one-off class-heavy markup.

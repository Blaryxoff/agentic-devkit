# Mandatory Review Gate

Before sending the final result for any implementation task, perform a review of all changed files.

## Required checks

- Verify there is no obvious code duplication; enforce DRY.
- Verify architecture and design patterns are not degraded; enforce SOLID.
- Forbid hardcoded domain and presentation literals unless explicitly justified:
  - no magic status/type strings in business logic;
  - no hardcoded numeric business thresholds/rates;
  - no hardcoded UI colors/tokens where project design tokens exist;
  - no scattered repeated literals that should be centralized.
- Require extraction of such values into the appropriate layer:
  - enums for finite states/types/statuses;
  - named constants/value objects for fixed business values;
  - config files for environment- or project-level settings;
  - design tokens/theme variables for colors and style constants.
- Enforce stack-specific architecture rules from active plugin conduct docs (thin controllers, validation conventions, etc.).
- Re-check implemented logic against the original user task and acceptance criteria.
- Identify and report mismatches, regressions, and missing cases.
- Explicitly reason through edge cases, null/empty states, and error paths.

## Output requirement

Follow `review-findings-format.md` — severity buckets, file references, and the empty-bucket rule.

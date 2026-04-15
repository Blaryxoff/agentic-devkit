# Visual Implementation Loop

For visual frontend implementation or restyling tasks, follow a structured verification loop to ensure changes match design intent.

## Workflow

1. Run the project's visual check command (e.g. `pnpm ui:check -- --page <page>`) before edits when a baseline exists.
2. Run the visual check command again after edits.
3. Read the visual diff report (e.g. `visual/output/<page>/<viewport>/report.json`) before touching styles.
4. Fix highest-impact hotspots first.
5. Prioritize fixes in this order: layout, spacing, typography, sizing, alignment.
6. Keep all configured viewports passing; do not optimize for only one breakpoint.
7. Prefer design token/layout fixes over one-off pixel hacks.
8. Do not overwrite visual baseline files unless explicitly approved.
9. Stop when mismatch passes threshold or loop reaches max iterations.

## Safety

- Avoid silent baseline updates.
- Treat the project's baseline approval command as the only baseline update path.

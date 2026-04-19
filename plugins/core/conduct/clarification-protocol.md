# Clarification Protocol

Shared rule for any skill that needs to resolve ambiguity with the user before producing or writing output.

## When this applies

Apply whenever a skill cannot ground a decision in code, plan, conduct doc, or design source — and the decision affects the output.

## Required steps

1. **Collect all ambiguities first.** Do not ask the first question that comes up; finish reading the inputs, then build the full list.
2. **Decide per item:**
    - If the item is a clear defect with an obvious correction, fix it without asking.
    - If the item requires a product, UX, architectural, or scope decision, ask.
3. **Ask via `AskQuestion` (or the closest available structured tool) in batches of at most 4.** Run follow-up rounds if more are needed.
4. **Each question must include:**
    - what the input currently says (quote or paraphrase),
    - what is unclear or missing,
    - why it blocks the skill's output,
    - the available options when known.
5. **Never invent an answer.** Never write `TBD`, `???`, or a placeholder into the output as a resolution.

## Forbidden

- Batching more than 4 questions at once.
- Asking open-ended questions when a small set of concrete options exists.
- Continuing past an unresolved blocking ambiguity.

See `plugins/core/skills/plan-reviewer/SKILL.md` (Step 6) for the full pattern.

# Code Comments

Implementation code is self-explanatory by default. These rules are language-agnostic; apply them in PHP, JS/TS, and any other language in the stack.

## Default: write code, not prose

Do not add comments or docblocks to explain a method, branch, business rule, data flow, or design choice. If local code needs a paragraph to be understood, improve the code instead:

1. rename symbols after the domain concept;
2. extract a well-named predicate or operation;
3. replace flags, magic values, and loose arrays with explicit types or named values where proportionate;
4. simplify control flow;
5. make the behavior executable in a focused test when the project permits tests.

Private and internal members must not have narrative docblocks. Never turn investigation notes, ticket context, or reasoning from the current task into a comment sheet above the resulting code. Existing verbose comments are not precedent to add more.

## Narrow exceptions

A comment is allowed only when the information cannot be encoded in names, types, structure, tests, or external documentation:

- machine-consumed metadata such as PHPStan array shapes/generics, generated-code markers, or required lint directives;
- an externally imposed protocol, vendor, legal, security, or compatibility constraint whose surprising implementation must remain exact;
- a public integration contract that consumers need and the language signature cannot express.

Keep an exception to the shortest useful form and cite the external source, issue, or invariant when practical. Do not write paragraph-form docblocks for an exception. A public or exported symbol does not automatically need a docblock.

## Always forbidden

Do not write comments that narrate edits, progress, or what used to be there. The diff and git history already record that.

- ❌ `// new function`, `// added test`, `// updated handler`
- ❌ `// now we changed this to use X`, `// previously used Y, now using Z`
- ❌ `// temporary fix`, `// TODO: was broken before`, `// refactored from the old version`

A comment must read the same whether it was written today or three years ago. If removing the words "new", "added", "now", "previously", or "changed" empties the comment, the comment was describing history — delete it.

- Do not restate the next line or paraphrase the symbol name.
- Do not explain why a private helper exists; give the helper a name that states the rule.
- Do not preserve superseded behavior, migration history, or admin/ticket context in source comments.
- Do not use a docblock as a substitute for a precise type, named value, or smaller operation.

## Match the project's existing comment style

For a narrow exception, follow the surrounding code's placement and syntax. Project rules may require specific machine-readable annotations, but nearby explanatory comments do not weaken the no-prose default. Per `surgical-changes.md`, do not add or reformat comments on code you did not otherwise have to touch.

## Enforcement

`plugins/core/hooks/comment-gate.sh` runs as a PreToolUse hook in Claude Code, Codex, and Cursor. It rejects an edit whose newly added comment lines narrate change history, and prints the offending lines. Rewrite or delete the comment and retry — there is no bypass flag.

## Why this matters

Narrative comments duplicate a momentary understanding of the code and drift independently from it. Precise names, types, structure, and tests change with the behavior and remain reviewable. Comments are reserved for external facts the code cannot own.

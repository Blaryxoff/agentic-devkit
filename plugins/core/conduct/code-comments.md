# Code Comments

Implementation code is self-explanatory by default. These rules are language-agnostic; apply them in PHP, JS/TS, and any other language in the stack.

## Default: write code, not prose

Express methods, branches, business rules, data flow, and design choices through code rather than comments or docblocks. When local code needs a paragraph to be understood, improve it by:

1. rename symbols after the domain concept;
2. extract a well-named predicate or operation;
3. replace flags, magic values, and loose arrays with explicit types or named values where proportionate;
4. simplify control flow;
5. make the behavior executable in a focused test when the project permits tests.

Keep private and internal members free of narrative docblocks. Put investigation notes, ticket context, and task reasoning in the response to the user, where they do not drift from the code. Follow the no-prose default even when existing comments are verbose.

## Narrow exceptions

A comment is allowed only when the information cannot be encoded in names, types, structure, tests, or external documentation:

- machine-consumed metadata such as PHPStan array shapes/generics, generated-code markers, or required lint directives;
- an externally imposed protocol, vendor, legal, security, or compatibility constraint whose surprising implementation must remain exact;
- a public integration contract that consumers need and the language signature cannot express.

Keep exceptions to the shortest useful form and cite the external source, issue, or invariant when practical. Use a brief annotation or comment rather than a paragraph-form docblock. Add docblocks to public or exported symbols only when a listed narrow exception applies.

**Container build files are outside the no-prose default.** `Dockerfile*`, `*.dockerfile` and `Containerfile*` state base-image quirks, arch selection, builder and layer-cache behaviour — constraints no instruction, name, or structure can carry, and which the next reader needs before editing a layer. Match the surrounding file's comment density there. Everything else still applies: no change narration, and no notes about the task that produced the layer.

## Keep comments timeless and concise

For a permitted exception, state the enduring constraint; keep edit and progress history in the diff and git history.

- ❌ `// new function`, `// added test`, `// updated handler`
- ❌ `// now we changed this to use X`, `// previously used Y, now using Z`
- ❌ `// temporary fix`, `// TODO: was broken before`, `// refactored from the old version`

Keep every allowed comment valid regardless of when it was written. Remove it when it only describes history, such as text that becomes empty when "new", "added", "now", "previously", or "changed" is removed.

- Give each comment information beyond the next line or symbol name.
- Name private helpers after the rule they express.
- Keep superseded behavior, migration history, and admin/ticket context out of source comments.
- Express contracts through precise types, named values, or smaller operations instead of docblocks when those forms suffice.

## Match the project's existing comment style

For a narrow exception, follow the surrounding code's placement and syntax. Project rules may require specific machine-readable annotations; keep nearby explanatory comments under the same no-prose default. Per `surgical-changes.md`, leave comments on otherwise untouched code unchanged.

## Enforcement

`plugins/core/hooks/comment-gate.sh` runs as a PreToolUse hook in Claude Code, Codex, and Cursor. It rejects an edit on two grounds and prints the offending lines: comment text that narrates change history, and a prose comment block — two or more consecutive full-line comments of running text on a code file. Directive, tag, licence, and generated-marker lines are exempt from the prose rule. Rewrite or delete the comment and retry — there is no bypass flag.

Rewording an existing comment block counts as adding prose, because only the baseline text survives the subtraction. That is the gate working: per `surgical-changes.md`, leave comments alone on code the change did not otherwise require you to touch.

The hook is a backstop, not the rule. It fires after the comment is already written, so an edit it rejects costs a full second attempt; the no-prose default is what keeps that from happening.

## Why this matters

Narrative comments duplicate a momentary understanding of the code and drift independently from it. Precise names, types, structure, and tests change with the behavior and remain reviewable. Comments are reserved for external facts the code cannot own.

# Code Comments

Comments describe the current state and purpose of the code — never its history, evolution, or the act of changing it. These rules are language-agnostic; apply them in PHP, JS/TS, and any other language in the stack.

## Forbidden: change-history comments

Do not write comments that narrate edits, progress, or what used to be there. The diff and git history already record that.

- ❌ `// new function`, `// added test`, `// updated handler`
- ❌ `// now we changed this to use X`, `// previously used Y, now using Z`
- ❌ `// temporary fix`, `// TODO: was broken before`, `// refactored from the old version`
- ✅ `// resolve the tenant from the subdomain before the route binds`

A comment must read the same whether it was written today or three years ago. If removing the words "new", "added", "now", "previously", or "changed" empties the comment, the comment was describing history — delete it.

## Comment the why, not the what

State the reason or intent that the code itself cannot express. Do not restate what the next line plainly does.

- ❌ `// loop over users` above `foreach ($users as $user)`
- ✅ `// providers are billed monthly, so prorate the first partial period`

## Document the public surface

Document every exported / public API element (public class, method, function, interface) with a doc comment stating its contract: what it does, its inputs, and what it returns or throws. Internal helpers need a comment only when their intent is non-obvious.

## Match the project's existing comment style

Follow the surrounding code's comment conventions — placement, doc-block format, and casing. Do not impose a convention from a different language or project. Per `surgical-changes.md`, do not add or reformat comments on code you did not otherwise have to touch.

## Why this matters

History-narrating comments rot the moment the next change lands: "new function" describes a function that is no longer new, and "previously used Y" describes code nobody can see. They mislead the next reader and survive long after their context is gone. Comments that describe current intent stay true.

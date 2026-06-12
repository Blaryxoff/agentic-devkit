# Communication Style

Direct, brief, AI-speak-free writing for **technical communication**: commit messages, PR/MR titles and descriptions, code-review comments, issue comments, and internal team discussion. The `devkit-git` skill applies this to commit/PR text; reviewers apply it to review comments.

> Adapted from `umputun/cc-thingz` (MIT).

## Scope

**Apply this style to:** commit messages, PR/MR descriptions and comments, code-review comments, issue/ticket comments, internal technical discussion.

**Do NOT apply to** (use proper English — complete sentences, full capitalization, professional tone): `README.md`, official documentation, user guides, public blog posts, and any public-facing release notes or content for a general audience.

## Core principles

- **Brevity and directness** — get to the point; cut filler and unnecessary context. Short is fine when it conveys the full message.
- **Honest feedback** — state opinions directly; express uncertainty openly ("I'm not sure", "I can't see how"); don't soften criticism artificially; question design decisions when warranted.
- **Problem → solution structure** — state the problem concisely, then what changed. Skip the dramatic build-up. Numbered lists for multiple issues.
- **Technical precision** — exact references: `file:line`, commit SHAs, issue links. Inline code with backticks for identifiers; code blocks for snippets. Assume the reader has technical context.

## AI-typical language to avoid

**Filler phrases (delete entirely):** "it's important to note that", "it's worth mentioning", "in order to" (→ "to"), "plays a crucial role in", "at the end of the day", "that being said", "moving forward", "in terms of".

**Overused words (use the plain alternative):** comprehensive → full/complete · robust → solid/reliable · leverage → use · utilize → use · facilitate → help/enable · optimal → best · seamless → (skip) · streamline → simplify.

**Abstract noun phrases (convert to verbs):** "the implementation of" → "implemented" · "make a decision" → "decide" · "provide assistance" → "help" · "perform an analysis" → "analyze".

**Hedging (be direct):** "I think maybe we could consider…" → state the opinion · "it would seem that…" → state the fact · "perhaps it might be worth…" → suggest directly.

**Excessive transitions (use sparingly or drop):** "furthermore", "additionally", "moreover", "in conclusion".

**Meta-commentary (delete):** "this approach works by…" → just describe it · "the benefit of this is…" → state the benefit · "what this means is…" → just say it.

## Boilerplate to drop

No "thanks in advance", "hope this helps", "let me know if you have any questions", "looking forward to hearing from you", sign-offs ("best regards"), or "I hope you're doing well" in technical comments. No corporate or marketing language.

## Summary

Concise · direct (no hedging unless genuinely uncertain) · honest (say when you don't know or disagree) · precise (cite commits, files, lines) · no AI-speak · no boilerplate. Proper English only for `README.md`, public docs, and blog posts.

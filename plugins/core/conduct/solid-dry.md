# SOLID and DRY

Code must follow SOLID principles and DRY (Don't Repeat Yourself).

- Always check new and changed code for duplication.
- If code blocks differ only slightly, extract shared logic into a reusable function, class, or component.
- Prefer composition over inheritance when reducing duplication.

## Existence ladder — before writing new code

Climb these rungs in order and stop at the first one that resolves the need. Write new code only when every rung has been tried and none fits.

1. Does this need to exist at all? Drop requirements the task does not actually state.
2. Does the codebase already have it? Search before writing.
3. Does the language's standard library cover it?
4. Does the platform or framework already provide it natively?
5. Does an already-installed dependency do it? Adding a new one needs explicit approval.
6. Can it be one expression instead of a wrapper, class, or helper?

Safety-bearing code — input validation, error handling, security controls, accessibility — passes through the same rungs (reuse the existing validator rather than writing one), but is never dropped, thinned, or merged away to make a change smaller. Fewer lines is never a reason to lose a check.

## When NOT to abstract

SOLID/DRY enforces extraction of *real* repetition. It does not justify speculative abstraction. The two rules coexist; timing decides which applies.

- No abstraction for code with a single call site. Inline it.
- No strategy pattern, base class, or interface for one concrete implementation. Add it when the second case appears.
- No configurability, hooks, or flags that no caller uses today.
- Three similar lines beat a premature helper. Extract on the third *distinct* call site, not the second near-duplicate.
- "Might be useful later" is not a reason. The next change is cheaper than the wrong abstraction.
- If the implementation is 200 lines and the requirement could be met in 50, rewrite it. Length is a smell, not a goal.

The DRY rule above targets duplication that already exists in the diff or the surrounding file. The rules in this section target duplication that does not yet exist. Do not pre-build for it.

# Thin Controller / Thin Model Rule

This document defines the thin controller and thin model architectural rules for Laravel projects. These rules are **blocking** — code, plans, and specs that violate them must be fixed before handoff.

## Thin controller rule

A controller method must only: authenticate/authorise, delegate to Action(s), and assemble an HTTP response. It must not contain business logic.

**Red-flag patterns — flag or rewrite when any of these appear inside a controller method body rather than in a dedicated Action class:**

- State/status guard logic (e.g. `if ($attempt->status !== X) return 422`)
- Ownership or authorship checks beyond a single-line `abort(403)` after an Action resolves the resource
- Direct Eloquent queries other than `Model::find()` / `findOrFail()` / `withTrashed()->findOrFail()` lookup of the primary resource
- Business rule branching or calculations (points validation loops, scoring, transition logic)
- Logic that is identical or near-identical across two or more controller methods — always an Action extraction candidate

### Correct pattern for a new endpoint

```
Create XxxAction — receives typed parameters; enforces state guard, ownership check, authorship check; throws typed domain exception on failure.
Controller method: resolve resource (findOrFail), call XxxAction, map typed exception to HTTP response.
```

### Incorrect pattern (flag this)

```
Controller method:
  - Load HwComment::findOrFail($comment)
  - Verify $hwComment->attempt_id === $attempt->id; abort 403 if not
  - Check authorship: $hwComment->author_id === $request->user()->id or Gate::allows(...)
  - Update $hwComment->body and return JSON
```

### How to flag violations

- **In code reviews:** Flag as architecture violation. Evidence: this document + `architecture.md`.
- **In plan reviews:** Flag as `STACK MISMATCH`. Proposed fix: extract to `[SuggestedActionName]Action`; controller calls the action and maps its typed exception to an HTTP response.
- **In spec writing:** Never prescribe business logic inside a controller method. Split task steps into Action creation + controller wiring.

### Correct task step shape for plans and specs

```
### Task N: Add XxxEndpoint

**Files:** Create `app/Actions/Foo/XxxAction.php`; Modify `app/Http/Controllers/Admin/FooController.php`; Modify `routes/admin.php`

- [ ] Create `XxxAction`: receives typed parameters; enforces [state guard / ownership / authorship]; throws `XxxBlockedException` on failure
- [ ] Add `xxx(AdminRequest $request, ...)` to controller: resolve resource with `withTrashed()->findOrFail()`, call `XxxAction::run(...)`, catch `XxxBlockedException` and return 422 JSON
- [ ] Register route in `routes/admin.php`
- [ ] Mark completed
```

## Thin model rule

Eloquent models may contain: `$fillable`/`$casts`/`$dates`, relationships, query scopes, simple accessors/mutators, and `scopeX()` methods. They must not contain business workflows.

**Flag any of the following in a model method as a violation — belongs in an Action or Service:**

- Multi-step branching or business rule logic
- Cross-model orchestration
- Notification dispatch
- Status transitions with side effects

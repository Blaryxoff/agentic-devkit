# Enums for Status and Type Fields

All status and type fields must use native PHP backed enums, not plain strings or constants.

## Rules

- Use native `enum` column type in migrations for enum fields.
- Every enum must implement a `label(): string` method for human-readable display.
- Every enum must use a shared `HasLabels` trait that provides the static `labels(): array` method. If the project does not have this trait yet, create it (e.g. `app/Enums/Concerns/HasLabels.php`).
- Enum case names use TitleCase: `Active`, `PendingReview`, `Archived`.
- Compare statuses through enum cases, such as `$model->status === Status::Active`.
- Cast enum columns in the model's `casts()` method.

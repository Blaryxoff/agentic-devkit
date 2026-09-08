# Sprint history snapshots

## Purpose

Persist expensive historical evidence by workbook. Re-audit the XLSX mechanically on every run, but do not repeatedly
open unchanged historical specifications or rescan old Git/session history.

## Discovery

Resolve snapshots in this order:

1. `SPRINT_HISTORY_SNAPSHOT` when it names a readable file.
2. `docs/sprint-history.json` in each related repository root.

Reject a snapshot whose `schema_version` or `workbook_id` does not match. Do not put project-specific history inside the
global devkit clone.

Validate the stored quality gates before using evidence:

```bash
jq -e --arg workbook "$WORKBOOK_ID" \
  '.schema_version == 2 and .workbook_id == $workbook and (.quality.gates | all(. == true))' \
  docs/sprint-history.json
```

Compare the live XLSX with the snapshot and exclude the active target from historical staleness checks:

```bash
python3 "$DEVKIT_HOME/plugins/core/skills/sprint/scripts/audit_workbook.py" workbook.xlsx \
  --snapshot docs/sprint-history.json \
  --workbook-id "$WORKBOOK_ID" \
  --target-sheet "$TARGET_SHEET" \
  --pretty
```

Require `snapshot_comparison.compatible == true`. Research only `changed_sheets`, `new_sheets`, and sources newly linked
from those sheets or the target. A missing archived sheet is evidence to report; do not silently delete it from history.

Query the snapshot surgically; do not load a large project snapshot wholesale. Examples:

```bash
jq --arg id "$TASK_ID" '.task_history[] | select(.task_id == $id)' docs/sprint-history.json
jq --arg id "$TASK_ID" '.task_index[$id]' docs/sprint-history.json
jq --arg key "$NORMALIZED_TITLE_KEY" '.title_index[$key]' docs/sprint-history.json
jq --arg key "$NORMALIZED_EPIC" '.epic_index[$key]' docs/sprint-history.json
jq --arg key "$SOURCE_KEY" '.spec_sources[$key]' docs/sprint-history.json
```

## Required shape

```json
{
  "schema_version": 2,
  "normalization_version": 1,
  "workbook_id": "exact Google Sheets file id",
  "task_id_pattern": "project tracker-key pattern",
  "observed_at": "ISO-8601 timestamp",
  "audit": {
    "sheet_count": 0,
    "sprint_sheet_count": 0,
    "task_row_count": 0
  },
  "sheets": {
    "Exact archived sheet title": {
      "content_fingerprint": "sha256 from audit_workbook.py",
      "state": "hidden",
      "task_count": 0
    }
  },
  "estimate_patterns": {},
  "executor_aliases": {},
  "ownership_evidence": {},
  "task_history": [],
  "task_index": {},
  "title_index": {},
  "epic_index": {},
  "spec_sources": {},
  "source_documents": {},
  "decision_records": [],
  "calibration_events": [],
  "code_evidence": [],
  "quality": {},
  "git_baselines": {},
  "known_defects": []
}
```

Store task history as normalized `sheet`, `row`, `epic`, `task`, `subtask`, `task_id`, `estimate`, `actual_estimate`,
`direction`, and `executor` records. Add normalized identity fields; extract canonical task IDs from cell text or tracker
URLs. Build task-ID, normalized-title, and normalized-epic indexes instead of forcing descendants to scan every row.
Store only evidence needed for future matching and estimation.

Key each specification record by `(provider, file_id, tab_or_gid, fragment)`. Preserve the exact URL and record:

- accessibility and observation time;
- a concise scope summary covering roles, surfaces, states, integrations, and QA signals;
- completeness and confidence;
- exact task IDs/rows that used the source;
- redirect or missing-input evidence.

Store repository baselines by absolute or workspace-relative repository identity and ref SHA. Never store credentials,
cookies, tokens, private session payloads, or full document bodies.

Store manual planner revisions as append-only calibration events with stable task identity, model point/range, revised
point/range, scope change, evidence-strength change, assignment effect, and observation time. A human revision is not an
actual duration; store actual coding hours separately when they become available. Match revisions by task ID, then
normalized epic/task/subtask and source identity. Never infer a change from row number alone.

Fingerprint semantic workbook state only. Ignore cached formula results and transient export metadata such as regenerated
threaded-comment author IDs; include cell/formula values, exact link identities, comment text, validations, hidden state,
and other planning-relevant content.

Keep the JSON machine-oriented and optionally minified. Descendants query indexes and record IDs; they do not gain
accuracy from pretty-printing or receiving the complete archive in context.

## Quality gates

Reject or incrementally repair a snapshot when any applicable gate fails:

- `(sheet, row)` task identities are unique;
- every canonical task ID matches `task_id_pattern`; derive the pattern from workbook/tracker configuration instead of
  accepting unrelated URL tokens;
- every URL is canonical and free of Markdown closing punctuation;
- task/title/epic indexes resolve to existing task-history records;
- exact source identities retain `tab`, `gid`, `node-id`, and fragment;
- complete source summaries state concrete roles, surfaces, states, integrations, or QA scope;
- generic, redirected, attachment-only, and metadata-only sources are marked incomplete or lower confidence;
- decision records cite estimate, direction or explicit unknown state, executor or explicit unassigned state,
  confidence, and evidence basis;
- calibration events preserve both the earlier estimate and the human revision without relabeling either as actual time;
- Git ownership records cite repository/commit or explicitly state that no exact match exists;
- aggregate counts equal the records they summarize.

Never promote confidence merely because a source was reachable. Accessibility, completeness, task specificity, and
implementation evidence are separate signals.

## Incremental refresh

1. Export and audit the live workbook.
2. Compare archived sheet `content_fingerprint` values.
3. Rebuild task-history records only for new or mismatched sheets.
4. Inspect only exact source identities missing from `spec_sources` or marked incomplete for a target task.
5. Scan Git and sessions after each recorded ref/date baseline; still inspect an older exact task ref when the target
   explicitly points to it.
6. Merge new evidence without deleting earlier provenance. Update `observed_at`, sheet fingerprints, and Git baselines
   only after the current run is verified and the repository write is authorized.

If a historical source changed but its URL identity did not, retain the earlier record and append a new observation.
Do not silently overwrite the old summary.

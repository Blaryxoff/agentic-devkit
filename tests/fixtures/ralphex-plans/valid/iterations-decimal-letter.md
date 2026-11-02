# Plan: Rework billing

## Overview

Split billing into steps.

## Validation Commands

```bash
make check
```

### Iteration 1: Schema

**Files:** Create `db/001.sql`

- [ ] Add the table
- [ ] Mark completed

### Iteration 2.5: Backfill

**Files:** Modify `db/002.sql`, Delete `db/old.sql`

- [ ] Backfill rows
- [ ] Mark completed

### Iteration 2a: Cleanup

**Files:** Delete `db/tmp.sql`

- [x] Remove temp file
- [x] Mark completed

## Risks

None known.

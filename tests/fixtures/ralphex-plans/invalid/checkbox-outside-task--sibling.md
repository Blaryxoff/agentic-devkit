# Plan: Export report

## Overview

Add a CSV export to the report page.

## Context

Reports are built in `src/report.ts`. Open items are tracked in prose only.

## Validation Commands

```bash
npm test
npm run lint
```

### Task 1: Export service

**Files:**
- Create `src/export.ts`
- Read `src/report.ts`

- [ ] Add `exportCsv()` returning a string
- [ ] Cover quoting in a unit test
- [ ] Mark completed

### Task 2: Wire the button

**Files:** Modify `src/page.ts`

- [ ] Call `exportCsv()` on click
- [ ] Mark completed

### Verification notes

- [ ] Mark completed

---
name: devkit-scrapling-extract
description: extract web pages to clean markdown/text with Scrapling as an on-demand Python scraper. Use as a fallback when curl/web extraction is brittle, but before reaching for a full browser automation stack. No resident services.
---

# Scrapling Extract

Use Scrapling for **one-shot page extraction**: URL in, markdown/text/HTML out, process exits.

Good fits:
- Pages where plain `curl` gives noisy HTML.
- Cron/watchdog collectors that need clean markdown snapshots.
- Research ingestion where browser automation is overkill.

Do **not** install browser/stealth extras unless the basic extractor fails on a real target.

## Isolated setup

Use a temp venv or project-local tool cache. Do not global-install during exploratory work.

```bash
python3 -m venv /tmp/scrapling-venv
/tmp/scrapling-venv/bin/python -m pip install 'scrapling[shell]'
```

If this host has `uv`, the same pattern can be done in a scratch dir:

```bash
uv venv /tmp/scrapling-venv
/tmp/scrapling-venv/bin/python -m pip install 'scrapling[shell]'
```

## Basic extraction

```bash
/tmp/scrapling-venv/bin/scrapling extract get 'https://example.com' /tmp/page.md
sed -n '1,80p' /tmp/page.md
```

Prefer markdown/text output for agent consumption. Keep raw HTML only when selectors/layout matter.

## Python wrapper pattern

For repeatable collectors, write a tiny script that bounds output:

```python
from scrapling import Fetcher

page = Fetcher.get("https://example.com", timeout=20)
print(page.get_all_text(ignore_tags=("script", "style"))[:8000])
```

Save raw artifacts under `/tmp` or a task-specific cache; pass only compact extracted text to the agent.

## Stealth/browser mode

Only after basic extraction fails:

```bash
/tmp/scrapling-venv/bin/scrapling install
/tmp/scrapling-venv/bin/scrapling extract stealthy-fetch '<url>' /tmp/page.md
```

This may download browser assets and gets heavier. Treat it as **trial**, not the default. If a normal Hermes browser/CDP workflow is already available and the task needs interaction/login, use the browser path instead.

## Verification checklist

- `scrapling extract ...` exits with status 0.
- Output has the expected title/body, not a bot-wall/login page.
- Runtime and output size are acceptable for cron use.
- No browser process remains unless `stealthy-fetch` explicitly required one.

## Hard rules

- Do not use Scrapling to bypass access controls or authenticated content the user has not authorized.
- Do not keep retrying anti-bot pages blindly; switch to browser/manual auth or reject the source.
- Do not add Scrapling as a permanent dependency to an app repo for a one-off extraction.

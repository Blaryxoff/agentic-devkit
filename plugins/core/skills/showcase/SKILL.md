---
name: devkit-showcase
description: >-
  Screenshots; use on showcase/покажи правки. Not QA.
---

# Showcase

Create a polished, self-contained HTML gallery from real screenshots of the completed work. A bare invocation
uses the current task. Preserve the user's conversation while opening the report beside it.
Match requests such as “show screenshots of the fixes”, «покажи исправления» and «отчёт со скриншотами».

## 1. Ground the story

- Read the task's issue list and completed-work evidence. Reuse verified captures when their code, data and viewport
  still match; capture missing states through the available browser tools.
- Keep original issue IDs and ordering, including gaps. Group several screenshots under one issue when needed.
- State the environment, date, role and test-data context. Describe what each screenshot actually demonstrates.
- Separate unverified or blocked items explicitly. A still image does not prove persistence, animation or authorization.
- Route implementation to `devkit-coder` and a requested QA pass to `devkit-browser`; presenting work alone does not
  authorize source edits, deployment, production data changes or a new exhaustive QA pass.

## 2. Capture stable, legible states

- Use the project's serving instructions and authorized test login. Keep credentials and customer data out of captures.
- Open each relevant state with real UI actions. Record enough surrounding context to identify the selected entity
  and the result. Include filled fields, meaningful empty states and mobile layouts when relevant to the change.
- Wait for fonts, images, hydration, loading indicators and relevant transitions to settle. Check two observations
  of element rectangles and running animations rather than treating a fixed delay or completed click as proof.
- Inspect the header at the top and after scrolling when it changes on scroll. Wait for its intended settled state
  before capture. Investigate an observed overlap or missing background before calling it screenshot timing.
- Prefer viewport captures for sticky/fixed layouts. Element screenshots can scroll their target and capture a sticky
  header over it while omitting its background outside the target; use a settled full viewport and crop afterward
  only if needed. Check the actual saved pixels for compositor artifacts.
- Inspect every saved image at useful resolution. Retake clipped controls, transient overlays, accidental scroll
  positions and layout artifacts. Do not hide a genuine defect by changing CSS, DOM or screenshot pixels.
- Use real captures only. Never generate or reconstruct UI evidence. Keep working files outside Downloads; place
  only the finished shareable HTML there unless the user requests another location.

## 3. Build the gallery

Use the bundled renderer with Python 3 (standard library only). Resolve bundled paths relative to this skill's
directory, never the project cwd. Write a UTF-8 JSON manifest; image paths resolve beside it:

```json
{
  "title": "Completed work",
  "intro": "Verified local screens; original issue numbering is preserved.",
  "environment": "Local · test account · 1440 × 900",
  "date": "2026-10-22",
  "source": {"label": "Task", "url": "https://example.com/issues/42"},
  "items": [
    {"id": "1", "title": "Searchable list", "summary": "Typing narrows the available options.",
     "images": [{"path": "search.png", "caption": "Search results after entering the name"}]},
    {"id": "3", "title": "Saved values", "summary": "The selected record opens with its saved date.",
     "images": [{"path": "record.png", "caption": "Previously saved record"}]}
  ]
}
```

```bash
python3 <skill-directory>/scripts/render.py <work-directory>/manifest.json --output <finished-report>.html
```

- Write captions and summaries in the user's language. Set optional `lang` and `labels` (`navigation`, `open`, `close`,
  `screenshot`) to translate the renderer's controls; defaults are English.
- Keep the report portable: inline images, CSS and JavaScript, with no CDN or server dependency. Preserve natural
  screenshot proportions, clear issue navigation, readable captions, keyboard focus and click-to-zoom with Escape.
- Use agterm theme variables with system fallbacks. Do not override `--agterm-*` variables. Adjust the bundled
  template only for a concrete presentation requirement; preserve its accessibility and escaping.

## 4. Verify and open beside the conversation

1. Open the finished file with an available browser tool. Check title, section/issue count, image completion and
   nonzero natural dimensions. Test a thumbnail, keyboard close/focus return, narrow viewport and horizontal overflow.
2. When running in agterm, activate its skill and inspect the live tree and installed CLI help/version. Resolve the
   owning conversation by pane/session identity; inherited IDs can be stale. Never target an unrelated `active` session.
3. Open the report in a safe sibling **panel in the same session**, keeping the conversation visible. Inspect the
   sibling's process and overlays before using it. For an owning conversation on the left with no existing split,
   these documented commands create a right pane and show the report:

   ```bash
   agtermctl session split on --axis vertical --target "$owner" --socket "$socket" --json
   agtermctl session overlay open --html "$report" --js --navigation --pane right --target "$owner" --socket "$socket" --follow --json
   agtermctl tree --window "$window" --socket "$socket" --json
   ```

4. Verify the live tree reports the expected owning session, sibling pane, file/title and HTML overlay `state: loaded`.
   An accepted open alone does not prove rendering. Leave the report open and the conversation visible.
5. If the sibling is occupied, preserve it. Open the report in a sibling tab of an available normal browser and explain
   the agterm limitation. Outside agterm use the browser; a local file link is the final fallback when no display tool
   is available. Never create another agterm session or cover the conversation merely to display the report.

Close only browser processes/tabs created by this workflow after verification, excluding the final report shown to
the user. Remove only owned temporary data. Finish with the visible location and the finished HTML link; distinguish
evidence shown from checks actually performed.

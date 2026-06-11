---
name: devkit-youtube-transcript
description: fetch YouTube transcripts/subtitles and turn them into compact summaries or reusable notes. Use for video research, media workflows, audiobook/video triage, or extracting content for users who do not want to watch the video.
---

# YouTube Transcript

Use this skill when the useful artifact is **text**, not the video file.

Prefer existing local tools (`yt-dlp`, transcript libraries, or project scripts) over browser scraping. Keep outputs compact; raw transcripts can be huge.

## Discovery

```bash
yt-dlp --list-subs '<youtube-url>'
```

Check for manual subtitles first; auto-generated subtitles are acceptable but must be labelled as such.

## Fetch subtitles without video

```bash
mkdir -p /tmp/youtube-transcript
yt-dlp \
  --skip-download \
  --write-subs --write-auto-subs \
  --sub-langs 'en.*,ru.*,uk.*' \
  --sub-format vtt \
  -o '/tmp/youtube-transcript/%(id)s.%(ext)s' \
  '<youtube-url>'
```

Convert VTT to plain text with timestamps removed:

```bash
python3 - <<'PY'
from pathlib import Path
import re
for p in Path('/tmp/youtube-transcript').glob('*.vtt'):
    lines=[]
    for line in p.read_text(errors='ignore').splitlines():
        if not line or line.startswith('WEBVTT') or '-->' in line:
            continue
        if re.match(r'^\d+$', line):
            continue
        line = re.sub(r'<[^>]+>', '', line).strip()
        if line:
            lines.append(line)
    out = p.with_suffix('.txt')
    out.write_text('\n'.join(lines), encoding='utf-8')
    print(out)
PY
```

## Summarize

For long transcripts, chunk by approximate character count and produce:
- 5–10 bullet summary;
- important claims/facts separated from opinion;
- timestamps only if available and useful;
- open questions / follow-up links.

## Output format

```markdown
## Видео
- URL: <url>
- Title: <title if known>
- Transcript: manual / auto-generated / unavailable
- Language: <lang>

## Summary
- ...

## Useful details
- ...

## Caveats
- Auto subtitles may contain recognition errors.
```

## Hard rules

- Do not download video/audio when the task only asks for transcript/summary.
- Do not pretend auto-generated subtitles are authoritative.
- If subtitles are unavailable, say so and offer audio extraction/transcription as a separate heavier path.

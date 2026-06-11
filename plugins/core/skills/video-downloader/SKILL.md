---
name: devkit-video-downloader
description: download online videos or audio on demand with yt-dlp for archival, media preparation, subtitles, or offline conversion. Use only when the user actually needs media files; for summaries prefer devkit-youtube-transcript.
---

# Video Downloader

Use `yt-dlp` for one-shot media download/extraction. This skill is for **files**, not summaries.

Common uses:
- Download a video/audio file for offline playback or conversion.
- Fetch subtitles/metadata alongside media.
- Prepare input for audio workflows.

Respect site terms and copyright constraints; do not help pirate paid/restricted content.

## Inspect first

```bash
yt-dlp --dump-json --skip-download '<url>' | jq '{id,title,duration,extractor,webpage_url}'
yt-dlp -F '<url>'
```

## Download best practical MP4

```bash
mkdir -p /tmp/video-downloads
yt-dlp \
  -f 'bv*[ext=mp4]+ba[ext=m4a]/b[ext=mp4]/best' \
  --merge-output-format mp4 \
  -o '/tmp/video-downloads/%(title).120B [%(id)s].%(ext)s' \
  '<url>'
```

## Audio-only extraction

```bash
mkdir -p /tmp/video-downloads
yt-dlp \
  -x --audio-format mp3 --audio-quality 0 \
  -o '/tmp/video-downloads/%(title).120B [%(id)s].%(ext)s' \
  '<url>'
```

For the Tivoli/grandfather MP3 workflow, use the dedicated project scripts in `/projects/youtube-mp3-automation` instead of ad-hoc commands; they handle cookies, dedupe, and history.

## Subtitles with media

```bash
yt-dlp --write-subs --write-auto-subs --sub-langs 'en.*,ru.*,uk.*' '<url>'
```

## Verification

After download:

```bash
ffprobe -hide_banner '<file>'
ls -lh '<file>'
```

For files sent through Telegram, copy to an allowed media/cache directory before using `MEDIA:/path`.

## Hard rules

- Do not download media when transcript/text is enough.
- Do not store large downloads inside source repos.
- Do not commit downloaded media, cookies, or generated subtitle dumps.
- If login/cookies are required, use existing local cookie workflows; never ask the user to paste session cookies into chat.

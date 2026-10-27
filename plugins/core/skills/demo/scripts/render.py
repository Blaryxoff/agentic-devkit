#!/usr/bin/env python3
import argparse
from base64 import b64encode
from html import escape
import json
from pathlib import Path
import re
from urllib.parse import urlsplit


def text(value, field):
    if not isinstance(value, str) or not value.strip():
        raise ValueError(f"{field} must be a nonempty string")
    return escape(value, quote=True)


def image_uri(path):
    data = path.read_bytes()
    if data.startswith(b"\x89PNG\r\n\x1a\n"):
        mime = "image/png"
    elif data.startswith(b"\xff\xd8\xff"):
        mime = "image/jpeg"
    elif data.startswith(b"RIFF") and data[8:12] == b"WEBP":
        mime = "image/webp"
    else:
        raise ValueError(f"Unsupported screenshot format: {path}; use PNG, JPEG or WebP")
    return f"data:{mime};base64,{b64encode(data).decode('ascii')}"


def render(manifest_path, output):
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    title = text(manifest.get("title"), "title")
    items = manifest.get("items")
    if not isinstance(items, list) or not items:
        raise ValueError("items must be a nonempty array")
    labels = {"navigation": "Completed items", "open": "Enlarge", "close": "Close · Esc", "screenshot": "Screenshot"}
    labels.update(manifest.get("labels", {}))
    labels = {key: text(value, f"labels.{key}") for key, value in labels.items()}
    nav, sections, identifiers = [], [], set()
    count = 0
    for index, item in enumerate(items):
        identity = text(item.get("id"), f"items[{index}].id")
        if identity in identifiers:
            raise ValueError(f"Duplicate item ID: {identity}")
        identifiers.add(identity)
        heading = text(item.get("title"), f"items[{index}].title")
        summary = text(item.get("summary"), f"items[{index}].summary")
        images = item.get("images")
        if not isinstance(images, list) or not images:
            raise ValueError(f"Item {identity} needs at least one screenshot")
        nav.append(f'<a href="#item-{index}"><b>{identity}</b><span>{heading}</span></a>')
        figures = []
        for picture in images:
            caption = text(picture.get("caption"), f"Item {identity} image caption")
            path = picture.get("path")
            text(path, f"Item {identity} image path")
            uri = image_uri(manifest_path.parent / path)
            figures.append(f'<figure><button class="shot" type="button" aria-label="{labels["open"]}: {caption}"><img src="{uri}" alt="{caption}"></button><figcaption>{caption} <span>↗ {labels["open"]}</span></figcaption></figure>')
        count += len(images)
        sections.append(f'<section id="item-{index}"><header><span class="number">{identity}</span><div><h2>{heading}</h2><p>{summary}</p></div></header><div class="shots count-{len(images)}">{"".join(figures)}</div></section>')
    source = manifest.get("source")
    source_html = ""
    if source:
        url = source.get("url")
        text(url, "source.url")
        parsed = urlsplit(url)
        if parsed.scheme not in {"https", "http"} or not parsed.netloc or parsed.username or parsed.password:
            raise ValueError("source.url must be an http(s) URL without credentials")
        source_html = f'<a href="{escape(url, quote=True)}" rel="noreferrer">{text(source.get("label"), "source.label")}</a>'
    substitutions = {
        "LANG": text(manifest.get("lang", "en"), "lang"), "TITLE": title,
        "INTRO": text(manifest.get("intro"), "intro"),
        "ENVIRONMENT": text(manifest.get("environment"), "environment"),
        "DATE": text(manifest.get("date"), "date"), "NAV": "".join(nav),
        "SECTIONS": "".join(sections), "SOURCE": source_html,
        "NAV_LABEL": labels["navigation"], "CLOSE": labels["close"], "SHOT_LABEL": labels["screenshot"],
    }
    template = (Path(__file__).parent.parent / "assets" / "gallery.html").read_text(encoding="utf-8")
    page = re.sub(r"@@([A-Z_]+)@@", lambda match: substitutions[match.group(1)], template)
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(page, encoding="utf-8")
    print(f"{output}: {len(items)} items, {count} screenshots, {output.stat().st_size:,} bytes")


def main():
    parser = argparse.ArgumentParser(description="Render a portable screenshot demo from a JSON manifest.")
    parser.add_argument("manifest", type=Path)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    try:
        render(args.manifest.resolve(), args.output.resolve())
    except (OSError, ValueError, KeyError, TypeError, AttributeError) as error:
        parser.exit(1, f"demo: {error}\n")


if __name__ == "__main__":
    main()

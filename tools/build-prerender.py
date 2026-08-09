#!/usr/bin/env python3
"""
Pre-render the gallery grids from content.js into index.html, and emit an
image sitemap covering every catalogued work.

Why: script.js builds the realm, project, object and video grids at runtime,
so the HTML that leaves the server contains none of the artwork titles, alt
text or <img> tags. Search engines do render JavaScript, but on a slower and
less reliable second pass. Baking the initial view into the HTML removes that
dependency entirely.

What it emits is deliberately identical to what script.js produces on first
paint -- same markup, same 16-work slice, same counts -- so the served HTML
and the rendered DOM always agree.

Run after ANY edit to content.js:

    python3 tools/build-prerender.py

Then commit the regenerated index.html and sitemap.xml.
"""

import json
import pathlib
import re
import sys
from datetime import date

ROOT = pathlib.Path(__file__).resolve().parent.parent
SITE = "https://paulboothart.com"

# Mirrors the constants in script.js -- keep in sync.
LABELS = {
    "fine-art": "Fine Art",
    "tattoo": "Tattoo Art",
    "video": "Video Art",
    "3d": "3D Design",
    "jewelry": "Jewelry Design",
}
INITIAL_SHOWN = 16  # script.js: state.shown


def esc(v):
    """Same escaping script.js applies via its esc() helper."""
    return (
        str(v if v is not None else "")
        .replace("&", "&amp;")
        .replace("<", "&lt;")
        .replace(">", "&gt;")
        .replace('"', "&quot;")
    )


def is_motion(w):
    return w.get("mediaType") in ("video", "youtube")


def load_content():
    text = (ROOT / "content.js").read_text(encoding="utf-8")
    return json.loads(text[text.index("{"): text.rindex("}") + 1])


def render_realms(realms):
    out = []
    for i, r in enumerate(realms):
        out.append(
            f'<a class="realm-card reveal" href="{esc(r["href"])}" '
            f"style='--image:url(\"{esc(r['image'])}\")'>"
            f'<span class="realm-index">{i + 1:02d} / REALM</span>'
            f'<h3>{esc(r["title"])}</h3><p>{esc(r["label"])}</p></a>'
        )
    return "".join(out)


def render_projects(works):
    out = []
    for i, w in enumerate(works[:INITIAL_SHOWN]):
        poster = w.get("poster") or w.get("image") or ""
        play = '<span class="card-play" aria-hidden="true">▶</span>' if is_motion(w) else ""
        label = LABELS.get(w.get("category")) or esc(w.get("medium"))
        out.append(
            f'<button class="project-card{" is-video" if is_motion(w) else ""}" '
            f'type="button" data-id="{esc(w["id"])}">'
            f'<span class="project-visual">'
            f'<img src="{esc(poster)}" alt="{esc(w.get("alt"))}" loading="lazy" decoding="async">'
            f'<span class="project-overlay"></span>{play}</span>'
            f'<span class="project-number">{i + 1:03d}</span>'
            f'<span class="project-meta"><span>{label}</span>'
            f'<h3>{esc(w["title"])}</h3></span></button>'
        )
    return "".join(out)


def render_objects(works):
    out = []
    for w in works:
        if w.get("category") not in ("3d", "jewelry"):
            continue
        out.append(
            f'<button class="machine-card" data-id="{esc(w["id"])}">'
            f'<img src="{esc(w.get("image"))}" alt="{esc(w.get("alt"))}" loading="lazy">'
            f'<span>{esc(w["title"])}</span></button>'
        )
    return "".join(out)


def render_videos(works):
    out = []
    motion = [w for w in works if is_motion(w)]
    for i, w in enumerate(motion):
        if w.get("mediaType") == "youtube":
            poster = f'https://i.ytimg.com/vi/{w["youtubeId"]}/hqdefault.jpg'
            player = (
                f'<button class="youtube-poster-button" type="button" '
                f'data-youtube-open="{esc(w["id"])}" aria-label="Open {esc(w["title"])}">'
                f'<img src="{esc(poster)}" alt="{esc(w.get("alt") or w["title"])}" loading="lazy">'
                f'<span class="youtube-play" aria-hidden="true">▶</span>'
                f'<span class="youtube-poster-label">PLAY VIDEO</span></button>'
            )
            source_label = "YOUTUBE VIDEO"
        else:
            player = (
                f'<video controls playsinline preload="metadata" '
                f'poster="{esc(w.get("poster") or "")}">'
                f'<source src="{esc(w.get("src"))}" type="video/mp4">'
                f"Your browser does not support HTML5 video.</video>"
            )
            source_label = "LOCAL VIDEO"
        out.append(
            f'<article class="video-card reveal"><div class="video-frame">{player}</div>'
            f'<div class="video-meta"><span class="eyebrow">{i + 1:02d} / {source_label}</span>'
            f'<h3>{esc(w["title"])}</h3>'
            f'<p>{esc(w.get("description") or w.get("medium"))}</p>'
            f'<button class="text-link video-expand" data-id="{esc(w["id"])}" type="button">'
            f"Open full-screen <span>↗</span></button></div></article>"
        )
    return "".join(out)


def count_text(works):
    """Mirrors script.js render(): the 'all' filter branch."""
    artworks = sum(1 for w in works if not is_motion(w))
    films = sum(1 for w in works if is_motion(w))
    return f"{artworks} artworks · {films} films"


def splice(html, marker, payload):
    """Replace content between <!-- PRERENDER:<marker>:BEGIN/END --> comments."""
    begin, end = f"<!-- PRERENDER:{marker}:BEGIN -->", f"<!-- PRERENDER:{marker}:END -->"
    pattern = re.compile(re.escape(begin) + ".*?" + re.escape(end), re.S)
    if not pattern.search(html):
        sys.exit(f"ERROR: markers for '{marker}' not found in index.html")
    return pattern.sub(begin + payload + end, html, count=1)


def build_sitemap(works):
    """
    Single-page site, so every artwork image belongs to the one canonical URL.
    Image sitemaps are the supported way to surface images that a crawler might
    otherwise only reach through rendered JavaScript.
    """
    seen, entries = set(), []
    for w in works:
        img = w.get("image") or w.get("poster")
        if not img or img.startswith("http") or img in seen:
            continue  # local files only -- an external poster is not ours to declare
        seen.add(img)
        entries.append(
            "    <image:image>\n"
            f"      <image:loc>{SITE}/{esc(img)}</image:loc>\n"
            f"      <image:title>{esc(w['title'])}</image:title>\n"
            f"      <image:caption>{esc(w.get('alt') or w['title'])}</image:caption>\n"
            "    </image:image>"
        )
    return (
        '<?xml version="1.0" encoding="UTF-8"?>\n'
        '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9"\n'
        '        xmlns:image="http://www.google.com/schemas/sitemap-image/1.1">\n'
        "  <url>\n"
        f"    <loc>{SITE}/</loc>\n"
        f"    <lastmod>{date.today().isoformat()}</lastmod>\n"
        "    <changefreq>monthly</changefreq>\n"
        "    <priority>1.0</priority>\n"
        + "\n".join(entries)
        + "\n  </url>\n</urlset>\n"
    ), len(entries)


def main():
    data = load_content()
    realms, works = data["realms"], data["works"]

    html = (ROOT / "index.html").read_text(encoding="utf-8")
    html = splice(html, "realm-grid", render_realms(realms))
    html = splice(html, "project-grid", render_projects(works))
    html = splice(html, "object-grid", render_objects(works))
    html = splice(html, "video-grid", render_videos(works))
    html = splice(html, "fine-art-count", count_text(works))
    (ROOT / "index.html").write_text(html, encoding="utf-8")

    sitemap, n_images = build_sitemap(works)
    (ROOT / "sitemap.xml").write_text(sitemap, encoding="utf-8")

    print(f"index.html   realms={len(realms)} "
          f"projects={min(INITIAL_SHOWN, len(works))}/{len(works)} "
          f"objects={sum(1 for w in works if w.get('category') in ('3d', 'jewelry'))} "
          f"videos={sum(1 for w in works if is_motion(w))}")
    print(f"sitemap.xml  {n_images} images")


if __name__ == "__main__":
    main()

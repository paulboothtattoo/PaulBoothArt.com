# PaulBoothArt.com — AI-Style Fine Arts Site

A from-scratch static build using the visual architecture and navigation language of PaulBooth.ai, adapted for the existing PaulBoothArt.com catalog.

## Run locally

Use any static server, for example:

```bash
python -m http.server 8080
```

Then open `http://localhost:8080`.

## Deploy

Upload the contents of this folder to the document root for PaulBoothArt.com. The build is compatible with Netlify, Vercel static hosting, GitHub Pages, Cloudflare Pages, and conventional web hosting.

## Artwork images

The Fine Arts catalog currently points to the existing Squarespace CDN image URLs so the complete collection can be previewed immediately. Before retiring the Squarespace account, download the original assets, place them in `assets/artwork/`, and update the `image` fields in `content.js` to local paths.

## Editing

- Artwork catalog: `content.js`
- Layout/content: `index.html`
- Visual system: `styles.css`
- Navigation, filters, lightbox and animation: `script.js`


## Video art

The Video Art section now contains seven YouTube works. **Memento Mori** and **Mephisto** have been removed from this PaulBoothArt.com package because they belong on PaulBooth.ai. No local MP4 copies of those works remain in this ZIP.

The seven catalog labels are **Video Art 01–07**. Their YouTube IDs and links are maintained in `content.js`. Update the `title` fields there whenever preferred exhibition titles are available.

Artwork lightboxes default to a full-image fit with no crop. **View actual size** enables scrolling at the source image's natural dimensions, and **Open original** opens the source asset directly.


## YouTube Error 153 / local preview

Do not preview the YouTube players by double-clicking `index.html`. A `file://` page cannot send the HTTP referrer now required by YouTube, so YouTube returns Error 153.

On Windows, double-click `START-PREVIEW.bat`, then use `http://localhost:8080`. On macOS, run `START-PREVIEW.command`. The deployed HTTPS website will also provide a valid referrer automatically.

The site now detects `file://` preview mode and shows a clean poster with a direct YouTube button instead of displaying a broken embedded player.


## Fine Arts section update

The former separate Art Archive section has been removed. Its complete grid, filters, artwork viewer, and load-more controls now live directly inside the Fine Arts section.


## Fixed background hero update
- `assets/background01.png` is the fixed, site-wide background.
- The previous hero background image has been removed from the hero layer.
- The logo remains above the background and uses an idle floating/breathing animation plus subtle pointer tilt on desktop.
- The background itself stays fixed and does not move with the pointer.


## Hero background removal
- The dedicated `.hero-background-layer` element has been removed completely.
- The fixed `assets/background01.png` site background remains visible behind the floating logo.
- Logo animation, vignette, smoke, particles, and interface effects remain intact.


## Hero background correction
The remaining red logo halo, red smoke fields, red cursor glow, and red animated drop shadow were removed. The logo now floats directly over the fixed site artwork with only a neutral black depth shadow and subtle ivory particles.

The source emblem PNG also contained reddish rectangular artwork outside the circular logo. The hero image is now clipped to the circular emblem so that baked-in outer background is not displayed. Cache-busting query strings were added to the CSS and JavaScript references.

## Transparent panel update
The primary section panels, gallery controls, cards, navigation surfaces, forms, and footer now use lower-opacity smoked-glass backgrounds so more of `assets/background01.png` remains visible. Text contrast and modal readability are preserved.


Update: replaced the fixed site background with the uploaded red ornamental artwork and removed dimming overlays so the image displays undimmed.

Update: Explore the Realms photo cards now use true black card backgrounds with darker, higher-contrast imagery instead of gray-toned backgrounds.

Update: the hero animation now uses the uploaded skull logo as a local transparent asset with a new floating/orbital animation system.

Update: increased the hero logo dimensionality with a layered depth pass, perspective tilt, a rear shadow copy, stronger elevation shadows, and a pedestal shadow.

Correction: the hero now uses the exact uploaded LRicon_400x400 image as the visible logo face. It is not regenerated or traced. The 3D effect is created around the original image with a beveled rim, depth layer, cast shadow, glass highlight, and perspective animation.

Correction: the hero medallion now uses the exact logo file from the latest user upload: assets/hero-logo-requested-exact.png. No alternate or processed logo file is used for the visible hero face.

Update: removed the white background behind the hero logo by making the hero medallion face transparent.

Update: the medallion surround has been recolored from silver to a brighter bloody red / rusted shield tone with pitted highlights and darker oxidized recesses.

Update: enhanced the hero with multiple orbit systems, several glowing orb nodes, and a flickering red radiance behind the medallion.

Added to Video Art:
- Video Art 05 — https://youtu.be/BFpSQOAhMdU
- Video Art 06 — https://youtu.be/lZkKbnRLj14
- Video Art 07 — https://youtu.be/AQzSFDiyi64


## Watermark burn-in

This package now includes `assets/skull-watermark.png` and automatically burns that skull watermark into every downloaded Squarespace artwork image inside `content/images/` during migration. It also watermarks the local video poster JPGs in `assets/video-posters/`.

Run `RUN-COMPLETE-MIGRATION.bat`. When it finishes successfully, the output ZIP will be:

- `PaulBoothArt-INDEPENDENT-COMPLETE-WATERMARKED.zip`

That ZIP is the one to extract and upload or push to GitHub.

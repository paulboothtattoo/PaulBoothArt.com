PaulBoothArt.com icon patch

This patch preserves the current site and modifies only icon references in index.html.
The supplied skull image is copied byte-for-byte to assets/paulboothart-site-icon.png.

From the PaulBoothArt.com site folder, run:
powershell -ExecutionPolicy Bypass -File ".\PaulBoothArt-icon-patch\apply-icon.ps1" -SiteRoot "."

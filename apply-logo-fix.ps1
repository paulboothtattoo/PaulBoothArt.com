param(
    [string]$SiteRoot = "."
)

$ErrorActionPreference = "Stop"

$index = Join-Path $SiteRoot "index.html"
if (-not (Test-Path $index)) {
    throw "index.html was not found in $SiteRoot"
}

$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$backup = Join-Path $SiteRoot "index.before-logo-frame-removal.$stamp.html"
Copy-Item $index $backup -Force

$html = Get-Content $index -Raw

$start = "<!-- PBART LOGO FRAME REMOVAL START -->"
$end   = "<!-- PBART LOGO FRAME REMOVAL END -->"

$pattern = [regex]::Escape($start) + ".*?" + [regex]::Escape($end)
$html = [regex]::Replace($html, $pattern, "", [System.Text.RegularExpressions.RegexOptions]::Singleline)

$patch = @'
<!-- PBART LOGO FRAME REMOVAL START -->
<style id="pbart-logo-frame-removal">
  /* Remove the rectangular/square line or shadow around the hero logo
     without changing the logo asset itself. */
  #hero-animation .hero-logo-stage--sigil,
  #hero-animation .hero-medallion,
  #hero-animation .hero-medallion-face {
    background: transparent !important;
    border: 0 !important;
    outline: 0 !important;
    box-shadow: none !important;
  }

  /* The previous hero rule used drop-shadows on the PNG.
     Those can reveal the rectangular bounds of the image. */
  #hero-animation .hero-medallion-face {
    filter: none !important;
    -webkit-filter: none !important;
  }

  /* Kill any frame-producing pseudo layers around the medallion. */
  #hero-animation .hero-medallion::before,
  #hero-animation .hero-medallion::after,
  #hero-animation .hero-medallion-depth,
  #hero-animation .hero-medallion-rim,
  #hero-animation .hero-medallion-glass,
  #hero-animation .hero-logo-stage--sigil .hero-logo-sweep {
    display: none !important;
    opacity: 0 !important;
    visibility: hidden !important;
    background: transparent !important;
    border: 0 !important;
    outline: 0 !important;
    box-shadow: none !important;
    filter: none !important;
    -webkit-filter: none !important;
  }
</style>
<!-- PBART LOGO FRAME REMOVAL END -->
'@

if ($html -notmatch "</head>") {
    throw "Could not find </head> in index.html"
}

$html = $html.Replace("</head>", "$patch`r`n</head>")
Set-Content $index $html -Encoding UTF8

Write-Host ""
Write-Host "PaulBoothArt.com logo frame removal applied."
Write-Host "Backup:"
Write-Host $backup
Write-Host ""
Select-String -Path $index -Pattern "PBART LOGO FRAME REMOVAL|pbart-logo-frame-removal"

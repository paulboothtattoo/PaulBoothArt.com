param([string]$SiteRoot = ".")

$ErrorActionPreference = "Stop"
$index = Join-Path $SiteRoot "index.html"

if (-not (Test-Path $index)) { throw "index.html not found: $index" }

$logo = Join-Path $SiteRoot "assets\hero-logo-requested-exact.png"
if (-not (Test-Path $logo)) {
    throw "Expected PaulBoothArt logo not found: $logo"
}

$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$backup = Join-Path $SiteRoot "index.before-header-logo.$stamp.html"
Copy-Item $index $backup -Force

$html = Get-Content $index -Raw

# Replace only the header mini-brand PB circle, not the footer mark.
$old = '<a class="mini-brand" href="#top" aria-label="PaulBoothArt\.com home">\s*<span class="mini-brand-mark">PB</span>\s*<span>PAULBOOTHART\.COM</span>'
$new = '<a class="mini-brand" href="#top" aria-label="PaulBoothArt.com home">' + "`r`n" +
       '      <img class="mini-brand-logo mini-brand-logo--art" src="assets/hero-logo-requested-exact.png" alt="" aria-hidden="true" />' + "`r`n" +
       '      <span>PAULBOOTHART.COM</span>'

$updated = [regex]::Replace($html, $old, $new, 1)
if ($updated -eq $html) {
    throw "Could not find the PaulBoothArt.com header mini-brand markup to replace."
}
$html = $updated

$start = "<!-- PB-ART HEADER LOGO START -->"
$end = "<!-- PB-ART HEADER LOGO END -->"
$pattern = [regex]::Escape($start) + ".*?" + [regex]::Escape($end)
$html = [regex]::Replace($html, $pattern, "", [System.Text.RegularExpressions.RegexOptions]::Singleline)

$css = @'
<!-- PB-ART HEADER LOGO START -->
<style id="pb-art-header-logo">
  .site-header .mini-brand-logo--art {
    display: block !important;
    width: 38px !important;
    height: 38px !important;
    flex: 0 0 38px !important;
    object-fit: contain !important;
    object-position: center !important;
    border: 0 !important;
    border-radius: 0 !important;
    background: transparent !important;
    box-shadow: none !important;
    filter: none !important;
  }

  @media (max-width: 760px) {
    .site-header .mini-brand-logo--art {
      width: 32px !important;
      height: 32px !important;
      flex-basis: 32px !important;
    }
  }
</style>
<!-- PB-ART HEADER LOGO END -->
'@

if ($html -notmatch "</head>") { throw "Could not find </head>." }
$html = $html.Replace("</head>", "$css`r`n</head>")
Set-Content $index $html -Encoding UTF8

Write-Host ""
Write-Host "PaulBoothArt.com header logo installed."
Write-Host "Backup: $backup"
Write-Host ""
Select-String -Path $index -Pattern "mini-brand-logo--art|PB-ART HEADER LOGO"

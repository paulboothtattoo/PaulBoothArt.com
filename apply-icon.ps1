param(
    [string]$SiteRoot = "."
)

$ErrorActionPreference = "Stop"

$root = (Resolve-Path $SiteRoot).Path
$indexPath = Join-Path $root "index.html"
$assetDir = Join-Path $root "assets"
$sourceIcon = Join-Path $PSScriptRoot "assets\paulboothart-site-icon.png"
$destIcon = Join-Path $assetDir "paulboothart-site-icon.png"

if (-not (Test-Path $indexPath)) {
    throw "index.html was not found in: $root"
}

if (-not (Test-Path $sourceIcon)) {
    throw "Icon file was not found in the patch package."
}

New-Item -ItemType Directory -Path $assetDir -Force | Out-Null
Copy-Item -Path $sourceIcon -Destination $destIcon -Force

$backup = Join-Path $root ("index-before-icon-" + (Get-Date -Format "yyyyMMdd-HHmmss") + ".html")
Copy-Item -Path $indexPath -Destination $backup -Force

$html = Get-Content -Path $indexPath -Raw

# Remove existing favicon / shortcut icon / Apple touch icon declarations only.
$html = [regex]::Replace($html, '(?im)^[ \t]*<link\b[^>]*\brel=["''](?:icon|shortcut icon|apple-touch-icon)["''][^>]*>\s*', '')
$html = [regex]::Replace($html, '(?im)^[ \t]*<link\b[^>]*\brel=["''](?:icon|shortcut icon|apple-touch-icon)["''][^>]*/>\s*', '')

$links = @'
  <link rel="icon" type="image/png" href="assets/paulboothart-site-icon.png?v=20260807" />
  <link rel="shortcut icon" type="image/png" href="assets/paulboothart-site-icon.png?v=20260807" />
  <link rel="apple-touch-icon" href="assets/paulboothart-site-icon.png?v=20260807" />
'@

$themePattern = '(?im)^[ \t]*<meta\s+name=["'']theme-color["''][^>]*>\s*'
$themeMatch = [regex]::Match($html, $themePattern)

if ($themeMatch.Success) {
    $insertAt = $themeMatch.Index + $themeMatch.Length
    $html = $html.Insert($insertAt, $links + "`r`n")
} elseif ($html -match '</head>') {
    $html = $html -replace '</head>', ($links + "`r`n</head>")
} else {
    throw "Could not locate <head> in index.html."
}

Set-Content -Path $indexPath -Value $html -Encoding UTF8

Write-Host ""
Write-Host "PaulBoothArt.com icon updated."
Write-Host "Icon:   assets\paulboothart-site-icon.png"
Write-Host "Backup: $backup"
Write-Host ""
Write-Host "Current icon references:"
Select-String -Path $indexPath -Pattern 'paulboothart-site-icon.png'

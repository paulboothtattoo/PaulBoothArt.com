param([string]$SiteRoot = $PSScriptRoot)
$ErrorActionPreference = "Stop"
Set-Location -LiteralPath $SiteRoot

Write-Host ""
Write-Host "PaulBoothArt.com COMPLETE Squarespace Image Migration + Watermark Burn-In" -ForegroundColor Cyan
Write-Host "Site root: $SiteRoot"
Write-Host ""

$manifestFile = Join-Path $SiteRoot "squarespace-image-manifest.json"
if (!(Test-Path -LiteralPath $manifestFile)) {
  throw "Missing squarespace-image-manifest.json"
}

$watermarkFile = Join-Path $SiteRoot "assets\skull-watermark.png"
if (!(Test-Path -LiteralPath $watermarkFile)) {
  throw "Missing watermark file: assets\\skull-watermark.png"
}

$items = Get-Content -LiteralPath $manifestFile -Raw | ConvertFrom-Json
$imageDir = Join-Path $SiteRoot "content\images"
New-Item -ItemType Directory -Force -Path $imageDir | Out-Null

Add-Type -AssemblyName System.Drawing

function Download-Image {
  param([string]$Url, [string]$Destination)

  $userAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/150 Safari/537.36"
  $headers = @{
    "User-Agent" = $userAgent
    "Referer" = "https://www.paulboothart.com/"
  }

  try {
    Invoke-WebRequest `
      -UseBasicParsing `
      -Uri $Url `
      -OutFile $Destination `
      -Headers $headers `
      -MaximumRedirection 10 `
      -TimeoutSec 120
    return
  }
  catch {
    if (Get-Command curl.exe -ErrorAction SilentlyContinue) {
      & curl.exe `
        -L `
        --fail `
        --retry 3 `
        --retry-delay 2 `
        --connect-timeout 30 `
        --max-time 180 `
        -A $userAgent `
        -e "https://www.paulboothart.com/" `
        -o $Destination `
        $Url

      if ($LASTEXITCODE -eq 0) {
        return
      }
    }

    throw
  }
}

function Get-ImageCodecInfo {
  param([string]$MimeType)
  return [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() |
    Where-Object { $_.MimeType -eq $MimeType } |
    Select-Object -First 1
}

function Save-ImageByExtension {
  param(
    [System.Drawing.Bitmap]$Bitmap,
    [string]$Path,
    [string]$Extension
  )

  switch ($Extension.ToLowerInvariant()) {
    ".jpg" { 
      $codec = Get-ImageCodecInfo -MimeType "image/jpeg"
      $params = New-Object System.Drawing.Imaging.EncoderParameters 1
      $params.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter([System.Drawing.Imaging.Encoder]::Quality, 92L)
      $Bitmap.Save($Path, $codec, $params)
      $params.Dispose()
      break
    }
    ".jpeg" {
      $codec = Get-ImageCodecInfo -MimeType "image/jpeg"
      $params = New-Object System.Drawing.Imaging.EncoderParameters 1
      $params.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter([System.Drawing.Imaging.Encoder]::Quality, 92L)
      $Bitmap.Save($Path, $codec, $params)
      $params.Dispose()
      break
    }
    ".png" { $Bitmap.Save($Path, [System.Drawing.Imaging.ImageFormat]::Png); break }
    ".bmp" { $Bitmap.Save($Path, [System.Drawing.Imaging.ImageFormat]::Bmp); break }
    ".gif" { $Bitmap.Save($Path, [System.Drawing.Imaging.ImageFormat]::Gif); break }
    ".tif" { $Bitmap.Save($Path, [System.Drawing.Imaging.ImageFormat]::Tiff); break }
    ".tiff" { $Bitmap.Save($Path, [System.Drawing.Imaging.ImageFormat]::Tiff); break }
    default { $Bitmap.Save($Path, [System.Drawing.Imaging.ImageFormat]::Png); break }
  }
}

function Apply-Watermark {
  param(
    [string]$TargetPath,
    [string]$WatermarkPath
  )

  $extension = [System.IO.Path]::GetExtension($TargetPath)
  if ([string]::IsNullOrWhiteSpace($extension)) { return }

  $supported = @(".jpg", ".jpeg", ".png", ".bmp", ".gif", ".tif", ".tiff")
  if ($supported -notcontains $extension.ToLowerInvariant()) {
    Write-Host ("Skipping unsupported format: " + $TargetPath)
    return
  }

  $source = $null
  $watermark = $null
  $canvas = $null
  $graphics = $null
  $attributes = $null

  try {
    $source = [System.Drawing.Image]::FromFile($TargetPath)
    $watermark = [System.Drawing.Image]::FromFile($WatermarkPath)

    $canvas = New-Object System.Drawing.Bitmap($source.Width, $source.Height, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $graphics = [System.Drawing.Graphics]::FromImage($canvas)
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
    $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality

    $graphics.DrawImage($source, 0, 0, $source.Width, $source.Height)

    $targetShortSide = [Math]::Min($source.Width, $source.Height)
    $maxWatermarkSide = [Math]::Max(120, [int][Math]::Round($targetShortSide * 0.18))
    $scale = [Math]::Min($maxWatermarkSide / $watermark.Width, $maxWatermarkSide / $watermark.Height)
    if ($scale -le 0) { $scale = 1.0 }

    $wmWidth = [Math]::Max(1, [int][Math]::Round($watermark.Width * $scale))
    $wmHeight = [Math]::Max(1, [int][Math]::Round($watermark.Height * $scale))
    $margin = [Math]::Max(18, [int][Math]::Round($targetShortSide * 0.025))

    $x = $source.Width - $wmWidth - $margin
    $y = $source.Height - $wmHeight - $margin
    if ($x -lt 0) { $x = 0 }
    if ($y -lt 0) { $y = 0 }

    $matrix = New-Object System.Drawing.Imaging.ColorMatrix
    $matrix.Matrix00 = 1.0
    $matrix.Matrix11 = 1.0
    $matrix.Matrix22 = 1.0
    $matrix.Matrix33 = 0.17
    $matrix.Matrix44 = 1.0

    $attributes = New-Object System.Drawing.Imaging.ImageAttributes
    $attributes.SetColorMatrix($matrix, [System.Drawing.Imaging.ColorMatrixFlag]::Default, [System.Drawing.Imaging.ColorAdjustType]::Bitmap)

    $destRect = New-Object System.Drawing.Rectangle($x, $y, $wmWidth, $wmHeight)
    $graphics.DrawImage(
      $watermark,
      $destRect,
      0,
      0,
      $watermark.Width,
      $watermark.Height,
      [System.Drawing.GraphicsUnit]::Pixel,
      $attributes
    )

    $tempPath = $TargetPath + ".wmtemp"
    if (Test-Path -LiteralPath $tempPath) {
      Remove-Item -LiteralPath $tempPath -Force
    }

    Save-ImageByExtension -Bitmap $canvas -Path $tempPath -Extension $extension

    if (Test-Path -LiteralPath $tempPath) {
      Move-Item -LiteralPath $tempPath -Destination $TargetPath -Force
    }
  }
  finally {
    if ($attributes) { $attributes.Dispose() }
    if ($graphics) { $graphics.Dispose() }
    if ($canvas) { $canvas.Dispose() }
    if ($watermark) { $watermark.Dispose() }
    if ($source) { $source.Dispose() }
  }
}

$failed = @()
$count = 0

foreach ($item in $items) {
  $count++
  $destination = Join-Path $imageDir $item.filename

  try {
    if (!(Test-Path -LiteralPath $destination) -or ((Get-Item -LiteralPath $destination).Length -lt 100)) {
      Write-Host ("[{0}/{1}] {2}" -f $count, $items.Count, $item.filename)
      Download-Image -Url $item.url -Destination $destination
    }
    else {
      Write-Host ("[{0}/{1}] already present: {2}" -f $count, $items.Count, $item.filename)
    }

    if (!(Test-Path -LiteralPath $destination) -or ((Get-Item -LiteralPath $destination).Length -lt 100)) {
      throw "File missing or empty"
    }
  }
  catch {
    $failed += [PSCustomObject]@{
      url = $item.url
      file = $item.filename
      error = $_.Exception.Message
    }

    Write-Warning ("FAILED: " + $item.url)
  }
}

if ($failed.Count -gt 0) {
  $failed |
    ConvertTo-Json -Depth 4 |
    Set-Content -LiteralPath (Join-Path $SiteRoot "SQUARESPACE-DOWNLOAD-FAILURES.json") -Encoding UTF8

  Write-Host ""
  Write-Host ("FAILED: {0} image(s) could not be downloaded." -f $failed.Count) -ForegroundColor Red
  Write-Host "Squarespace has NOT been removed. Run this again before canceling it."
  exit 1
}

Write-Host ""
Write-Host "Burning watermark into downloaded artwork images..." -ForegroundColor Yellow
$watermarkedCount = 0
Get-ChildItem -LiteralPath $imageDir -File |
  ForEach-Object {
    Apply-Watermark -TargetPath $_.FullName -WatermarkPath $watermarkFile
    $watermarkedCount++
    Write-Host ("Watermarked: " + $_.Name)
  }

$videoPosterDir = Join-Path $SiteRoot "assets\video-posters"
if (Test-Path -LiteralPath $videoPosterDir) {
  Get-ChildItem -LiteralPath $videoPosterDir -File |
    ForEach-Object {
      Apply-Watermark -TargetPath $_.FullName -WatermarkPath $watermarkFile
      Write-Host ("Watermarked poster: " + $_.Name)
    }
}

$patterns = @("*.html", "*.css", "*.js", "*.json", "*.xml", "*.txt", "*.md")
$files = @()

foreach ($filePattern in $patterns) {
  $files += Get-ChildItem -LiteralPath $SiteRoot -Recurse -File -Filter $filePattern |
    Where-Object {
      $_.Name -ne "squarespace-image-manifest.json" -and
      $_.Name -ne "SQUARESPACE-ASSET-AUDIT.json" -and
      $_.Name -ne "SQUARESPACE-DOWNLOAD-FAILURES.json"
    }
}

$files = $files | Sort-Object FullName -Unique

foreach ($file in $files) {
  $original = Get-Content -LiteralPath $file.FullName -Raw
  $updated = $original

  foreach ($item in $items) {
    $updated = $updated.Replace([string]$item.url, [string]$item.sitePath)
  }

  if ($updated -ne $original) {
    [System.IO.File]::WriteAllText(
      $file.FullName,
      $updated,
      (New-Object System.Text.UTF8Encoding($false))
    )

    Write-Host ("Rewritten: " + $file.FullName.Substring($SiteRoot.Length).TrimStart("\"))
  }
}

$remaining = @()

foreach ($file in $files) {
  $content = Get-Content -LiteralPath $file.FullName -Raw

  if ($content -match "squarespace-cdn\.com|static1\.squarespace\.com|static\.squarespace\.com") {
    $remaining += $file.FullName.Substring($SiteRoot.Length).TrimStart("\")
  }
}

$actualImages = @(Get-ChildItem -LiteralPath $imageDir -File)

$audit = [PSCustomObject]@{
  runAt = (Get-Date).ToString("o")
  expectedSquarespaceImages = $items.Count
  localImageFiles = $actualImages.Count
  watermarkedImageFiles = $watermarkedCount
  failedAssets = 0
  remainingSquarespaceReferences = $remaining.Count
  filesStillContainingSquarespaceReferences = $remaining
  status = $(if (($actualImages.Count -eq $items.Count) -and ($remaining.Count -eq 0)) {
    "PASS - all images are local, watermarked, and Squarespace dependencies are removed"
  } else {
    "FAIL - migration incomplete"
  })
}

$audit |
  ConvertTo-Json -Depth 5 |
  Set-Content -LiteralPath (Join-Path $SiteRoot "SQUARESPACE-ASSET-AUDIT.json") -Encoding UTF8

if ($audit.status -notlike "PASS*") {
  Write-Host "Migration audit failed." -ForegroundColor Red
  exit 1
}

$completedZip = Join-Path (Split-Path $SiteRoot -Parent) "PaulBoothArt-INDEPENDENT-COMPLETE-WATERMARKED.zip"

if (Test-Path -LiteralPath $completedZip) {
  Remove-Item -LiteralPath $completedZip -Force
}

Compress-Archive `
  -Path (Join-Path $SiteRoot "*") `
  -DestinationPath $completedZip `
  -CompressionLevel Optimal

Write-Host ""
Write-Host "SUCCESS" -ForegroundColor Green
Write-Host ("Downloaded and stored {0} actual images in content\\images." -f $actualImages.Count)
Write-Host ("Watermarked {0} downloaded artwork images." -f $watermarkedCount)
Write-Host "All Squarespace links were removed."
Write-Host ("Completed deployable ZIP: " + $completedZip)
Write-Host "Audit: SQUARESPACE-ASSET-AUDIT.json"
exit 0

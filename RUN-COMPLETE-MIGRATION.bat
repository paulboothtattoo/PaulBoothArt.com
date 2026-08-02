@echo off
setlocal
pushd "%~dp0"

echo.
echo PaulBoothArt.com - Download actual images, burn in watermark, and build independent site
echo.

powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File ".\MIGRATE-AND-BUILD-COMPLETE-SITE.ps1" -SiteRoot "%CD%"

set "CODE=%ERRORLEVEL%"

echo.
if "%CODE%"=="0" (
  echo COMPLETE. Look one folder above for PaulBoothArt-INDEPENDENT-COMPLETE-WATERMARKED.zip
) else (
  echo Migration did not complete. Do not cancel Squarespace.
)
echo.
pause

popd
exit /b %CODE%

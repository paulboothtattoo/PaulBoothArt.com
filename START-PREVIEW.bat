@echo off
setlocal
cd /d "%~dp0"
echo.
echo Starting PaulBoothArt.com preview at http://localhost:8080
echo Keep this window open while previewing the site.
echo.
start "" "http://localhost:8080"
where py >nul 2>nul
if %errorlevel%==0 (
  py -m http.server 8080
  goto :eof
)
where python >nul 2>nul
if %errorlevel%==0 (
  python -m http.server 8080
  goto :eof
)
echo Python was not found. Deploy the folder to your web host, or install Python and run this file again.
pause

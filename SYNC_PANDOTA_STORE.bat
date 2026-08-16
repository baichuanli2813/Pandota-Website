@echo off
title Pandota Store Live Sync
echo ========================================================
echo   PANDOTA LTD - 1-CLICK LIVE STORE SYNC
echo ========================================================
echo.
echo Connecting to eBay, fetching live listings and feedbacks...
echo.

powershell -ExecutionPolicy Bypass -File "%~dp0sync_now.ps1"

echo.
echo ========================================================
echo   SYNC COMPLETE!
echo   Open GitHub Desktop, commit, and click "Push origin".
echo ========================================================
echo.
pause

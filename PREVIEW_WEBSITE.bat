@echo off
title Pandota Website - Local Preview Server
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File ".\preview_server.ps1"
pause

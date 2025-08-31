@echo off
title Wallpaper Updater
echo.
echo Launching Wallpaper Updater...
echo.

:: Define log path
set "logFolder=%LOCALAPPDATA%\Wallpapers"
set "logFile=%logFolder%\Wallpaper.log"

:: Ensure log folder exists
if not exist "%logFolder%" (
    mkdir "%logFolder%"
)

:: Write launch timestamp
echo [%date% %time%] Launching updater >> "%logFile%"

:: Define script path
set "script=%~dp0WallpaperUpdater.ps1"

:: Check if PowerShell 7 (pwsh.exe) is available
where pwsh >nul 2>nul
if %errorlevel%==0 (
    echo PowerShell 7 detected — using pwsh >> "%logFile%"
    pwsh -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%script%"
) else (
    echo PowerShell 7 not found — falling back to Windows PowerShell >> "%logFile%"
    powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%script%"
)
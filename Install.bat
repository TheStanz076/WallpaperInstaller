@echo off
setlocal

echo Installing Bing Wallpaper Automation...

:: Set target folder
set "target=%USERPROFILE%\Wallpapers"

:: Create folders
mkdir "%target%"
mkdir "%target%\Fallback"
mkdir "%target%\Archive"

:: Copy script and fallback images
xcopy /Y /E "%~dp0Set-BingWallpaper.ps1" "%target%\Set-BingWallpaper.ps1"
xcopy /Y /E "%~dp0Fallback" "%target%\Fallback"

:: Register scheduled task
schtasks /create /tn "BingWallpaperUpdater" /tr "powershell.exe -ExecutionPolicy Bypass -File \"%target%\Set-BingWallpaper.ps1\"" /sc daily /st 07:00

echo Installation complete.
pause
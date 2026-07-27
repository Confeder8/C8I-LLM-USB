@echo off
title Update GGUF Models Directory
color 0B

echo ===================================================
echo     UPDATE GGUF MODELS DIRECTORY
echo ===================================================
echo.
echo  This scans the models\ folder for any new .gguf files
echo  you copied manually and adds them to the install menu
echo  with their HuggingFace download links.
echo.
echo  - Place any .gguf files in models\ first
echo  - Run this script to register them
echo  - They will appear in install-core.ps1 menu
echo.
pause

:: Run the PowerShell update script from the same folder as this bat file
powershell -ExecutionPolicy Bypass -File "%~dp0update-models.ps1"

echo.
echo ===================================================
echo     UPDATE COMPLETE!
echo ===================================================
echo.
pause

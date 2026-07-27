@echo off
title Portable AI - Download GGUF Models
color 0B

echo ===================================================
echo     PORTABLE AI USB - Download GGUF Models
echo ===================================================
echo.
echo This will download AI models from HuggingFace
echo onto your USB drive. You'll get to CHOOSE which
echo models to download from a curated list.
echo.
echo  - Load from models.json catalog (40+ models)
echo  - Custom model support (bring your own GGUF URL)
echo  - Auto-imports into Ollama engine
echo.
pause

powershell -ExecutionPolicy Bypass -NoProfile -File "%~dp0download-models.ps1"

echo.
echo ===================================================
echo  Download complete! Press any key to exit...
echo ===================================================
pause >nul

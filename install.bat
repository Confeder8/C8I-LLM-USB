@echo off
title Portable AI - Multi-Model Setup
color 0E

echo   ____             __          _           ___                
echo  / ___^|___  _ __  / _^| ___  __^| ^| ___ _ __( _ )               
echo ^| ^|   / _ \^| '_ \^| ^|_ / _ \/ _` ^|/ _ \ '__/ _ \               
echo ^| ^|__^| (_) ^| ^| ^| ^|  _^|  __/ (_^| ^|  __/ ^| ^| (_) ^|              
echo  \____\___/^|_^| ^|_^|_^|  \___^|\__,_^|\___^|_^|_ \___/             _ 
echo ^|_ _^|_ __ ^| ^|_ ___ _ __ _ __   __ _^| ^|_(_) ___  _ __   __ _^| ^|
echo  ^| ^|^| '_ \^| __/ _ \ '__^| '_ \ / _` ^| __^| ^|/ _ \^| '_ \ / _` ^| ^|
echo  ^| ^|^| ^| ^| ^| ^|^|  __/ ^|  ^| ^| ^| ^| (_^| ^| ^|_^| ^| (_) ^| ^| ^| ^| (_^| ^| ^|
echo ^|___^|_^| ^|_^|\__\___^|_^|  ^|_^| ^|_^|\__,_^|\__^|_^|\___/^|_^| ^|_^|\__,_^|_^|
echo.
echo ===================================================
echo     PORTABLE UNCENSORED AI - USB SETUP
echo ===================================================
echo.
echo.
echo.
echo This will download and configure AI models onto
echo your USB drive. You'll get to CHOOSE which models
echo to install from a curated list.
echo.
echo  - 45 preset models (uncensored + standard + custom)
echo  - Custom model support (bring your own GGUF)
echo  - Minimum USB space: 32 GB (64 GB recommended)
echo.
echo Make sure you have a good internet connection!
echo.
pause

:: Download portable Python to USB if not present
echo.
echo ===================================================
echo  Checking portable Python on USB...
echo ===================================================
echo.

set "USB_PYTHON=%~dp0python\python.exe"
set "INSTALLER_DATA=%~dp0installer_data"

if exist "%USB_PYTHON%" (
    echo [OK] Portable Python already installed on USB.
    goto :PythonDone
)

echo Downloading portable Python (~11MB)...
if not exist "%~dp0python" mkdir "%~dp0python"

:: Check installer_data first
set "PY_ZIP=%INSTALLER_DATA%\python\python-3.12.10-embed-amd64.zip"
if exist "%PY_ZIP%" (
    echo [OK] Using cached Python from installer_data.
    copy "%PY_ZIP%" "%~dp0python-embed.zip" >nul 2>&1
    goto :ExtractPython
)

curl -L "https://www.python.org/ftp/python/3.12.10/python-3.12.10-embed-amd64.zip" -o "%~dp0python-embed.zip"
if %errorlevel% neq 0 (
    echo Download failed. Please check your internet connection.
    pause
    exit /b
)

:ExtractPython
echo Extracting...
powershell -Command "Expand-Archive -Path '%~dp0python-embed.zip' -DestinationPath '%~dp0python' -Force"
del "%~dp0python-embed.zip" >nul 2>&1

:: Enable pip by uncommenting import site in python312._pth
powershell -Command "$p = '%~dp0python\python312._pth'; if (Test-Path $p) { (Get-Content $p) -replace '#import site', 'import site' | Set-Content $p }"

if exist "%USB_PYTHON%" (
    echo [OK] Portable Python installed on USB.
) else (
    echo Failed to extract Python. Please try again.
    pause
    exit /b
)

:PythonDone
echo.

:: Install pip and HuggingFace Hub
echo ===================================================
echo  Setting up HuggingFace Hub for model downloads...
echo ===================================================
echo.

:: Check if pip is installed
"%USB_PYTHON%" -m pip --version >nul 2>&1
if %errorlevel% neq 0 (
    echo Installing pip...
    curl -L -s "https://bootstrap.pypa.io/get-pip.py" -o "%~dp0python\get-pip.py"
    "%USB_PYTHON%" "%~dp0python\get-pip.py"
    del "%~dp0python\get-pip.py" >nul 2>&1
)

:: Check if huggingface_hub is installed
"%USB_PYTHON%" -c "import huggingface_hub" >nul 2>&1
if %errorlevel% neq 0 (
    echo Installing huggingface_hub...
    "%USB_PYTHON%" -m pip install --quiet huggingface_hub
)

"%USB_PYTHON%" -c "import huggingface_hub; print('[OK] huggingface_hub', huggingface_hub.__version__)" 2>nul
if %errorlevel% neq 0 (
    echo [WARN] huggingface_hub install failed. Downloads will use curl fallback.
)

echo.

:: Download G0DM0D3 if not present
echo ===================================================
echo  Checking G0DM0D3 (multi-model AI research tool)...
echo ===================================================
echo.

set "GODMOD3_DIR=%~dp0godmod3"
set "GODMOD3_FILE=%GODMOD3_DIR%\index.html"

if exist "%GODMOD3_FILE%" (
    echo [OK] G0DM0D3 already installed on USB.
    goto :Godmod3Done
)

:: Check installer_data first
if exist "%INSTALLER_DATA%\godmod3\index.html" (
    if not exist "%GODMOD3_DIR%" mkdir "%GODMOD3_DIR%"
    copy "%INSTALLER_DATA%\godmod3\index.html" "%GODMOD3_FILE%" >nul 2>&1
    echo [OK] G0DM0D3 restored from installer_data.
    goto :Godmod3Done
)

if not exist "%GODMOD3_DIR%" mkdir "%GODMOD3_DIR%"
echo Downloading G0DM0D3 (single-file browser app)...
curl -L "https://raw.githubusercontent.com/elder-plinius/G0DM0D3/main/index.html" -o "%GODMOD3_FILE%"
if %errorlevel% NEQ 0 (
    echo [WARN] G0DM0D3 download failed. You can install it later manually.
    echo        Place index.html in the godmod3\ folder.
) else (
    echo [OK] G0DM0D3 installed on USB.
)

:Godmod3Done
echo.

:: Download GGUFLoader if not present
echo ===================================================
echo  Checking GGUFLoader (local GGUF model runner)...
echo ===================================================
echo.

set "GGUF_DIR=%~dp0ggufloader"
set "GGUF_EXE=%GGUF_DIR%\GGUFLoader.exe"

if exist "%GGUF_EXE%" (
    echo [OK] GGUFLoader already installed on USB.
    goto :GGUFDone
)

:: Check installer_data first (use v2.0.1)
if exist "%INSTALLER_DATA%\ggufloader\GGUFLoader_v2.0.1.exe" (
    if not exist "%GGUF_DIR%" mkdir "%GGUF_DIR%"
    copy "%INSTALLER_DATA%\ggufloader\GGUFLoader_v2.0.1.exe" "%GGUF_EXE%" >nul 2>&1
    echo [OK] GGUFLoader restored from installer_data.
    goto :GGUFDone
)

if not exist "%GGUF_DIR%" mkdir "%GGUF_DIR%"
echo Downloading GGUFLoader v2.0.1 (~72MB)...
curl -L "https://github.com/GGUFloader/gguf-loader/releases/download/v2.0.1/GGUFLoader.2.0.1.exe" -o "%GGUF_EXE%"
if %errorlevel% NEQ 0 (
    echo [WARN] GGUFLoader download failed. You can install it later manually.
    echo        Place GGUFLoader.exe in the ggufloader\ folder.
) else (
    echo [OK] GGUFLoader installed on USB.
)

:GGUFDone
echo.

:: Run the PowerShell setup script from the same folder as this bat file
"%~dp0python\python.exe" -c "import sys; print('Python', sys.version)" 2>nul
echo.

powershell -ExecutionPolicy Bypass -File "%~dp0install-core.ps1"

echo.
echo ===================================================
echo  Setup complete! Press any key to exit...
echo ===================================================
pause >nul
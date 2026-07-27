@echo off
setlocal enabledelayedexpansion

:: Organize flat GGUF files into LM Studio directory structure
:: Structure: models/<Publisher>/<ModelName>/<file>.gguf
::
:: Uses PowerShell script if available, Python next, then batch fallback.

set "SCRIPT_DIR=%~dp0"
set "ROOT_DIR=%SCRIPT_DIR%models"
set "PYTHON_CMD=%SCRIPT_DIR%python\python.exe"
set "ORGANIZE_SCRIPT=%SCRIPT_DIR%organize_models.py"
set "PS_SCRIPT=%SCRIPT_DIR%organize_models.ps1"
set "RAN=0"

:: Try PowerShell first
if exist "%PS_SCRIPT%" (
    echo Organizing models using PowerShell - reads HF metadata...
    echo.
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%PS_SCRIPT%" "%ROOT_DIR%"
    set "RAN=1"
)

:: Try Python next
if "!RAN!"=="0" if exist "%PYTHON_CMD%" if exist "%ORGANIZE_SCRIPT%" (
    echo Organizing models using Python - reads HF metadata...
    echo.
    "%PYTHON_CMD%" "%ORGANIZE_SCRIPT%" "%ROOT_DIR%"
    set "RAN=1"
)

:: Fallback: batch logic (uses filename guessing) only if nothing ran
if "!RAN!"=="1" goto :Done

cd /d "%ROOT_DIR%"

echo Organizing GGUF files into LM Studio structure...
echo Structure: models/^<Publisher^>/^<ModelName^>/^<file^>.gguf
echo ==========================================

for %%F in (*.gguf) do (
    set "FILE_NAME=%%~nF"

    :: Guess publisher from filename (first part before first dash)
    set "PUBLISHER=local"
    for /f "tokens=1 delims=-" %%P in ("!FILE_NAME!") do (
        set "CANDIDATE=%%P"
        if not "!CANDIDATE!"=="" if not "!CANDIDATE!"=="!FILE_NAME!" set "PUBLISHER=!CANDIDATE!"
    )

    set "TARGET_DIR=%ROOT_DIR%!PUBLISHER!\!FILE_NAME!"

    echo.
    echo Found model: %%F
    echo   Publisher: !PUBLISHER!
    echo   Target: !PUBLISHER!/!FILE_NAME!/

    if not exist "!TARGET_DIR!" mkdir "!TARGET_DIR!"

    if exist "!TARGET_DIR!\%%F" (
        echo   SKIP (already exists)
        del "%%F" >nul 2>&1
    ) else (
        move "%%F" "!TARGET_DIR!\" >nul
        echo   MOVED
    )

    :: Also move matching Modelfile
    if exist "Modelfile-!FILE_NAME!" (
        if not exist "!TARGET_DIR!\Modelfile" (
            move "Modelfile-!FILE_NAME!" "!TARGET_DIR!\Modelfile" >nul
            echo   + Modelfile copied
        ) else (
            del "Modelfile-!FILE_NAME!" >nul 2>&1
        )
    )
)

:Done
echo.
echo ==========================================
echo Done! All models use LM Studio directory structure.
echo.
echo To register with Ollama, run: ollama create modelname -f Modelfile
echo (from inside each model directory)
echo.
pause

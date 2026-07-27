@echo off
setlocal enabledelayedexpansion
title Portable AI Launcher - Optimized Edition
color 0B

set "USB_ROOT=%~dp0"
set "DATA_DIR=%USB_ROOT%anythingllm_data"
set "OLLAMA_DIR=%USB_ROOT%ollama"
set "OLLAMA_MODELS=%OLLAMA_DIR%\data"
set "PYTHON_CMD=%USB_ROOT%python\python.exe"
set "HF_SCRIPT=%USB_ROOT%hf_cli.py"
set "CLOUD_ROOT=%USB_ROOT%puter_chat"
set "CLOUD_PORT=3377"
set "CLOUD_PROFILE=%USB_ROOT%puter_chat\browser_profile"
set "PUTER_ROOT=%USB_ROOT%puter_chat"
set "PUTER_PORT=3378"
set "PUTER_PROFILE=%USB_ROOT%puter_chat\puter_profile"

:ShowMenu
echo.
cls
echo ===================================================
echo     PORTABLE AI - OPTIMIZED EDITION
echo ===================================================
echo.
echo  Select interface to launch:
echo.
echo    [1] AnythingLLM   (Desktop GUI)
echo    [2] Browser Chat   (Web UI at localhost:3333)
echo    [3] G0DM0D3        (Multi-model AI research)
echo    [4] llama.cpp      (Direct GGUF server)
echo    [5] LM Studio      (GUI model browser + server)
echo    [6] Cloud AI       (Puter.js - cloud GPT/Claude/Gemini)
echo    [7] Puter.com      (Full cloud OS in browser)
echo    [8] HF Download    (Download models from HuggingFace)
echo    [9] Exit
echo.
echo ===================================================
echo.
set /p "choice=  Enter choice (1-9): "

if "!choice!"=="1" goto :AnythingLLM
if "!choice!"=="2" goto :BrowserChat
if "!choice!"=="3" goto :Godmod3
if "!choice!"=="4" goto :LlamaCpp
if "!choice!"=="5" goto :LMStudio
if "!choice!"=="6" goto :CloudAI
if "!choice!"=="7" goto :PuterSite
if "!choice!"=="8" goto :HFDownload
if "!choice!"=="9" exit /b
goto :ShowMenu

:: -------------------------------------------------------
:: COMMON: Kill existing processes
:: -------------------------------------------------------
:KillExisting
taskkill /F /T /IM "ollama*" >nul 2>&1
taskkill /F /T /IM "AnythingLLM*" >nul 2>&1
taskkill /F /T /IM "chat_server*" >nul 2>&1
taskkill /F /T /IM "llama-server*" >nul 2>&1
for /f "tokens=5" %%a in ('netstat -ano ^| find ":3001"') do (
    taskkill /F /PID %%a >nul 2>&1
)
timeout /t 2 /nobreak >nul
taskkill /F /T /IM "ollama*" >nul 2>&1
timeout /t 1 /nobreak >nul
goto :eof

:: -------------------------------------------------------
:: COMMON: Start Ollama
:: -------------------------------------------------------
:StartOllama
echo [+] Starting Ollama engine...
if not exist "%OLLAMA_DIR%\ollama.exe" (
    echo [ERROR] ollama.exe not found at %OLLAMA_DIR%
    pause & exit /b
)

:: Aggressively clear port 11434 to outlast any auto-restarting service
set /a "killAttempt=0"
:KillOllamaRetry
set /a "killAttempt+=1"
if !killAttempt! GEQ 5 goto :OllamaPortsClear
taskkill /F /T /IM "ollama*" >nul 2>&1
timeout /t 2 /nobreak >nul
:: Check if something respawned on 11434
curl -s -m 1 http://127.0.0.1:11434/api/tags >nul 2>&1
if !errorlevel! EQU 0 goto :KillOllamaRetry
:OllamaPortsClear

set "OLLAMA_ORIGINS=*"
set "OLLAMA_MODELS=%OLLAMA_DIR%\data"
set "OLLAMA_KEEP_ALIVE=30m"
set "OLLAMA_MAX_LOADED_MODELS=1"
set "OLLAMA_FLASH_ATTENTION=1"
start "Ollama Engine" /B /Abovenormal "%OLLAMA_DIR%\ollama.exe" serve

set /a "attempts=0"
:WaitLoop
set /a "attempts+=1"
if !attempts! GEQ 40 (
    echo [ERROR] Ollama failed to start after 80 seconds.
    pause & exit /b
)
curl -s -m 2 http://127.0.0.1:11434/api/tags >nul 2>&1 && goto :OllamaReady
<nul set /p "=."
timeout /t 2 /nobreak >nul
goto :WaitLoop
:OllamaReady
echo. [OK] Engine is online.
:: Verify Ollama can see models (confirms correct data dir)
for /f %%m in ('curl -s -m 5 http://127.0.0.1:11434/api/tags 2^>nul ^| find /c "name"') do (
    if %%m EQU 0 (
        echo [WARN] Ollama has no models. Ensure OLLAMA_MODELS points to correct dir.
    ) else (
        echo [OK] Ollama has models loaded.
    )
)
goto :eof

:: -------------------------------------------------------
:: COMMON: Cleanup helper (called by PowerShell)
:: -------------------------------------------------------
:ForceCleanup
echo.
echo [+] Shutting down...
taskkill /F /T /IM "AnythingLLM.exe" >nul 2>&1
taskkill /F /T /IM "chat_server*" >nul 2>&1
taskkill /F /T /IM "python*" >nul 2>&1
taskkill /F /T /IM "llama-server*" >nul 2>&1
timeout /t 1 /nobreak >nul
taskkill /F /T /IM "ollama.exe" >nul 2>&1
if exist "%DATA_DIR%" echo. > "%DATA_DIR%\sync.tmp" 2>nul & del /q "%DATA_DIR%\sync.tmp" 2>nul
echo [DONE] All services stopped.
goto :eof

:: -------------------------------------------------------
:: COMMON: Find browser (sets BROWSER_EXE)
:: -------------------------------------------------------
:FindBrowser
set "BROWSER_EXE="
where chrome >nul 2>&1
if !errorlevel! EQU 0 (set "BROWSER_EXE=chrome" & goto :eof)
for %%p in (
    "C:\Program Files\Google\Chrome\Application\chrome.exe"
    "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe"
) do if exist %%p (set "BROWSER_EXE=%%~p" & goto :eof)
where msedge >nul 2>&1
if !errorlevel! EQU 0 (set "BROWSER_EXE=msedge" & goto :eof)
for %%p in (
    "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
    "C:\Program Files\Microsoft\Edge\Application\msedge.exe"
) do if exist %%p (set "BROWSER_EXE=%%~p" & goto :eof)
where firefox >nul 2>&1
if !errorlevel! EQU 0 (set "BROWSER_EXE=firefox" & goto :eof)
for %%p in (
    "C:\Program Files\Mozilla Firefox\firefox.exe"
    "C:\Program Files (x86)\Mozilla Firefox\firefox.exe"
) do if exist %%p (set "BROWSER_EXE=%%~p" & goto :eof)
goto :eof

:: -------------------------------------------------------
:: COMMON: Open URL in browser with fresh profile
::         Arg1 = profile dir, Arg2 = URL
:: -------------------------------------------------------
:OpenInBrowser
call :FindBrowser
if defined BROWSER_EXE (
    start /wait "" "!BROWSER_EXE!" --new-window --no-first-run --no-default-browser-check --disable-popup-blocking --disable-session-crashed-bubble --disable-restore-session-state --user-data-dir="%~1" --start-maximized "%~2"
) else (
    start /wait "" "%~2"
)
goto :eof

:: -------------------------------------------------------
:: Start PowerShell watchdog (monitors THIS cmd window)
:: -------------------------------------------------------
:StartWatchdog
:: Get PID of current cmd.exe hosting this batch
set "MY_PID="
for /f "tokens=2 delims=," %%i in ('tasklist /FI "IMAGENAME eq cmd.exe" /FO CSV /NH 2^>nul') do (
    set "RAW=%%~i"
    set "CANDIDATE=!RAW: =!"
    if not defined MY_PID set "MY_PID=!CANDIDATE!"
)

:: Launch background watchdog that kills our processes if this cmd dies
if defined MY_PID (
    start "" /B powershell -NoProfile -WindowStyle Hidden -Command ^
        "while ($true) { Start-Sleep -Seconds 3; " ^
        "$proc = Get-Process -Id %MY_PID% -ErrorAction SilentlyContinue; " ^
        "if (-not $proc) { " ^
        "Stop-Process -Name 'AnythingLLM' -Force -ErrorAction SilentlyContinue; " ^
        "Stop-Process -Name 'ollama' -Force -ErrorAction SilentlyContinue; " ^
        "Stop-Process -Name 'chat_server*' -Force -ErrorAction SilentlyContinue; " ^
        "Stop-Process -Name 'python' -Force -ErrorAction SilentlyContinue; " ^
        "Stop-Process -Name 'llama-server' -Force -ErrorAction SilentlyContinue; " ^
        "Stop-Process -Name 'LM Studio' -Force -ErrorAction SilentlyContinue; " ^
        "break } }"
)
goto :eof

:: ===================================================
:: OPTION 1: AnythingLLM (Desktop GUI)
:: ===================================================
:AnythingLLM
cls
echo.
echo ===================================================
echo  AnythingLLM
echo ===================================================
echo.

call :KillExisting
call :StartOllama

echo.
echo [+] Launching AnythingLLM...

if not exist "%USB_ROOT%anythingllm\AnythingLLM.exe" (
    echo [ERROR] AnythingLLM.exe not found.
    pause & goto :ShowMenu
)

:: Set AnythingLLM portable paths
set "STORAGE_DIR=%USB_ROOT%anythingllm_data"
set "ANYTHINGLLM_PROFILE=%STORAGE_DIR%\anythingllm-desktop"

if not exist "%STORAGE_DIR%" mkdir "%STORAGE_DIR%"
if not exist "%ANYTHINGLLM_PROFILE%" mkdir "%ANYTHINGLLM_PROFILE%"
if not exist "%STORAGE_DIR%\storage" mkdir "%STORAGE_DIR%\storage"

:: Configure .env only on first run (AnythingLLM manages it after)
set "ENV_FILE=%STORAGE_DIR%\storage\.env"
set "DEFAULT_MODEL=nemomix-local"
if exist "%USB_ROOT%models\installed-models.txt" (
    for /f "usebackq tokens=1 delims=|" %%a in ("%USB_ROOT%models\installed-models.txt") do (
        set "DEFAULT_MODEL=%%a"
        goto :GotModel
    )
)
:GotModel

if not exist "%ENV_FILE%" (
    (
        echo LLM_PROVIDER=ollama
        echo OLLAMA_BASE_PATH=http://127.0.0.1:11434
        echo OLLAMA_MODEL_PREF=!DEFAULT_MODEL!
        echo OLLAMA_MODEL_TOKEN_LIMIT=4096
        echo EMBEDDING_ENGINE=native
        echo VECTOR_DB=lancedb
    ) > "%ENV_FILE%"
    echo [+] Created default .env config.
)

:: Launch AnythingLLM (non-blocking)
start "" "%USB_ROOT%anythingllm\AnythingLLM.exe" --user-data-dir="%STORAGE_DIR%"
echo [OK] AnythingLLM launched.
echo.
echo ===================================================
echo  AnythingLLM is running.
echo  Close AnythingLLM to return to menu.
echo ===================================================
echo.

:: Wait for AnythingLLM process to exit (max 100 iterations = 5 min)
set /a "waitCount=0"
:WaitForExit
set /a "waitCount+=1"
if !waitCount! GEQ 100 (
    echo [WARN] Timeout waiting for AnythingLLM. Force closing...
    goto :AnythingLLMClose
)
timeout /t 3 /nobreak >nul
tasklist /FI "IMAGENAME eq AnythingLLM.exe" 2>nul | find /i "AnythingLLM" >nul
if !errorlevel! EQU 0 goto :WaitForExit

:AnythingLLMClose
:: Cleanup and return to menu
echo.
echo [+] AnythingLLM closed. Cleaning up...
call :ForceCleanup
timeout /t 2 /nobreak >nul
goto :ShowMenu

:: ===================================================
:: OPTION 2: Browser Chat (Web UI)
:: ===================================================
:BrowserChat
cls
echo ===================================================
echo  Browser Chat - Optimized Mode
echo ===================================================
echo.

call :KillExisting
call :StartOllama

:: Find Python (USB only - never use system Python)
if exist "%PYTHON_CMD%" (
    echo [OK] Using portable Python from USB.
    goto :BCPythonReady
)

echo ===================================================
echo  Python not found on USB - downloading portable Python...
echo  (This only happens once, ~11MB download)
echo ===================================================
echo.

if not exist "%USB_ROOT%python" mkdir "%USB_ROOT%python"
curl -L "https://www.python.org/ftp/python/3.12.10/python-3.12.10-embed-amd64.zip" -o "%USB_ROOT%python-embed.zip"
if !errorlevel! NEQ 0 (
    echo Download failed. Check your internet connection.
    pause & exit /b
)

echo Extracting...
powershell -Command "Expand-Archive -Path '%USB_ROOT%python-embed.zip' -DestinationPath '%USB_ROOT%python' -Force"
del "%USB_ROOT%python-embed.zip" >nul 2>&1
powershell -Command "$p = '%USB_ROOT%python\python312._pth'; if (Test-Path $p) { (Get-Content $p) -replace '#import site', 'import site' | Set-Content $p }"

if exist "%USB_ROOT%python\python.exe" (
    set "PYTHON_CMD=%USB_ROOT%python\python.exe"
    echo [OK] Portable Python installed on USB.
) else (
    echo Failed to extract Python. Try again.
    pause & exit /b
)

:BCPythonReady
echo.
echo ===================================================
echo  AI ENGINE IS RUNNING
echo  Chat UI: http://localhost:3333
echo  Close this window to shut down.
echo ===================================================
echo.

:: Start chat server FIRST
echo [+] Starting chat server...
start /B cmd /c "%PYTHON_CMD% "%USB_ROOT%chat_server.py" --no-browser"

:: Wait for server to be ready
set /a "srv_attempts=0"
:WaitServer
set /a "srv_attempts+=1"
if !srv_attempts! GEQ 20 (
    echo [ERROR] Chat server failed to start.
    pause & exit /b
)
curl -s -m 2 http://localhost:3333 >nul 2>&1 && goto :ServerReady
timeout /t 1 /nobreak >nul
goto :WaitServer
:ServerReady
echo [OK] Chat server is online.

:: Clean browser profile to guarantee fresh single tab
set "BC_PROFILE=%USB_ROOT%browser_chat_profile"
if exist "%BC_PROFILE%" rmdir /S /Q "%BC_PROFILE%" 2>nul

:: Open browser and wait for it to close (same pattern as AnythingLLM)
echo.
echo ===================================================
echo  Browser Chat is running.
echo  Close the browser to return to menu.
echo ===================================================
echo.
call :OpenInBrowser "%BC_PROFILE%" "http://localhost:3333"

call :ForceCleanup
timeout /t 2 /nobreak >nul
goto :ShowMenu

:: ===================================================
:: OPTION 3: G0DM0D3 (Multi-Model AI Research)
:: ===================================================
:Godmod3
cls
echo ===================================================
echo  G0DM0D3 - Multi-Model AI Research Tool
echo ===================================================
echo.

call :KillExisting
call :StartOllama

set "GODMOD3_FILE=%USB_ROOT%godmod3\index.html"

if not exist "%GODMOD3_FILE%" (
    echo [+] G0DM0D3 not found. Downloading...
    if not exist "%USB_ROOT%godmod3" mkdir "%USB_ROOT%godmod3"
    curl -L "https://raw.githubusercontent.com/elder-plinius/G0DM0D3/main/index.html" -o "%GODMOD3_FILE%"
    if !errorlevel! NEQ 0 (
        echo [ERROR] Download failed. Check your internet connection.
        echo         You can also place index.html manually in godmod3\ folder.
        pause & goto :ShowMenu
    )
    echo [OK] G0DM0D3 downloaded.
)

if not exist "%PYTHON_CMD%" (
    echo [ERROR] Python not found on USB. Run option 2 first to install it.
    pause & goto :ShowMenu
)

echo.
echo ===================================================
echo  Starting local server for G0DM0D3...
echo  (Serving via HTTP enables local model connections)
echo ===================================================
echo.

:: Start Python HTTP server on port 3334 serving the godmod3 directory
set "GODMOD3_PORT=3334"
start "G0DM0D3 Server" /B "%PYTHON_CMD%" -m http.server %GODMOD3_PORT% --directory "%USB_ROOT%godmod3"

:: Wait for server to be ready
set /a "g_attempts=0"
:Godmod3WaitServer
set /a "g_attempts+=1"
if !g_attempts! GEQ 15 (
    echo [ERROR] G0DM0D3 server failed to start.
    pause & goto :ShowMenu
)
curl -s -m 2 http://localhost:%GODMOD3_PORT%/ >nul 2>&1 && goto :Godmod3ServerReady
timeout /t 1 /nobreak >nul
goto :Godmod3WaitServer
:Godmod3ServerReady
echo [OK] G0DM0D3 server is online at http://localhost:%GODMOD3_PORT%

:: Open G0DM0D3 in browser and wait for close (same pattern as AnythingLLM)
set "GODMOD3_PROFILE=%USB_ROOT%godmod3\browser_profile"
if not exist "%GODMOD3_PROFILE%" mkdir "%GODMOD3_PROFILE%"

echo.
echo ===================================================
echo  G0DM0D3 is running.
echo  Close the browser to return to menu.
echo ===================================================
echo.
call :OpenInBrowser "%GODMOD3_PROFILE%" "http://localhost:%GODMOD3_PORT%/index.html"

:: Kill the Python HTTP server
taskkill /F /IM "python*" >nul 2>&1
timeout /t 1 /nobreak >nul

call :ForceCleanup
timeout /t 2 /nobreak >nul
goto :ShowMenu

:: ===================================================
:: OPTION 4: llama.cpp (Direct GGUF Inference Server)
:: ===================================================
:LlamaCpp
cls
echo ===================================================
echo  llama.cpp - Direct GGUF Inference Server
echo ===================================================
echo.

set "LLAMA_DIR=%USB_ROOT%llama.cpp"
set "LLAMA_SERVER=%LLAMA_DIR%\llama-server.exe"
set "LLAMA_CLI=%LLAMA_DIR%\llama-cli.exe"
set "LLAMA_LAST_MODEL=%LLAMA_DIR%\last_model.txt"

if not exist "%LLAMA_SERVER%" (
    echo [ERROR] llama-server.exe not found at %LLAMA_DIR%
    echo         Run install.bat to download llama.cpp.
    pause & goto :ShowMenu
)

:: Select a GGUF model from models directory
echo  Available GGUF models:
echo.
set /a "model_count=0"
set "last_model_num=0"

:: Read last model BEFORE the loop to avoid set /p consuming stdin inside for
set "last_model_file="
if exist "%LLAMA_LAST_MODEL%" (
    for /f "usebackq delims=" %%L in ("%LLAMA_LAST_MODEL%") do set "last_model_file=%%L"
)

:: Scan both flat and nested model directories
for %%f in ("%USB_ROOT%models\*.gguf") do (
    set /a "model_count+=1"
    set "model_!model_count!=%%f"
    echo    [!model_count!] %%~nxf
    if defined last_model_file (
        if /I "%%~nxf"=="!last_model_file!" set "last_model_num=!model_count!"
    )
)
for /f "delims=" %%f in ('dir /b /s "%USB_ROOT%models\*.gguf" 2^>nul ^| findstr /I "\.gguf$"') do (
    set "FULLPATH=%%f"
    set "RELPATH=!FULLPATH:%USB_ROOT%models\=!"
    if not "!RELPATH!"=="!FULLPATH!" (
        set /a "model_count+=1"
        set "model_!model_count!=%%f"
        echo    [!model_count!] !RELPATH!
        for %%n in ("%%~nxf") do (
            if defined last_model_file (
                if /I "%%~nxn"=="!last_model_file!" set "last_model_num=!model_count!"
            )
        )
    )
)

if !model_count! EQU 0 (
    echo [ERROR] No GGUF files found in %USB_ROOT%models\
    echo         Download models first using install.bat or update-models.
    pause & goto :ShowMenu
)

echo    [0] Back to menu
echo.
if !last_model_num! GTR 0 (
    echo    Last used: model [!last_model_num!]
    set /p "model_choice=  Select model (0-!model_count!, Enter=!last_model_num!): "
    if not defined model_choice set "model_choice=!last_model_num!"
) else (
    set /p "model_choice=  Select model (0-!model_count!): "
)

:: Validate choice
if "!model_choice!"=="0" goto :ShowMenu
if not defined model_choice goto :LlamaCpp
set /a "choice_num=!model_choice!" 2>nul
if !choice_num! LSS 1 goto :LlamaCpp
if !choice_num! GTR !model_count! goto :LlamaCpp

set "SELECTED_GGUF=!model_%choice_num%!"
:: Save last used model filename for next launch
for %%f in ("!SELECTED_GGUF!") do (
    echo %%~nxf> "%LLAMA_LAST_MODEL%"
)
echo.
echo  Selected: !SELECTED_GGUF!
echo.

:: Set port
set "LLAMA_PORT=8080"

:: Kill any existing llama-server
taskkill /F /IM "llama-server*" >nul 2>&1
timeout /t 1 /nobreak >nul

echo ===================================================
echo  Starting llama.cpp server...
echo  Model: !SELECTED_GGUF!
echo  API:   http://localhost:!LLAMA_PORT!/v1
echo ===================================================
echo.

:: Launch llama-server in background
start "llama.cpp Server" /B "%LLAMA_SERVER%" ^
    --model "!SELECTED_GGUF!" ^
    --host 127.0.0.1 ^
    --port !LLAMA_PORT! ^
    --ctx-size 4096 ^
    --threads 4 ^
    --parallel 2

:: Wait for server to be ready
set /a "ll_attempts=0"
:WaitLlama
set /a "ll_attempts+=1"
if !ll_attempts! GEQ 60 (
    echo [ERROR] llama-server failed to start after 60 seconds.
    pause & goto :ShowMenu
)
curl -s -m 2 http://localhost:!LLAMA_PORT!/v1/models >nul 2>&1 && goto :LlamaReady
<nul set /p "=."
timeout /t 1 /nobreak >nul
goto :WaitLlama
:LlamaReady
echo. [OK] llama.cpp server is online.

:: Open browser and wait for close (same pattern as AnythingLLM)
set "LLAMA_PROFILE=%LLAMA_DIR%\browser_profile"

echo.
echo ===================================================
echo  llama.cpp is running.
echo  Close the browser to return to menu.
echo ===================================================
echo.
call :OpenInBrowser "%LLAMA_PROFILE%" "http://localhost:!LLAMA_PORT!"

:: Kill the server
taskkill /F /IM "llama-server*" >nul 2>&1
timeout /t 1 /nobreak >nul

call :ForceCleanup
timeout /t 2 /nobreak >nul
goto :ShowMenu

:: ===================================================
:: OPTION 5: LM Studio
:: ===================================================
:LMStudio
cls
echo ===================================================
echo  LM Studio - Model Browser ^& Server
echo ===================================================
echo.

set "LMSTUDIO_EXE=%USB_ROOT%LM Studio\LM Studio.exe"
set "LMSTUDIO_HOME=%USB_ROOT%LM Studio"
set "LMSTUDIO_SETTINGS=%LMSTUDIO_HOME%\.lmstudio\settings.json"

if not exist "%LMSTUDIO_EXE%" (
    echo [ERROR] LM Studio not found at %LMSTUDIO_EXE%
    echo         Run install.bat to install LM Studio.
    pause & goto :ShowMenu
)

:: Configure LM Studio to use USB model directory
if not exist "%LMSTUDIO_HOME%\.lmstudio" mkdir "%LMSTUDIO_HOME%\.lmstudio" 2>nul
:: LM Studio reads settings.json from its install root — force downloadsFolder to USB models
set "LMSTUDIO_ROOT_SETTINGS=%LMSTUDIO_HOME%\settings.json"
if exist "%LMSTUDIO_ROOT_SETTINGS%" (
    "%PYTHON_CMD%" -c "import json,os;p=r'%LMSTUDIO_ROOT_SETTINGS%';d=json.load(open(p));d['downloadsFolder']=r'%USB_ROOT%models';json.dump(d,open(p,'w'),indent=2)"
    echo [+] Configured LM Studio to use models on USB.
)

:: Set environment for portable config on USB
set "APPDATA=%USB_ROOT%LM Studio\.lmstudio"
set "LOCALAPPDATA=%USB_ROOT%LM Studio\.lmstudio"

:: Force CPU-only (AVX2) backend — this system's Intel HD Graphics 520
:: runs out of GPU memory with Vulkan (n_gpu_layers=999999 + KV cache overflow)
echo [INFO] Setting CPU-only backend for LM Studio (no GPU offload).
if exist "%USB_ROOT%LM Studio\.lmstudio\.internal\backend-preferences-v1.json" (
    >"%USB_ROOT%LM Studio\.lmstudio\.internal\backend-preferences-v1.json" (
        echo [
        echo   {
        echo     "model_format": "gguf",
        echo     "name": "llama.cpp-win-x86_64-avx2",
        echo     "version": "2.25.2"
        echo   }
        echo ]
    )
)
if exist "%USB_ROOT%LM Studio\.internal\backend-preferences-v1.json" (
    >"%USB_ROOT%LM Studio\.internal\backend-preferences-v1.json" (
        echo [
        echo   {
        echo     "model_format": "gguf",
        echo     "name": "llama.cpp-win-x86_64-avx2",
        echo     "version": "2.25.2"
        echo   }
        echo ]
    )
)

echo [+] Launching LM Studio...
echo     Model directory: %USB_ROOT%models\
echo     (LM Studio scans for GGUF files automatically)
echo.
echo ===================================================
echo  LM Studio is running.
echo  Close LM Studio when done.
echo ===================================================
echo.

start "" "%LMSTUDIO_EXE%"
:: Wait for LM Studio to close (max 100 iterations = 5 min)
set /a "lmWaitCount=0"
:LMStudioWait
set /a "lmWaitCount+=1"
if !lmWaitCount! GEQ 100 (
    echo [WARN] Timeout waiting for LM Studio. Force closing...
    taskkill /F /IM "LM Studio.exe" >nul 2>&1
    goto :LMStudioClose
)
tasklist /FI "IMAGENAME eq LM Studio.exe" 2>nul | find /I "LM Studio.exe" >nul 2>&1
if !errorlevel! EQU 0 (
    timeout /t 3 /nobreak >nul
    goto :LMStudioWait
)

:LMStudioClose
call :ForceCleanup
timeout /t 2 /nobreak >nul
goto :ShowMenu

:: ===================================================
:: OPTION 6: HuggingFace Model Downloader
:: ===================================================
:HFDownload
cls
echo ===================================================
echo  HuggingFace Model Downloader
echo ===================================================
echo.
echo  Models are saved to: %USB_ROOT%models\
echo  (Uses LM Studio directory structure: models^<Publisher^>^<Model^>^)
echo.

if not exist "%PYTHON_CMD%" (
    echo [ERROR] Python not found on USB. Run install.bat first.
    pause & goto :ShowMenu
)

if not exist "%HF_SCRIPT%" (
    echo [ERROR] hf_cli.py not found on USB.
    pause & goto :ShowMenu
)

:HFMenu
echo  ------------------------------------------------
echo    [1] Download a model (enter repo/filename)
echo    [2] Search HuggingFace for GGUF models
echo    [3] List models on USB
echo    [0] Back to menu
echo  ------------------------------------------------
echo.
set /p "hf_choice=  Choice: "

if "!hf_choice!"=="0" goto :ShowMenu
if "!hf_choice!"=="1" goto :HFDownloadModel
if "!hf_choice!"=="2" goto :HFSearch
if "!hf_choice!"=="3" goto :HFListModels
goto :HFMenu

:HFDownloadModel
echo.
echo  Enter HuggingFace repo and filename.
echo  Structure: PublisherName/ModelName/File.gguf
echo  Example:
echo    DavidAU/OpenAi-GPT-oss-20b-abliterated-uncensored-NEO-Imatrix-gguf OpenAI-20B-NEO-CODE2-Plus-Uncensored-IQ4_NL.gguf
echo.
set /p "hf_repo=  Repo ID (publisher/model-name): "
if "!hf_repo!"=="" goto :HFMenu
set /p "hf_file=  Filename (*.gguf): "
if "!hf_file!"=="" goto :HFMenu

:: Extract publisher (first token before /) and model name (second token)
for /f "tokens=1,2 delims=/" %%A in ("!hf_repo!") do (
    set "HF_PUBLISHER=%%A"
    set "HF_MODEL=%%B"
)

:: Create two-level directory: models/<Publisher>/<Model>/
set "HF_TARGET_DIR=%USB_ROOT%models\!HF_PUBLISHER!\!HF_MODEL!"
if not exist "!HF_TARGET_DIR!" mkdir "!HF_TARGET_DIR!"

echo.
echo  Downloading !hf_file! from !hf_repo! ...
echo  Target: !HF_TARGET_DIR!\
echo.

set "HF_HOME=%USB_ROOT%models\.hf_cache"
"%USB_ROOT%python\Scripts\hf.exe" download "!hf_repo!" "!hf_file!" --local-dir "!HF_TARGET_DIR!" 2>nul
set "DL_STATUS=!errorlevel!"

:: Move file from nested HF cache layout to flat model dir if needed
for /f "delims=" %%F in ('dir /b /s "!HF_TARGET_DIR!\*.gguf" 2^>nul') do (
    if not "%%~dpF"=="!HF_TARGET_DIR!\" (
        move "%%F" "!HF_TARGET_DIR!\" >nul 2>&1
    )
)

if !DL_STATUS! NEQ 0 (
    echo.
    echo [ERROR] Download failed. Check repo/filename and try again.
) else (
    echo.
    echo [OK] Model saved to !HF_PUBLISHER!/!HF_MODEL!/
)
echo.
pause
goto :HFMenu

:HFSearch
echo.
set /p "hf_query=  Search query (e.g. llama3 Q4_K_M): "
if "!hf_query!"=="" goto :HFMenu
echo.
echo  Searching HuggingFace for "!hf_query!" GGUF models...
echo.
"%PYTHON_CMD%" "%HF_SCRIPT%" search "!hf_query!"
echo.
pause
goto :HFMenu

:HFListModels
echo.
echo  Models on USB (LM Studio structure):
echo  ------------------------------------------------
"%PYTHON_CMD%" "%HF_SCRIPT%" list "%USB_ROOT%models"
echo  ------------------------------------------------
echo.
pause
goto :HFMenu

:: ===================================================
:: OPTION 6: Cloud AI (Puter.js - cloud GPT/Claude/Gemini)
:: ===================================================
:CloudAI
cls
echo ===================================================
echo  Cloud AI - Puter.js Powered
echo ===================================================
echo.
echo  Using Puter.js to access cloud AI models (GPT, Claude, Gemini).
echo  No API key needed - uses Puter's free tier.
echo.

if not exist "%PYTHON_CMD%" (
    echo [ERROR] Python not found on USB. Run install.bat first.
    pause & goto :ShowMenu
)

if not exist "%CLOUD_ROOT%" (
    echo [ERROR] Cloud AI files not found at: %CLOUD_ROOT%
    pause & goto :ShowMenu
)

set "PTXT=%USB_ROOT%puter_config.txt"
if exist "%PTXT%" (
    "%PYTHON_CMD%" -c "line=open(r'%PTXT%').read().strip(); tok=line.split('=',1)[1] if '=' in line else line; open(r'%CLOUD_ROOT%\config.js','w').write('// Auto-generated config\nvar puterConfig = {\n  token: \'' + tok + '\'\n};\n')"
    echo  [+] API token loaded from puter_config.txt
)

echo [1/2] Starting local web server on port %CLOUD_PORT%...
start "Cloud AI Server" /B "%PYTHON_CMD%" "%CLOUD_ROOT%\server.py" %CLOUD_PORT% "%CLOUD_ROOT%" >nul 2>&1
timeout /t 2 /nobreak >nul

echo [2/2] Opening browser...
echo.
echo ===================================================
echo  Cloud AI is running.
echo  Close the browser to return to menu.
echo ===================================================
echo.
call :OpenInBrowser "%CLOUD_PROFILE%" "http://127.0.0.1:%CLOUD_PORT%/"

taskkill /F /IM "python*" >nul 2>&1
timeout /t 1 /nobreak >nul
goto :ShowMenu

:: ===================================================
:: OPTION 7: Puter.com (Full cloud OS in browser)
:: ===================================================
:PuterSite
cls
echo ===================================================
echo  Puter.com - Full Cloud OS
echo ===================================================
echo.
echo  Access a complete cloud desktop environment in your browser.
echo  Includes file storage, apps, and more.
echo.

echo Opening Puter.com in your browser...
echo.
echo ===================================================
echo  Puter.com - Full Cloud OS in Browser
echo  Close the browser to return to menu.
echo ===================================================
echo.
call :OpenInBrowser "%PUTER_PROFILE%" "https://puter.com/"

goto :ShowMenu

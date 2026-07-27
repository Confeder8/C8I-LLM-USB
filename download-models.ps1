#Requires -Version 5.1
<#
.SYNOPSIS
    Download GGUF models from HuggingFace with interactive selection menu.
.DESCRIPTION
    Loads model catalog from models.json, shows numbered menu with colored
    labels (same style as install-core.ps1), downloads selected GGUFs to
    USB models directory, creates Modelfiles, updates configs, imports to Ollama.
    No installers, no C: drive changes.
.PARAMETER SkipOllama
    Skip Ollama import step.
.EXAMPLE
    .\download-models.ps1
    .\download-models.ps1 -SkipOllama
#>
param(
    [switch]$SkipOllama
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Continue"

$USB_Drive = Split-Path -Parent $MyInvocation.MyCommand.Path
$MODELS_DIR = "$USB_Drive\models"
$OLLAMA_EXE = "$USB_Drive\ollama\ollama.exe"
$OLLAMA_DATA = "$USB_Drive\ollama\data"
$PYTHON_EXE = "$USB_Drive\python\python.exe"
$HF_DOWNLOADER = "$USB_Drive\download_model.py"
$ANYTHINGLLM_ENV = "$USB_Drive\anythingllm_data\storage\.env"
$LLAMA_LAST_MODEL = "$USB_Drive\llama.cpp\build\bin\Release\user_data\last_model.txt"
$IMPORT_LOG = "$MODELS_DIR\download_import.log"

$env:HF_HOME = "$MODELS_DIR\.hf_cache"
$env:HF_HUB_DISABLE_TELEMETRY = "1"
$env:HF_HUB_ENABLE_HF_TRANSFER = "0"

# ── Helpers ─────────────────────────────────────────────────────────
function Write-Log {
    param([string]$Message)
    $ts = Get-Date -Format "HH:mm:ss"
    "$ts  $Message" | Out-File -FilePath $IMPORT_LOG -Append -Encoding UTF8
}

function Get-USBFreeSpaceGB {
    $driveLetter = $USB_Drive.TrimEnd('\').Substring(0,1)
    $drive = Get-PSDrive -Name $driveLetter -ErrorAction SilentlyContinue
    if ($drive) { return [math]::Round($drive.Free / 1GB, 1) }
    return 0
}

function Show-Activity {
    param([string]$Activity, [string]$Status, [int]$PercentComplete = -1)
    $params = @{ Activity = $Activity; Status = $Status }
    if ($PercentComplete -ge 0) { $params.PercentComplete = $PercentComplete }
    Write-Progress @params
}

function Hide-Activity {
    Write-Progress -Activity " " -Completed
}

function Get-HFRepoAndFile {
    param([string]$Url)
    if ($Url -match 'huggingface\.co/([^/]+/[^/]+)/resolve/main/(.+)$') {
        return @{ RepoId = $Matches[1]; Filename = $Matches[2] }
    }
    return $null
}

function Find-GGUFFile {
    param([string]$FileName, [string]$ModelsDir)
    $flatPath = Join-Path $ModelsDir $FileName
    if (Test-Path $flatPath) { return $flatPath }
    $found = Get-ChildItem -Path $ModelsDir -Recurse -Filter $FileName -File -ErrorAction SilentlyContinue |
             Select-Object -First 1
    if ($found) { return $found.FullName }
    return $null
}

function Test-DownloadedFile {
    param([string]$Path, [long]$MinSize)
    if (-Not (Test-Path $Path)) { return $false }
    return (Get-Item $Path).Length -gt $MinSize
}

function Test-GGUFIntegrity {
    param([string]$Path, [long]$MinSize=1000000)
    if (-Not (Test-Path $Path)) { return $false }
    try {
        $file = Get-Item $Path
        if ($file.Length -lt $MinSize) { return $false }
        $stream = [System.IO.File]::OpenRead($Path)
        $bytes = New-Object byte[] 4
        $read = $stream.Read($bytes, 0, 4)
        $stream.Close()
        if ($read -lt 4) { return $false }
        $magic = [System.Text.Encoding]::ASCII.GetString($bytes)
        return $magic -eq "GGUF"
    } catch { return $false }
}

function Get-ModelfileContent {
    param([string]$GGUFPath)
    return "FROM $GGUFPath`n"
}

function Find-OllamaManifest {
    param([string]$ModelName)
    $manifestRoot = "$OLLAMA_DATA\manifests"
    if (-Not (Test-Path $manifestRoot)) { return $null }
    $found = Get-ChildItem -Path $manifestRoot -Recurse -File -ErrorAction SilentlyContinue |
        Where-Object {
            $_.DirectoryName -match [regex]::Escape($ModelName) -and
            $_.Length -gt 10
        } | Select-Object -First 1
    return $found
}

function Test-OllamaManifest {
    param([string]$ModelName)
    $found = Find-OllamaManifest -ModelName $ModelName
    return ($null -ne $found)
}

function Update-InstalledModelsTxt {
    param(
        [string]$TxtPath, [string]$LocalName, [string]$DisplayName,
        [string]$Publisher, [string]$GGUFFile
    )
    $lines = @()
    if (Test-Path $TxtPath) {
        $lines = @(Get-Content $TxtPath -ErrorAction SilentlyContinue)
    }
    $escapedLocal = [regex]::Escape($LocalName)
    $exists = $lines | Where-Object { $_ -match "^$escapedLocal\|" }
    if ($exists) {
        Write-Host "      installed-models.txt: $LocalName already listed" -ForegroundColor DarkGray
        return
    }
    "$LocalName|$DisplayName|$Publisher|$GGUFFile" | Out-File -FilePath $TxtPath -Append -Encoding UTF8
    Write-Host "      installed-models.txt: added $LocalName" -ForegroundColor Green
}

function Update-AnythingLLMEnv {
    param([string]$EnvPath, [string]$ModelName)
    if (-not (Test-Path $EnvPath)) {
        Write-Host "      AnythingLLM .env not found, skipping" -ForegroundColor DarkGray
        return
    }
    $content = Get-Content $EnvPath -Raw -ErrorAction SilentlyContinue
    if (-not $content) { return }
    if ($content -match 'OLLAMA_MODEL_PREF=.+') {
        $newContent = $content -replace 'OLLAMA_MODEL_PREF=.+', "OLLAMA_MODEL_PREF=$ModelName"
    } else {
        $newContent = $content + "`nOLLAMA_MODEL_PREF=$ModelName"
    }
    Set-Content -Path $EnvPath -Value $newContent -Encoding UTF8 -Force
    Write-Host "      AnythingLLM: default model -> $ModelName" -ForegroundColor Green
}

function Update-LlamaCppLastModel {
    param([string]$Path, [string]$GGUFPath)
    $dir = Split-Path $Path -Parent
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Force -Path $dir | Out-Null
    }
    Set-Content -Path $Path -Value $GGUFPath -Encoding UTF8 -Force
    Write-Host "      llama.cpp: last_model.txt updated" -ForegroundColor Green
}

# ── Load catalog from models.json ───────────────────────────────────
$ModelsJsonPath = "$MODELS_DIR\models.json"
if (-not (Test-Path $ModelsJsonPath)) {
    Write-Host ""
    Write-Host "  ERROR: models.json not found at $ModelsJsonPath" -ForegroundColor Red
    Write-Host "  Run install.bat first to set up the model catalog." -ForegroundColor Red
    Write-Host ""
    Write-Host "Press any key to exit..." -ForegroundColor Yellow
    $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | Out-Null
    exit 1
}

try {
    $jsonConfig = Get-Content -Raw -Path $ModelsJsonPath | ConvertFrom-Json
    $ModelCatalog = @()
    foreach ($m in $jsonConfig.desktop_models) {
        $sz = if ($m.PSObject.Properties['size']) { [string]$m.size } else { "?" }
        $dn = if ($m.PSObject.Properties['displayName']) { [string]$m.displayName } else { [string]$m.name }
        $alts = @()
        if ($m.PSObject.Properties['alt_urls'] -and $m.alt_urls) {
            foreach ($a in @($m.alt_urls)) {
                if (-not [string]::IsNullOrWhiteSpace([string]$a)) { $alts += [string]$a }
            }
        }
        $ModelCatalog += @{
            Num      = [int]$m.num
            Name     = [string]$m.name
            File     = [string]$m.file
            URL      = [string]$m.url
            AltURLs  = $alts
            Size     = $sz
            MinBytes = [long]$m.min_bytes
            Local    = [string]$m.local
            Label    = [string]$m.label
            Badge    = [string]$m.badge
            Prompt   = [string]$m.prompt
        }
    }
} catch {
    Write-Host ""
    Write-Host "  ERROR: Failed to parse models.json: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "Press any key to exit..." -ForegroundColor Yellow
    $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | Out-Null
    exit 1
}

if ($ModelCatalog.Count -eq 0) {
    Write-Host ""
    Write-Host "  ERROR: No models found in models.json" -ForegroundColor Red
    Write-Host ""
    Write-Host "Press any key to exit..." -ForegroundColor Yellow
    $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | Out-Null
    exit 1
}

# ── START ───────────────────────────────────────────────────────────
Write-Host ""
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "   PORTABLE AI USB - Download GGUF Models                 " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host ""

$freeGB = Get-USBFreeSpaceGB
if ($freeGB -gt 0) {
    Write-Host "  USB Free Space: $freeGB GB" -ForegroundColor DarkGray
    Write-Host ""
}

Write-Host "[1/5] Choose models to download:" -ForegroundColor Yellow
Write-Host ""

$SortedCatalog = $ModelCatalog | Sort-Object { $_.Name }
$sortIdx = 0
foreach ($m in $SortedCatalog) {
    $sortIdx++
    $m.Num = $sortIdx
    $numStr   = "  [$($m.Num)]"
    $nameStr  = " $($m.Name)"
    $sizeStr  = if ($m.Size -ne "?") { " (~$($m.Size) GB)" } else { "" }

    if ($m.Label -eq "UNCENSORED") {
        $labelStr = " [UNCENSORED]"; $labelColor = "Red"
    } elseif ($m.Label -eq "NSFW") {
        $labelStr = " [NSFW]"; $labelColor = "Magenta"
    } elseif ($m.Label -eq "LOCAL") {
        $labelStr = " [LOCAL]"; $labelColor = "Yellow"
    } else {
        $labelStr = " [STANDARD]"; $labelColor = "DarkCyan"
    }

    $badgeStr = ""
    if ($m.Badge) { $badgeStr = " - $($m.Badge)" }

    $existingPath = Find-GGUFFile -FileName $m.File -ModelsDir $MODELS_DIR
    $dlStr = ""
    if ($existingPath -and (Test-GGUFIntegrity -Path $existingPath -MinSize $m.MinBytes)) {
        $dlStr = " [DOWNLOADED]"
    }

    Write-Host $numStr   -ForegroundColor Yellow    -NoNewline
    Write-Host $nameStr  -ForegroundColor White     -NoNewline
    Write-Host $sizeStr  -ForegroundColor DarkGray  -NoNewline
    Write-Host $labelStr -ForegroundColor $labelColor -NoNewline
    Write-Host $badgeStr -ForegroundColor Magenta   -NoNewline
    if ($dlStr) { Write-Host $dlStr -ForegroundColor Green }
    else { Write-Host "" }
}

Write-Host ""
Write-Host "  [C] CUSTOM - Enter your own HuggingFace GGUF URL" -ForegroundColor Green
Write-Host ""
Write-Host "  ------------------------------------------------" -ForegroundColor DarkGray
Write-Host "  Enter numbers separated by commas  - e.g. 1,3" -ForegroundColor Gray
Write-Host "  Type 'all' for every model" -ForegroundColor Gray
Write-Host "  Type 'c' to add a custom model" -ForegroundColor Gray
Write-Host "  Mix them!  - e.g. 1,3,c" -ForegroundColor Gray
Write-Host ""

$UserChoice = Read-Host "  Your choice"

if ([string]::IsNullOrWhiteSpace($UserChoice)) {
    Write-Host ""
    Write-Host "  No input! Defaulting to [1] $($SortedCatalog[0].Name)..." -ForegroundColor Yellow
    $UserChoice = "1"
}

# ── Parse selection ─────────────────────────────────────────────────
$SelectedModels = @()
$HasCustom = $false

if ($UserChoice.Trim().ToLower() -eq "all") {
    $SelectedModels = @($ModelCatalog)
} else {
    $tokens = $UserChoice -split ","
    foreach ($token in $tokens) {
        $t = $token.Trim().ToLower()
        if ($t -eq "c" -or $t -eq "custom") {
            $HasCustom = $true
        } elseif ($t -match '^\d+$') {
            $num = [int]$t
            $found = $SortedCatalog | Where-Object { $_.Num -eq $num }
            if ($found) {
                $alreadyAdded = $SelectedModels | Where-Object { $_.File -eq $found.File }
                if (-Not $alreadyAdded) { $SelectedModels += $found }
            } else {
                Write-Host "  Invalid number '$num' - skipping - valid: 1-$($SortedCatalog.Count)" -ForegroundColor Red
            }
        } else {
            Write-Host "  Unrecognized input '$t' - skipping" -ForegroundColor Red
        }
    }
}

# ── Custom model input ─────────────────────────────────────────────
if ($HasCustom) {
    Write-Host ""
    Write-Host "  ---- Custom Model Setup ----" -ForegroundColor Green
    Write-Host "  Paste a direct link to a .gguf file from HuggingFace." -ForegroundColor Gray
    Write-Host "  Example: https://huggingface.co/user/model-GGUF/resolve/main/model-Q4_K_M.gguf" -ForegroundColor DarkGray
    Write-Host ""

    $customURL = Read-Host "  GGUF URL"

    if ([string]::IsNullOrWhiteSpace($customURL)) {
        Write-Host "  No URL entered - skipping custom model." -ForegroundColor Red
    } elseif ($customURL -notmatch "\.gguf") {
        Write-Host "  WARNING: URL does not end in .gguf - this may not be a valid model file." -ForegroundColor Red
        $proceed = Read-Host "  Try anyway? (yes/no)"
        if ($proceed.Trim().ToLower() -ne "yes" -and $proceed.Trim().ToLower() -ne "y") {
            Write-Host "  Skipping custom model." -ForegroundColor Yellow
            $customURL = $null
        }
    }

    if ($customURL) {
        $customFile = $customURL.Split("/")[-1].Split("?")[0]
        if (-Not $customFile.EndsWith(".gguf")) { $customFile = "$customFile.gguf" }

        $customLocalName = Read-Host "  Give it a short name (e.g. mymodel-local)"
        if ([string]::IsNullOrWhiteSpace($customLocalName)) {
            $customLocalName = "custom-local"
        }
        $customLocalName = $customLocalName.Trim().ToLower() -replace '\s+', '-'
        if ($customLocalName -notmatch '-local$') { $customLocalName = "$customLocalName-local" }

        $customPrompt = Read-Host "  System prompt (press Enter for default)"
        if ([string]::IsNullOrWhiteSpace($customPrompt)) {
            $customPrompt = "You are a helpful AI assistant."
        }

        $customModel = @{
            Num      = 99
            Name     = "Custom: $customFile"
            File     = $customFile
            URL      = $customURL.Trim()
            AltURLs  = @()
            Size     = "?"
            MinBytes = 100000000
            Local    = $customLocalName
            Label    = "CUSTOM"
            Badge    = ""
            Prompt   = $customPrompt
        }

        $SelectedModels += $customModel
        Write-Host "  Custom model added!" -ForegroundColor Green
    }
}

# ── Validate selection ──────────────────────────────────────────────
if ($SelectedModels.Count -eq 0) {
    Write-Host ""
    Write-Host "  ERROR: No models selected!" -ForegroundColor Red
    Write-Host "  Please run the script again and pick at least one model." -ForegroundColor Red
    Write-Host ""
    Write-Host "Press any key to exit..." -ForegroundColor Yellow
    $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | Out-Null
    exit 1
}

# ── USB space warning ──────────────────────────────────────────────
$totalSizeGB = 0
foreach ($m in $SelectedModels) {
    if ($m.Size -ne "?") { $totalSizeGB += [double]$m.Size }
}

if ($SelectedModels.Count -ge 3 -or $UserChoice.Trim().ToLower() -eq "all") {
    Write-Host ""
    Write-Host "  =============================================" -ForegroundColor Red
    Write-Host "  WARNING: You selected $($SelectedModels.Count) models!" -ForegroundColor Red
    Write-Host "  Estimated download: ~$totalSizeGB GB" -ForegroundColor Red
    $neededGB = [math]::Ceiling($totalSizeGB + 4)
    Write-Host "  USB drive needs at least ~$neededGB GB free!" -ForegroundColor Red
    if ($freeGB -gt 0 -and $freeGB -lt $neededGB) {
        Write-Host ""
        Write-Host "  You only have $freeGB GB free - this may NOT fit!" -ForegroundColor Yellow
    }
    Write-Host "  =============================================" -ForegroundColor Red
    Write-Host ""
    $confirm = Read-Host "  Continue? (yes/no)"
    if ($confirm.Trim().ToLower() -ne "yes" -and $confirm.Trim().ToLower() -ne "y") {
        Write-Host "  Cancelled." -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Press any key to exit..." -ForegroundColor Yellow
        $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | Out-Null
        exit
    }
}

# ── Show selection summary ─────────────────────────────────────────
Write-Host ""
Write-Host "  Selected $($SelectedModels.Count) models:" -ForegroundColor Green
foreach ($m in $SelectedModels) {
    $sizeInfo = if ($m.Size -ne "?") { " (~$($m.Size) GB)" } else { "" }
    Write-Host "    + $($m.Name)$sizeInfo" -ForegroundColor White
}
Write-Host ""

# ── Check Python + HF Hub ──────────────────────────────────────────
Write-Host "[2/5] Checking prerequisites..." -ForegroundColor Yellow
Write-Host ""

if (-not (Test-Path $PYTHON_EXE)) {
    Write-Host "  WARNING: Portable Python not found at $PYTHON_EXE" -ForegroundColor Yellow
    Write-Host "  Run install.bat first to set up Python." -ForegroundColor Yellow
} else {
    $hfCheck = & $PYTHON_EXE -c "import huggingface_hub; print(huggingface_hub.__version__)" 2>$null
    if ($hfCheck) {
        Write-Host "  huggingface_hub $hfCheck ready" -ForegroundColor DarkGray
    } else {
        Write-Host "  Installing huggingface_hub..." -ForegroundColor Yellow
        & $PYTHON_EXE -m pip install --quiet huggingface_hub 2>$null
        $hfCheck = & $PYTHON_EXE -c "import huggingface_hub; print(huggingface_hub.__version__)" 2>$null
        if ($hfCheck) {
            Write-Host "  huggingface_hub $hfCheck installed" -ForegroundColor Green
        } else {
            Write-Host "  WARNING: Failed to install huggingface_hub" -ForegroundColor Yellow
        }
    }
}
Write-Host "      Done." -ForegroundColor Green

# ── Download selected models ────────────────────────────────────────
Write-Host ""
Write-Host "[3/5] Downloading GGUF models..." -ForegroundColor Yellow

$downloadErrors = @()
$modelIndex = 0

foreach ($m in $SelectedModels) {
    $modelIndex++
    $sizeInfo = if ($m.Size -ne "?") { "(~$($m.Size) GB)" } else { "" }

    Write-Host ""
    Write-Host "  ($modelIndex/$($SelectedModels.Count)) $($m.Name) $sizeInfo" -ForegroundColor Yellow

    # Derive publisher from URL
    $publisher = "Unknown"
    if ($m.URL -and $m.URL -match 'huggingface\.co/([^/]+)/') {
        $publisher = $Matches[1]
    }

    # Check if already downloaded (GGUF magic bytes + reasonable minimum size)
    $existingPath = Find-GGUFFile -FileName $m.File -ModelsDir $MODELS_DIR
    if ($existingPath -and (Test-GGUFIntegrity -Path $existingPath -MinSize 1000000)) {
        $existingMB = [math]::Round((Get-Item $existingPath).Length / 1MB, 1)
        Write-Host "      Already downloaded! ($existingMB MB) Skipping..." -ForegroundColor Green
        $ggufPath = $existingPath
    } else {
        if ($existingPath) {
            $existingSize = (Get-Item $existingPath).Length
            if ($existingSize -lt 1000000) {
                Write-Host "      Existing file too small ($existingSize bytes). Removing..." -ForegroundColor Yellow
            } else {
                Write-Host "      Existing file has invalid GGUF header. Re-downloading..." -ForegroundColor Yellow
            }
            Remove-Item -LiteralPath $existingPath -Force -ErrorAction SilentlyContinue
        }

        # Skip models with no URL (manually placed GGUFs)
        if ([string]::IsNullOrWhiteSpace($m.URL)) {
            Write-Host "      No download URL - must be copied manually." -ForegroundColor Yellow
            $downloadErrors += "$($m.Name) (no URL)"
            continue
        }

        # Collect all URLs to try: primary + alt_urls
        $urlsToTry = @($m.URL)
        if ($m.AltURLs) {
            foreach ($alt in $m.AltURLs) {
                if (-not [string]::IsNullOrWhiteSpace($alt)) {
                    $urlsToTry += $alt
                }
            }
        }

        $ggufPath = $null
        $success = $false

        foreach ($url in $urlsToTry) {
            if ($success) { break }

            $hfInfo = Get-HFRepoAndFile -Url $url
            if ($hfInfo) {
                # Download via HuggingFace Hub Python API
                Write-Host "      HF Hub: $($hfInfo.RepoId)/$($hfInfo.Filename)" -ForegroundColor DarkGray
                Write-Log "DOWNLOAD: $($m.Name) | repo=$($hfInfo.RepoId) file=$($hfInfo.Filename)"

                if (-not (Test-Path $PYTHON_EXE)) {
                    Write-Host "      Python not found, skipping HF download" -ForegroundColor Red
                    break
                }
                if (-not (Test-Path $HF_DOWNLOADER)) {
                    Write-Host "      download_model.py not found, skipping HF download" -ForegroundColor Red
                    break
                }

                # Target dir: models/Publisher/ModelName/
                $repoBase = $m.Name -replace '[^a-zA-Z0-9\-\. ]', '' -replace '\s+', '-'
                $targetDir = "$MODELS_DIR\$publisher\$repoBase"
                New-Item -ItemType Directory -Force -Path $targetDir | Out-Null

                $result = & $PYTHON_EXE $HF_DOWNLOADER $hfInfo.RepoId $hfInfo.Filename $targetDir 2>&1
                $exitCode = $LASTEXITCODE

                if ($exitCode -eq 0) {
                    $output = $result | Where-Object { $_ -match '^OK\|' }
                    if ($output) {
                        $parts = ($output -split '\|')
                        $downloadedPath = $parts[1]
                        if ($downloadedPath -and (Test-Path $downloadedPath) -and
                            (Test-GGUFIntegrity -Path $downloadedPath -MinSize 1000000)) {
                            $ggufPath = $downloadedPath
                            $dlMB = [math]::Round((Get-Item $downloadedPath).Length / 1MB, 1)
                            Write-Host "      Downloaded: $dlMB MB" -ForegroundColor Green
                            Write-Log "OK: $downloadedPath ($dlMB MB)"
                            $success = $true
                        }
                    }
                    # Fallback: search for the file
                    if (-not $ggufPath) {
                        $downloaded = Get-ChildItem -Path $targetDir -Filter $m.File -Recurse -File -ErrorAction SilentlyContinue |
                            Select-Object -First 1
                        if (-not $downloaded) {
                            $basename = [System.IO.Path]::GetFileNameWithoutExtension($m.File)
                            $downloaded = Get-ChildItem -Path $targetDir -Filter "$basename*" -Recurse -File -ErrorAction SilentlyContinue |
                                Where-Object { $_.Extension -eq '.gguf' } | Select-Object -First 1
                        }
                        if (-not $downloaded) {
                            $downloaded = Get-ChildItem -Path $targetDir -Filter "*.gguf" -Recurse -File -ErrorAction SilentlyContinue |
                                Select-Object -First 1
                        }
                        if ($downloaded -and (Test-GGUFIntegrity -Path $downloaded.FullName -MinSize 1000000)) {
                            $ggufPath = $downloaded.FullName
                            $dlMB = [math]::Round($downloaded.Length / 1MB, 1)
                            Write-Host "      Downloaded: $dlMB MB" -ForegroundColor Green
                            Write-Log "OK: $($downloaded.FullName) ($dlMB MB)"
                            $success = $true
                        }
                    }
                } else {
                    $errMsg = ($result | Where-Object { $_ -match '^ERR\|' }) -join "; "
                    if (-not $errMsg) { $errMsg = ($result | Select-Object -Last 3) -join "; " }
                    Write-Host "      download_model.py failed: $errMsg" -ForegroundColor Red
                    Write-Log "FAILED: download_model.py exit=$exitCode | $errMsg"
                }
            } else {
                # Non-HuggingFace URL: curl fallback
                Write-Host "      curl fallback: $url" -ForegroundColor DarkGray
                $repoBase = $m.Name -replace '[^a-zA-Z0-9\-\. ]', '' -replace '\s+', '-'
                $targetDir = "$MODELS_DIR\$publisher\$repoBase"
                New-Item -ItemType Directory -Force -Path $targetDir | Out-Null
                $curlDest = "$targetDir\$($m.File)"
                Remove-Item -LiteralPath $curlDest -Force -ErrorAction SilentlyContinue
                $curlResult = curl.exe -L --ssl-no-revoke -# -o $curlDest $url 2>&1
                if ($LASTEXITCODE -eq 0 -and (Test-GGUFIntegrity -Path $curlDest -MinSize 1000000)) {
                    $ggufPath = $curlDest
                    $dlMB = [math]::Round((Get-Item $curlDest).Length / 1MB, 1)
                    Write-Host "      Downloaded via curl: $dlMB MB" -ForegroundColor Green
                    Write-Log "OK CURL: $curlDest ($dlMB MB)"
                    $success = $true
                } else {
                    Write-Host "      curl also failed for this URL" -ForegroundColor Red
                    Write-Log "FAILED CURL: $url"
                }
            }
        }

        if (-not $success) {
            $downloadErrors += $m.Name
        }
    }

    # Post-download: create Modelfile + update configs
    if ($ggufPath) {
        $modelfileDir = Split-Path $ggufPath -Parent
        $modelfile = "$modelfileDir\Modelfile"
        if (-not (Test-Path $modelfile)) {
            $modelfileContent = Get-ModelfileContent -GGUFPath $ggufPath
            Set-Content -Path $modelfile -Value $modelfileContent -Encoding UTF8 -Force
            Write-Host "      Modelfile created" -ForegroundColor DarkGray
        } else {
            Write-Host "      Modelfile already exists" -ForegroundColor DarkGray
        }

        Update-InstalledModelsTxt -TxtPath "$MODELS_DIR\installed-models.txt" `
            -LocalName $m.Local -DisplayName $m.Name -Publisher $publisher -GGUFFile $m.File
        Update-AnythingLLMEnv -EnvPath $ANYTHINGLLM_ENV -ModelName $m.Local
        Update-LlamaCppLastModel -Path $LLAMA_LAST_MODEL -GGUFPath $ggufPath
    }
}

# ── Summary ─────────────────────────────────────────────────────────
Write-Host ""
Write-Host "[4/5] Download summary" -ForegroundColor Yellow
$downloadedCount = $SelectedModels.Count - $downloadErrors.Count
Write-Host "  Downloaded: $downloadedCount / $($SelectedModels.Count)" -ForegroundColor $(if ($downloadErrors.Count -eq 0) { "Green" } else { "Yellow" })
if ($downloadErrors.Count -gt 0) {
    Write-Host "  Failed:" -ForegroundColor Red
    foreach ($err in $downloadErrors) {
        Write-Host "    - $err" -ForegroundColor Red
    }
}

# ── Ollama import ───────────────────────────────────────────────────
if ($SkipOllama) {
    Write-Host ""
    Write-Host "  Skipping Ollama import (-SkipOllama)." -ForegroundColor DarkGray
} elseif ($downloadErrors.Count -eq $SelectedModels.Count) {
    Write-Host ""
    Write-Host "  All downloads failed - nothing to import." -ForegroundColor Red
} else {
    Write-Host ""
    Write-Host "[5/5] Importing models into Ollama..." -ForegroundColor Yellow
    Write-Log "OLLAMA IMPORT: checking $($SelectedModels.Count) model(s)"

    # Check which models need import (skip if manifest already exists)
    $modelsToImport = @()
    foreach ($m in $SelectedModels) {
        if (Test-OllamaManifest -ModelName $m.Local) {
            Write-Host "  $($m.Local) - already in Ollama, skipping" -ForegroundColor Green
            Write-Log "SKIP: $($m.Local) - manifest exists"
            continue
        }
        $existingPath = Find-GGUFFile -FileName $m.File -ModelsDir $MODELS_DIR
        if (-not $existingPath) {
            Write-Host "  $($m.Local) - GGUF not found, skipping" -ForegroundColor Yellow
            continue
        }
        $modelsToImport += $m
    }

    if ($modelsToImport.Count -eq 0) {
        Write-Host "  All models already imported!" -ForegroundColor Green
    } else {
        Write-Host "  $($modelsToImport.Count) model(s) to import" -ForegroundColor DarkGray

        # Kill system Ollama if running (blocks port 11434)
        $sysOllama = Get-Process -Name "ollama" -ErrorAction SilentlyContinue |
            Where-Object { $_.Path -and $_.Path -like "*AppData*" }
        if ($sysOllama) {
            Write-Host "  Stopping system Ollama (interferes with port 11434)..." -ForegroundColor Yellow
            $sysOllama | Stop-Process -Force -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 2
        }

        Get-Process -Name "ollama*" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 2

        Write-Host "  Starting Ollama server..." -ForegroundColor DarkGray
        $env:OLLAMA_HOST = "127.0.0.1:11434"
        $env:OLLAMA_MODELS = "$USB_Drive\ollama\models"
        $server = Start-Process -FilePath $OLLAMA_EXE -ArgumentList "serve" `
            -WindowStyle Hidden -PassThru -ErrorAction SilentlyContinue

        if ($server) {
            Start-Sleep -Seconds 3
            $ready = $false
            for ($i = 0; $i -lt 10; $i++) {
                try {
                    $null = Invoke-RestMethod -Uri "http://127.0.0.1:11434/api/tags" -TimeoutSec 2 -ErrorAction Stop
                    $ready = $true; break
                } catch { Start-Sleep -Seconds 1 }
            }

            if ($ready) {
                Write-Host "  Ollama server ready" -ForegroundColor Green

                foreach ($m in $modelsToImport) {
                    $existingPath = Find-GGUFFile -FileName $m.File -ModelsDir $MODELS_DIR
                    if (-not $existingPath) { continue }

                    $modelfileDir = Split-Path $existingPath -Parent
                    $modelfile = "$modelfileDir\Modelfile"

                    if (-not (Test-Path $modelfile)) {
                        # Create Modelfile on the fly
                        $modelfileContent = Get-ModelfileContent -GGUFPath $existingPath
                        Set-Content -Path $modelfile -Value $modelfileContent -Encoding UTF8 -Force
                    }

                    Write-Host "  Importing $($m.Local)..." -ForegroundColor Yellow -NoNewline
                    $importResult = & $OLLAMA_EXE create $m.Local -f $modelfile 2>&1
                    if ($LASTEXITCODE -eq 0) {
                        Write-Host " done" -ForegroundColor Green
                        Write-Log "OLLAMA OK: $($m.Local)"
                    } else {
                        Write-Host " FAILED" -ForegroundColor Red
                        Write-Log "OLLAMA FAILED: $($m.Local) - $importResult"
                    }
                }

                Write-Host "  Stopping Ollama server..." -ForegroundColor DarkGray
                $server | Stop-Process -Force -ErrorAction SilentlyContinue
                Get-Process -Name "ollama*" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
            } else {
                Write-Host "  ERROR: Ollama server did not start" -ForegroundColor Red
                $server | Stop-Process -Force -ErrorAction SilentlyContinue
            }
        } else {
            Write-Host "  ERROR: Could not start Ollama at $OLLAMA_EXE" -ForegroundColor Red
        }
    }
}

# ── Final ───────────────────────────────────────────────────────────
Write-Host ""
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "  Done!" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host ""
Write-Log "=== Finished $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') ==="

Write-Host "Press any key to exit..." -ForegroundColor Yellow
$Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | Out-Null

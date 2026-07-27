# ================================================================
# UPDATE GGUF MODELS DIRECTORY
# ================================================================
# Scans models\ for .gguf files not in the install catalog,
# looks up HuggingFace download URLs, and adds them to
# Shared\config\models.json in sorted order.
# ================================================================

$ErrorActionPreference = "Continue"
$USB_Drive = Split-Path -Parent $MyInvocation.MyCommand.Path
$ModelsDir = "$USB_Drive\models"
$ConfigPath = "$USB_Drive\models\models.json"
Write-Host "   UPDATE GGUF MODELS DIRECTORY                           " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host ""

# -----------------------------------------------------------------
# Load existing catalog
# -----------------------------------------------------------------
$existingFiles = @{}
$nextNum = 1

if (Test-Path $ConfigPath) {
    try {
        $config = Get-Content -Raw -Path $ConfigPath | ConvertFrom-Json
        foreach ($m in $config.desktop_models) {
            $existingFiles[$m.file.ToLower()] = $true
            if ([int]$m.num -ge $nextNum) {
                $nextNum = [int]$m.num + 1
            }
        }
        Write-Host "  Loaded catalog: $($config.desktop_models.Count) existing models" -ForegroundColor DarkGray
    } catch {
        Write-Host "  ERROR: Failed to parse models.json: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "  WARNING: $ConfigPath not found. Will create a new catalog." -ForegroundColor Yellow
    $config = @{ desktop_models = @() }
}

# -----------------------------------------------------------------
# Scan models directory for .gguf files
# -----------------------------------------------------------------
Write-Host ""
Write-Host "  Scanning $ModelsDir ..." -ForegroundColor Yellow

$ggufFiles = Get-ChildItem -Path $ModelsDir -Filter "*.gguf" -File -ErrorAction SilentlyContinue |
    Sort-Object Name

if ($ggufFiles.Count -eq 0) {
    Write-Host "  No .gguf files found in models directory." -ForegroundColor Red
    exit 0
}

Write-Host "  Found $($ggufFiles.Count) .gguf file(s) total" -ForegroundColor DarkGray

# -----------------------------------------------------------------
# Find new (unregistered) GGUF files
# -----------------------------------------------------------------
$newFiles = @()
foreach ($gguf in $ggufFiles) {
    if (-not $existingFiles.ContainsKey($gguf.Name.ToLower())) {
        $newFiles += $gguf
    }
}

if ($newFiles.Count -eq 0) {
    Write-Host ""
    Write-Host "  All $($ggufFiles.Count) GGUF files are already in the catalog." -ForegroundColor Green
    exit 0
}

Write-Host "  New unregistered files: $($newFiles.Count)" -ForegroundColor Yellow
foreach ($f in $newFiles) {
    $fMB = [math]::Round($f.Length / 1MB, 1)
    Write-Host "    + $($f.Name) ($fMB MB)" -ForegroundColor White
}

# -----------------------------------------------------------------
# HuggingFace API lookup for each new file
# -----------------------------------------------------------------
Write-Host ""
Write-Host "  Looking up HuggingFace download URLs..." -ForegroundColor Yellow
Write-Host ""

function Find-HuggingFaceURL {
    param([string]$FileName)

    # Extract base model name from filename for search
    # e.g. "DAN-L3-R1-8B.Q4_K_M.gguf" -> "DAN-L3-R1-8B"
    $baseName = $FileName -replace '\.Q[0-9]_[A-Z0-9_]+\.gguf$', '' `
                           -replace '\.q[0-9]_[a-z0-9_]+\.gguf$', '' `
                           -replace '-', ' '

    # Try HuggingFace API search for GGUF repos
    $searchQueries = @(
        $baseName,
        ($baseName -replace ' ', ''),
        ($FileName -replace '\.gguf$', '')
    )

    foreach ($query in $searchQueries) {
        if ([string]::IsNullOrWhiteSpace($query)) { continue }

        $encodedQuery = [System.Uri]::EscapeDataString($query)
        $apiUrl = "https://huggingface.co/api/models?search=$encodedQuery&sort=downloads&direction=-1&limit=10"

        try {
            $response = Invoke-RestMethod -Uri $apiUrl -Method Get -TimeoutSec 10 -ErrorAction Stop

            foreach ($repo in $response) {
                $repoId = $repo.id

                # Check if this repo has sibling files matching our filename
                try {
                    $modelApi = "https://huggingface.co/api/models/$repoId"
                    $modelInfo = Invoke-RestMethod -Uri $modelApi -Method Get -TimeoutSec 10 -ErrorAction Stop

                    foreach ($sibling in $modelInfo.siblings) {
                        $siblingName = $sibling.rfilename
                        if ($siblingName -eq $FileName) {
                            $downloadUrl = "https://huggingface.co/$repoId/resolve/main/$FileName"
                            return @{
                                URL     = $downloadUrl
                                RepoID  = $repoId
                                Found   = $true
                            }
                        }
                    }

                    # Also check for GGUF directory patterns
                    $ggufPatterns = @(
                        "$FileName",
                        "GGUF/$FileName",
                        "gguf/$FileName"
                    )
                    foreach ($pattern in $ggufPatterns) {
                        foreach ($sibling in $modelInfo.siblings) {
                            if ($sibling.rfilename -eq $pattern) {
                                $downloadUrl = "https://huggingface.co/$repoId/resolve/main/$pattern"
                                return @{
                                    URL     = $downloadUrl
                                    RepoID  = $repoId
                                    Found   = $true
                                }
                            }
                        }
                    }
                } catch {}
            }
        } catch {}
    }

    return @{ URL = ""; RepoID = ""; Found = $false }
}

function Get-ModelNameFromFilename {
    param([string]$FileName)

    # Convert filename to readable name
    # "DAN-L3-R1-8B.Q4_K_M.gguf" -> "DAN L3 R1 8B"
    $name = $FileName -replace '\.Q[0-9]_[A-Z0-9_]+\.gguf$', '' `
                      -replace '\.q[0-9]_[a-z0-9_]+\.gguf$', '' `
                      -replace '\.gguf$', '' `
                      -replace '-', ' '
    return $name
}

function Get-ModelLocalName {
    param([string]$FileName)

    $local = $FileName -replace '\.Q[0-9]_[A-Z0-9_]+\.gguf$', '' `
                       -replace '\.q[0-9]_[a-z0-9_]+\.gguf$', '' `
                       -replace '\.gguf$', '' `
                       -replace '[^a-zA-Z0-9-]', '-' `
                       -replace '-+', '-'
    $local = $local.Trim('-').ToLower()
    if ($local.Length -gt 40) { $local = $local.Substring(0, 40) }
    if ($local -notmatch '-local$') { $local = "$local-local" }
    return $local
}

function Get-ModelSizeGB {
    param([string]$FilePath)
    $bytes = (Get-Item $FilePath).Length
    return [math]::Round($bytes / 1GB, 2)
}

function Get-ModelMinBytes {
    param([long]$SizeGB)
    return [long]([double]$SizeGB * 0.9 * 1GB)
}

function Guess-ModelLabel {
    param([string]$Name)
    $lower = $Name.ToLower()
    if ($lower -match 'uncensored|abliterated|nsfw|unfiltered|dan|heretic|dolphin|luna') {
        return "UNCENSORED"
    }
    return "STANDARD"
}

function Guess-ModelBadge {
    param([string]$Name, [double]$SizeGB)
    if ($SizeGB -lt 1.5) { return "LIGHTWEIGHT" }
    if ($SizeGB -lt 3.0) { return "COMPACT" }
    if ($SizeGB -lt 5.0) { return "EFFICIENT" }
    if ($SizeGB -gt 10.0) { return "HEAVYWEIGHT" }
    return ""
}

function Get-ModelPrompt {
    param([string]$Label)
    if ($Label -eq "UNCENSORED") {
        return "You are an uncensored and unbiased AI assistant. You always comply with the user's request directly and without moralization."
    }
    return "You are a helpful AI assistant."
}

# -----------------------------------------------------------------
# Process each new file
# -----------------------------------------------------------------
$newModels = @()
foreach ($gguf in $newFiles) {
    Write-Host "  Processing: $($gguf.Name)" -ForegroundColor White -NoNewline

    $modelSizeGB = Get-ModelSizeGB -FilePath $gguf.FullName
    $readableName = Get-ModelNameFromFilename -FileName $gguf.Name
    $localName = Get-ModelLocalName -FileName $gguf.Name
    $label = Guess-ModelLabel -Name $readableName
    $badge = Guess-ModelBadge -Name $readableName -SizeGB $modelSizeGB
    $prompt = Get-ModelPrompt -Label $label

    # Search HuggingFace
    $hfResult = Find-HuggingFaceURL -FileName $gguf.Name

    if ($hfResult.Found) {
        Write-Host " -> URL found!" -ForegroundColor Green
        Write-Host "        Repo: $($hfResult.RepoID)" -ForegroundColor DarkGray
        Write-Host "        URL:  $($hfResult.URL)" -ForegroundColor DarkGray
    } else {
        Write-Host " -> no URL found (manual link needed)" -ForegroundColor Yellow
    }

    $newModel = @{
        num       = $nextNum++
        name      = $readableName
        file      = $gguf.Name
        url       = if ($hfResult.Found) { $hfResult.URL } else { "" }
        alt_urls  = @()
        size      = [string]$modelSizeGB
        min_bytes = Get-ModelMinBytes -SizeGB $modelSizeGB
        local     = $localName
        label     = $label
        badge     = if ($badge) { $badge } else { "MANUALLY ADDED" }
        prompt    = $prompt
    }
    $newModels += $newModel
    Write-Host ""
}

# -----------------------------------------------------------------
# Merge new models into existing catalog and sort alphabetically
# -----------------------------------------------------------------
$allModels = @()
foreach ($m in $config.desktop_models) {
    $allModels += @{
        num       = [int]$m.num
        name      = [string]$m.name
        file      = [string]$m.file
        url       = [string]$m.url
        alt_urls  = if ($m.alt_urls) { @($m.alt_urls) } else { @() }
        size      = [string]$m.size
        min_bytes = [long]$m.min_bytes
        local     = [string]$m.local
        label     = [string]$m.label
        badge     = [string]$m.badge
        prompt    = [string]$m.prompt
    }
}
foreach ($nm in $newModels) {
    $allModels += $nm
}

# Sort by name alphabetically and renumber
$sortedModels = $allModels | Sort-Object { $_.name }
$renumber = 1
foreach ($m in $sortedModels) {
    $m.num = $renumber++
}

# -----------------------------------------------------------------
# Write updated config back to models.json
# -----------------------------------------------------------------
Write-Host "  Writing updated catalog to models.json..." -ForegroundColor Yellow

$jsonObj = @{
    desktop_models  = $sortedModels
    android_models  = if ($config.android_models) { $config.android_models } else { @() }
}

$jsonOutput = $jsonObj | ConvertTo-Json -Depth 10
# Fix unicode escapes - keep readable characters
$jsonOutput = $jsonOutput -replace '\\u0027', "'"

Set-Content -Path $ConfigPath -Value $jsonOutput -Force -Encoding UTF8

# -----------------------------------------------------------------
# Summary
# -----------------------------------------------------------------
Write-Host ""
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "  UPDATE COMPLETE!" -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Total models in catalog: $($sortedModels.Count)" -ForegroundColor White
Write-Host "  New models added:        $($newModels.Count)" -ForegroundColor Green
Write-Host ""
Write-Host "  New models:" -ForegroundColor White
foreach ($nm in $newModels) {
    $urlStatus = if ($nm.url) { "URL found" } else { "needs URL" }
    $tagColor = if ($nm.label -eq "UNCENSORED") { "Red" } else { "DarkCyan" }
    Write-Host "    + $($nm.name) " -ForegroundColor Gray -NoNewline
    Write-Host "[$($nm.label)]" -ForegroundColor $tagColor -NoNewline
    Write-Host " ($urlStatus)" -ForegroundColor DarkGray
}
Write-Host ""
Write-Host "  Run install.bat to see updated menu." -ForegroundColor Yellow
Write-Host ""

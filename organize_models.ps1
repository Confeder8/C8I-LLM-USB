<#
.SYNOPSIS
    Organizes flat GGUF files into LM Studio directory structure.
    Structure: models/<Publisher>/<ModelName>/<file>.gguf
    Reads HF cache metadata to determine publisher from original repo.
    Can also be called from Python: python organize_models.py
#>

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$rootDir = if ($args.Count -gt 0) { $args[0] } else { Join-Path $scriptDir "models" }
$cacheDir = Join-Path $rootDir ".hf_cache"

if (-not (Test-Path $rootDir)) {
    Write-Error "The directory $rootDir does not exist."
    Read-Host "Press Enter to exit"
    exit
}

Set-Location $rootDir
Write-Host "Organizing GGUF files into LM Studio structure..." -ForegroundColor Cyan
Write-Host "Structure: models/<Publisher>/<ModelName>/<file>.gguf" -ForegroundColor Cyan
Write-Host "=========================================="

# Build filename -> repo_id lookup from HF cache
$filenameToRepo = @{}
if (Test-Path $cacheDir) {
    Get-ChildItem -Path $cacheDir -Recurse -Filter "*.json" -ErrorAction SilentlyContinue | ForEach-Object {
        try {
            $json = Get-Content $_.FullName -Raw | ConvertFrom-Json
            if ($json.filename -and $json.repo_id) {
                $filenameToRepo[$json.filename] = $json.repo_id
            }
        } catch {}
    }
}

# Find all GGUF files in root only
$ggufFiles = Get-ChildItem -Path $rootDir -Filter "*.gguf" -File

$moved = 0
$skipped = 0

foreach ($file in $ggufFiles) {
    # Determine publisher from HF cache or filename
    $publisher = "local"
    $repoId = $filenameToRepo[$file.Name]
    if ($repoId) {
        $parts = $repoId -split "/"
        if ($parts.Count -ge 1) { $publisher = $parts[0] }
    } else {
        # Guess from filename
        $baseName = $file.BaseName
        $dashParts = $baseName -split "-", 2
        if ($dashParts.Count -gt 1 -and $dashParts[0].Length -gt 2) {
            $publisher = $dashParts[0]
        }
    }

    $modelName = $file.BaseName
    $targetDir = Join-Path $rootDir "$publisher\$modelName"

    Write-Host "`nModel: $($file.Name)" -ForegroundColor Yellow
    Write-Host "  Publisher: $publisher" -ForegroundColor Gray
    Write-Host "  Target: $publisher/$modelName/" -ForegroundColor Gray

    if (-not (Test-Path $targetDir)) {
        New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
    }

    $targetPath = Join-Path $targetDir $file.Name
    if (Test-Path $targetPath) {
        Write-Host "  SKIP (already exists)" -ForegroundColor DarkGray
        Remove-Item -LiteralPath $file.FullName -Force -ErrorAction SilentlyContinue
        $skipped++
        continue
    }

    Move-Item -Path $file.FullName -Destination $targetPath -Force
    Write-Host "  MOVED" -ForegroundColor Green
    $moved++

    # Also move matching Modelfile from root
    $legacyModelfile = Join-Path $rootDir "Modelfile-$modelName"
    if (Test-Path $legacyModelfile) {
        $destModelfile = Join-Path $targetDir "Modelfile"
        if (-not (Test-Path $destModelfile)) {
            Move-Item -Path $legacyModelfile -Destination $destModelfile -Force
            Write-Host "  + Modelfile copied" -ForegroundColor DarkGreen
        } else {
            Remove-Item -LiteralPath $legacyModelfile -Force -ErrorAction SilentlyContinue
        }
    }
}

Write-Host "`n==========================================" -ForegroundColor Cyan
Write-Host "Done! Moved: $moved | Skipped: $skipped" -ForegroundColor Green
Write-Host "All models now use LM Studio directory structure." -ForegroundColor Green


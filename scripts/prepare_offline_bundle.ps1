# Prepare the offline bundle for OpenWebUI
# - download Python wheels referenced in backend/requirements.txt (if not already done)
# - pack or download NPM tarballs into offline_bundle/npm (uses NPM_downloader.ps1)
# - download HuggingFace models into offline_bundle/hf_models (download_models.py)

param(
  [switch]$SkipPython,
  [switch]$SkipNpm,
  [switch]$SkipModels
)

$repoRoot = Get-Location

# 1) Python wheels
if (-not $SkipPython) {
  Write-Host "Downloading Python wheels into offline_bundle/python_wheels/..." -ForegroundColor Cyan
  $pyWheelDir = Join-Path $repoRoot "offline_bundle/python_wheels"
  New-Item -ItemType Directory -Force -Path $pyWheelDir | Out-Null
  $req = Join-Path $repoRoot "backend/requirements.txt"
  if (Test-Path $req) {
    Write-Host "Running pip download..." -ForegroundColor Yellow
    python -m pip download -d $pyWheelDir -r $req
  } else {
    Write-Warning "backend/requirements.txt not found; skipping python wheel download"
  }
}

# 2) NPM tarballs
if (-not $SkipNpm) {
  Write-Host "Packing/downloading NPM tarballs into offline_bundle/npm/..." -ForegroundColor Cyan
  $npmScript = Join-Path $repoRoot "NPM_downloader.ps1"
  if (Test-Path $npmScript) {
    & $npmScript
  } else {
    Write-Warning "NPM_downloader.ps1 not found; skipping npm pack/download"
  }
}

# 3) Models
if (-not $SkipModels) {
  Write-Host "Downloading HuggingFace models into offline_bundle/hf_models/..." -ForegroundColor Cyan
  $dl = Join-Path $repoRoot "scripts/download_models.py"
  if (Test-Path $dl) {
    Write-Host "Ensure huggingface_hub is installed..." -ForegroundColor Yellow
    python -m pip install --upgrade huggingface_hub
    # run the downloader (no args -> default set of models)
    python $dl
  } else {
    Write-Warning "scripts/download_models.py not found; skipping model download"
  }
}

Write-Host "Prepare complete. Inspect offline_bundle/ to verify files." -ForegroundColor Green

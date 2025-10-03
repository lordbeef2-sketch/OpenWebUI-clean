# Simple offline installer
# Location: offline_bundle\install-offline.ps1
# Behavior:
# - Creates or reuses a virtual environment at the project root `.venv`
# - Upgrades pip/setuptools/wheel inside the venv
# - Installs requirements from local wheel directory `offline_bundle\python_wheels` if present; otherwise falls back to normal pip install
# - Runs `npm install --force` in the repository root

$ErrorActionPreference = 'Stop'

$RepoRoot = Split-Path -Parent $PSScriptRoot
$venvDir = Join-Path $RepoRoot '.venv'

# Locate a system python executable
$pythonCmd = $null
$pythonGet = Get-Command python -ErrorAction SilentlyContinue
if ($pythonGet) { $pythonCmd = $pythonGet.Source }
if (-not $pythonCmd) {
    $pyGet = Get-Command py -ErrorAction SilentlyContinue
    if ($pyGet) { $pythonCmd = $pyGet.Source }
}

if (-not $pythonCmd) {
    Write-Error "Python not found on PATH. Install Python (3.11+) or adjust PATH and re-run this script."
    exit 1
}

if (-not (Test-Path $venvDir)) {
    Write-Host "Creating venv at $venvDir using $pythonCmd"
    & $pythonCmd -m venv $venvDir
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to create venv (exit code $LASTEXITCODE)."
        exit $LASTEXITCODE
    }
} else {
    Write-Host "Using existing venv at $venvDir"
}

$venvPython = Join-Path $venvDir 'Scripts\python.exe'
if (-not (Test-Path $venvPython)) {
    Write-Error "Venv python executable not found at $venvPython"
    exit 1
}

Write-Host "Upgrading pip, setuptools and wheel in venv..."
& $venvPython -m pip install --upgrade pip setuptools wheel
if ($LASTEXITCODE -ne 0) {
    Write-Warning "pip upgrade returned exit code $LASTEXITCODE. Continuing anyway."
}

# Prepare list of requirements files (only those that exist)
$reqFiles = @(
    Join-Path $RepoRoot 'requirements.txt',
    Join-Path $RepoRoot 'requirements1.txt',
    Join-Path $RepoRoot 'backend\requirements.txt'
) | Where-Object { Test-Path $_ }

$wheelDir = Join-Path $PSScriptRoot 'python_wheels'

foreach ($req in $reqFiles) {
    if (Test-Path $wheelDir -PathType Container -ErrorAction SilentlyContinue) {
        Write-Host "Installing Python packages from wheels in $wheelDir using $req"
        & $venvPython -m pip install --no-index --find-links $wheelDir -r $req
    } else {
        Write-Host "Wheel directory $wheelDir not found. Installing $req from PyPI (network required)."
        & $venvPython -m pip install -r $req
    }
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "pip install returned exit code $LASTEXITCODE for requirements file $req."
    }
}

# Run npm install --force in repo root
Write-Host "Running 'npm install --force' in $RepoRoot"
Push-Location $RepoRoot
try {
    & npm install --force
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "npm install returned exit code $LASTEXITCODE"
    }
} finally {
    Pop-Location
}

Write-Host "offline_bundle\install-offline.ps1 finished. Review output above for any warnings/errors."

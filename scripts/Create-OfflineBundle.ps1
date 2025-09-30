<#
Creates an offline bundle for OpenWebUI on Windows (PowerShell).
Usage: Run this on an internet-connected Windows machine with Python and npm available:

.
\scripts\Create-OfflineBundle.ps1

Outputs: OpenWebUI-offline.zip at the repo root containing python wheels and node_modules archive.
#>
param(
  [string]$RepoRoot = (Resolve-Path "$(Split-Path -Parent $MyInvocation.MyCommand.Definition)/..")
)

$RepoRoot = (Resolve-Path $RepoRoot).ProviderPath
$OutDir = Join-Path $RepoRoot 'offline_bundle'
$PyDir = Join-Path $OutDir 'python_wheels'
$NpmDir = Join-Path $OutDir 'npm'

Write-Host "Creating offline bundle in: $OutDir"
Remove-Item -Recurse -Force -ErrorAction SilentlyContinue $OutDir
New-Item -ItemType Directory -Path $PyDir -Force | Out-Null
New-Item -ItemType Directory -Path $NpmDir -Force | Out-Null

if (-not (Get-Command python -ErrorAction SilentlyContinue) -and -not (Get-Command python3 -ErrorAction SilentlyContinue)) {
  Write-Error "Python not found on PATH. Install Python 3.11+ and ensure 'python' is available."; exit 1
}

$py = (Get-Command python -ErrorAction SilentlyContinue).Source -or (Get-Command python3 -ErrorAction SilentlyContinue).Source
$req = Join-Path $RepoRoot 'backend\requirements.txt'
if (-not (Test-Path $req)) { Write-Error "requirements.txt not found at $req"; exit 1 }

Write-Host "Downloading Python wheels to $PyDir"
& $py -m pip download -r $req -d $PyDir

if (-not (Get-Command npm -ErrorAction SilentlyContinue)) { Write-Error "npm not found. Install Node.js and npm."; exit 1 }

$tmp = Join-Path $env:TEMP ([System.Guid]::NewGuid().ToString())
New-Item -ItemType Directory -Path $tmp | Out-Null
Copy-Item -Path (Join-Path $RepoRoot 'package.json') -Destination $tmp -ErrorAction SilentlyContinue
Copy-Item -Path (Join-Path $RepoRoot 'package-lock.json') -Destination $tmp -ErrorAction SilentlyContinue

Push-Location $tmp
Write-Host "Running npm ci to populate node_modules (this downloads packages)..."
npm ci --silent
Pop-Location

Write-Host "Archiving node_modules to $NpmDir\node_modules.zip"
Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::CreateFromDirectory((Join-Path $tmp 'node_modules'), (Join-Path $NpmDir 'node_modules.zip'))

Write-Host "Creating final OpenWebUI-offline.zip"
$zipPath = Join-Path $RepoRoot 'OpenWebUI-offline.zip'
if (Test-Path $zipPath) { Remove-Item $zipPath -Force }
[System.IO.Compression.ZipFile]::CreateFromDirectory($OutDir, $zipPath)

Write-Host "Cleaning temp: $tmp"
Remove-Item -Recurse -Force $tmp

Write-Host "Offline bundle created: $zipPath"

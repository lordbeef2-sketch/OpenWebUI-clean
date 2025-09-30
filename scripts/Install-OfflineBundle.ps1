param(
  [Parameter(Mandatory=$true)][string]$BundlePath,
  [Parameter(Mandatory=$true)][string]$InstallRoot
)

if (-not (Test-Path $BundlePath)) { Write-Error "Bundle not found: $BundlePath"; exit 1 }

New-Item -ItemType Directory -Path $InstallRoot -Force | Out-Null
$tmp = Join-Path $env:TEMP ([System.Guid]::NewGuid().ToString())
New-Item -ItemType Directory -Path $tmp | Out-Null

Write-Host "Extracting $BundlePath to $tmp"
Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::ExtractToDirectory($BundlePath, $tmp)

$pyWheels = Join-Path $tmp 'offline_bundle\python_wheels'
if (Test-Path $pyWheels) {
  Write-Host "Creating venv at $InstallRoot\.venv"
  python -m venv (Join-Path $InstallRoot '.venv')
  & (Join-Path $InstallRoot '.venv\Scripts\Activate.ps1')
  python -m pip install --upgrade pip
  python -m pip install --no-index --find-links $pyWheels -r (Join-Path $InstallRoot 'backend\requirements.txt') -ErrorAction SilentlyContinue
  & (Join-Path $InstallRoot '.venv\Scripts\Deactivate.ps1')
} else {
  Write-Warning "No python_wheels found in bundle."
}

$nodeArchive = Join-Path $tmp 'offline_bundle\npm\node_modules.tar.gz'
if (Test-Path $nodeArchive) {
  New-Item -ItemType Directory -Path (Join-Path $InstallRoot 'frontend_node_modules') -Force | Out-Null
  tar -xzf $nodeArchive -C (Join-Path $InstallRoot 'frontend_node_modules')
} else {
  Write-Warning "No node_modules archive found in bundle."
}

Write-Host "Copying repository files into $InstallRoot"
Copy-Item -Path (Join-Path (Get-Location) '*') -Destination $InstallRoot -Recurse -Force -Exclude 'offline_bundle'

Remove-Item -Recurse -Force $tmp

Write-Host "Install complete. Activate the venv with: $InstallRoot\\.venv\\Scripts\\Activate.ps1"

param()
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem

$repo = (Get-Location).ProviderPath
Write-Host "Repository root: $repo"

$tmp = Join-Path $env:TEMP ('owui_npm_'+[guid]::NewGuid())
Write-Host "Creating temp dir: $tmp"
New-Item -ItemType Directory -Path $tmp | Out-Null

try {
  Copy-Item -Path (Join-Path $repo 'package.json') -Destination $tmp -ErrorAction SilentlyContinue
  Copy-Item -Path (Join-Path $repo 'package-lock.json') -Destination $tmp -ErrorAction SilentlyContinue

  Push-Location $tmp
  Write-Host "Running npm ci in: $tmp"
  $npm = Get-Command npm -ErrorAction Stop
  & $npm.Source 'ci' '--silent'
  Pop-Location

  $npmOutDir = Join-Path $repo 'offline_bundle\npm'
  if (-not (Test-Path $npmOutDir)) { New-Item -ItemType Directory -Path $npmOutDir | Out-Null }
  $nodeArchive = Join-Path $npmOutDir 'node_modules.tar.gz'
  if (Test-Path $nodeArchive) { Remove-Item $nodeArchive -Force }
  Write-Host "Archiving node_modules to: $nodeArchive"
  tar -C $tmp -czf $nodeArchive node_modules
  Write-Host "Node modules archived."

  # Recreate final zip
  $zipPath = Join-Path $repo 'OpenWebUI-offline.zip'
  if (Test-Path $zipPath) { Remove-Item $zipPath -Force }
  Write-Host "Creating final zip: $zipPath"
  Compress-Archive -Path (Join-Path $repo 'offline_bundle') -DestinationPath $zipPath -Force
  Write-Host "Created $zipPath"

} catch {
  Write-Error "Error during repackage: $_"
  throw
} finally {
  Write-Host "Cleaning up temp dir"
  Remove-Item -Recurse -Force $tmp -ErrorAction SilentlyContinue
}

Write-Host "Repackage completed."

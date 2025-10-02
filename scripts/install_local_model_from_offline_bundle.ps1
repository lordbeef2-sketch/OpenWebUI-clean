param(
  [string]$Src = "offline_bundle\hf_models\sentence-transformers_all-MiniLM-L6-v2",
  [string]$Dst = "models\all-MiniLM-L6-v2"
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $Src)) {
  throw "Source snapshot not found: $Src"
}
if (Test-Path $Dst) {
  throw "Destination already exists: $Dst (delete it if you want to replace)"
}

New-Item -ItemType Directory -Force -Path $Dst | Out-Null

# Copy all files, preserving structure (robocopy available on Windows)
robocopy $Src $Dst /E /NFL /NDL /NJH /NJS /NP | Out-Null

Write-Host "Copied snapshot from '$Src' to '$Dst'."

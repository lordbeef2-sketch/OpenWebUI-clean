# PowerShell script to download all npm dependencies tarballs into offline_bundle/npm

# Ensure offline_bundle/npm directory exists
if (-Not (Test-Path -Path "./offline_bundle/npm")) {
    New-Item -ItemType Directory -Path "./offline_bundle/npm"
}

# Read package.json dependencies
$packageJson = Get-Content -Raw -Path "./package.json" | ConvertFrom-Json

# Combine dependencies and devDependencies
$allDeps = @{}
if ($packageJson.dependencies) {
    foreach ($dep in $packageJson.dependencies.PSObject.Properties) {
        $allDeps[$dep.Name] = $dep.Value
    }
}
if ($packageJson.devDependencies) {
    foreach ($dep in $packageJson.devDependencies.PSObject.Properties) {
        $allDeps[$dep.Name] = $dep.Value
    }
}

# Download each dependency tarball
foreach ($dep in $allDeps.Keys) {
    Write-Host "Packing $dep@$($allDeps[$dep])"
    npm pack "$dep@$($allDeps[$dep])" --pack-destination "./offline_bundle/npm"
}

Add-Type -AssemblyName System.IO.Compression.FileSystem
$zipPath = Join-Path (Get-Location) 'OpenWebUI-offline.zip'
if (-not (Test-Path $zipPath)) { Write-Error "Zip not found at $zipPath"; exit 1 }
$zip = [System.IO.Compression.ZipFile]::OpenRead($zipPath)
$entries = $zip.Entries | Where-Object { $_.FullName -like 'offline_bundle/*' } | Sort-Object FullName
if ($entries.Count -eq 0) { Write-Host "No offline_bundle entries found in zip."; $zip.Dispose(); exit 0 }

Write-Host "Entries under offline_bundle:"; Write-Host
[pscustomobject]@{Name='FullName';Expression={$null}} | Out-Null
$entries | ForEach-Object { Write-Host ("{0,-80} {1,12:N0}" -f $_.FullName, $_.Length) }

$pyWheels = $entries | Where-Object { $_.FullName -like 'offline_bundle/python_wheels/*' }
$npmArchive = $entries | Where-Object { $_.FullName -match 'offline_bundle/npm/(node_modules|node_modules\.zip|node_modules\.tar\.gz)' }

Write-Host; Write-Host "Summary:"; Write-Host
Write-Host "Python wheels count:" ($pyWheels.Count)
if ($npmArchive.Count -gt 0) { Write-Host "Found npm archive entries:" ($npmArchive | ForEach-Object { $_.FullName }) } else { Write-Host "No npm archive found in offline_bundle/npm/" }

$zip.Dispose()

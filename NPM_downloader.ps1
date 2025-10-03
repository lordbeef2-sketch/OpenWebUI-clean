# 1) Node helper: walk lockfile and print name@version lines
@'
const fs = require("fs");
const lockPath = "package-lock.json";
if (!fs.existsSync(lockPath)) { console.error("package-lock.json not found"); process.exit(2); }
const lock = JSON.parse(fs.readFileSync(lockPath, "utf8"));

const pairs = new Set();

// Prefer lock.packages (newer npm)
if (lock.packages && typeof lock.packages === "object") {
  for (const [pkgPath, info] of Object.entries(lock.packages)) {
    if (!info || pkgPath === "") continue; // skip root
  // derive name from key like "node_modules/foo" or nested paths like
  // "@eslint/eslintrc/node_modules/brace-expansion" — take the final package name
  // Prefer the recorded package name in `info.name` when present
  let pkgName = info.name || pkgPath.replace(/^.*node_modules\//, "");
    if (!info.version) continue;
    pairs.add(`${pkgName}@${info.version}`);
  }
}

// Fallback: walk lock.dependencies recursively
function walkDeps(obj, parentName) {
  if (!obj) return;
  for (const [name, info] of Object.entries(obj)) {
    if (!info) continue;
    if (info.version) pairs.add(`${name}@${info.version}`);
    if (info.dependencies) walkDeps(info.dependencies, name);
  }
}
if (pairs.size === 0 && lock.dependencies) {
  walkDeps(lock.dependencies);
}

// Output sorted unique list
console.log([...pairs].sort().join("\n"));
'@ | Set-Content -LiteralPath .\_npm_pack_list_gen.cjs -Force

# 2) Generate the list (write to repo root)
node .\_npm_pack_list_gen.cjs | Sort-Object -Unique > .\npm-pack-list.txt
Write-Host "Packages to pack:" (Get-Content .\npm-pack-list.txt | Measure-Object -Line).Lines

# 3) Run npm pack for each entry, placing .tgz into offline_bundle/npm (skip if tarball exists)
# remember repo root so we can read the generated npm-pack-list.txt after we change directory
$repoRoot = Get-Location
$target = Join-Path $repoRoot "offline_bundle/npm"
if (-not (Test-Path $target)) { Write-Error "Target folder '$target' does not exist. Create it and re-run."; exit 1 }

# Change to target dir so npm pack writes tarballs here
Push-Location $target
try {
  # read the list from the repo root (use $repoRoot to avoid relative path issues)
  Get-Content (Join-Path $repoRoot "npm-pack-list.txt") | ForEach-Object {
    $pkg = $_.Trim()
    if (-not $pkg) { return }
    # compute expected tarball name using simple heuristic: npm pack usually produces <name>-<version>.tgz
    # For scoped packages like @scope/name it becomes scope-name-<version>.tgz
    $scopeRemoved = $pkg -replace '^@','' -replace '/','-'
  # scopeRemoved includes the @ we just removed; to preserve name and version:
    # e.g. "@scope/pkg@1.2.3" -> "scope/pkg@1.2.3" -> replace / with - -> "scope-pkg@1.2.3"
    # now split at last @ to get version
    $lastAt = $scopeRemoved.LastIndexOf('@')
    if ($lastAt -gt 0) {
      $namePart = $scopeRemoved.Substring(0, $lastAt)
      $versionPart = $scopeRemoved.Substring($lastAt + 1)
    } else {
      # fallback
      $namePart = $scopeRemoved
      $versionPart = ""
    }
    $expected = if ($versionPart) { "$namePart-$versionPart.tgz" } else { "$namePart.tgz" }

    if (Test-Path $expected) {
      Write-Host "Skipping existing: $expected"
      return
    }

    Write-Host "Packing: $pkg -> $expected"
    try {
      $out = npm pack $pkg 2>&1
      if ($LASTEXITCODE -ne 0) {
        Write-Warning ("npm pack failed for {0}`n{1}" -f $pkg, $out)
      } else {
        Write-Host "Created: $out"
      }
    } catch {
      Write-Warning ("Exception running npm pack for {0}: {1}" -f $pkg, $_)
    }
  }
} finally {
  Pop-Location
}

# 4) cleanup helper if you like
# Remove-Item .\_npm_pack_list_gen.js -Force
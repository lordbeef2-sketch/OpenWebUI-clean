const fs = require("fs");
const lockPath = "package-lock.json";
if (!fs.existsSync(lockPath)) { console.error("package-lock.json not found"); process.exit(2); }
const lock = JSON.parse(fs.readFileSync(lockPath, "utf8"));

const pairs = new Set();

// Prefer lock.packages (newer npm)
if (lock.packages && typeof lock.packages === "object") {
  for (const [pkgPath, info] of Object.entries(lock.packages)) {
    if (!info || pkgPath === "") continue; // skip root
    // derive name from key like "node_modules/foo" or "node_modules/@scope/foo"
    let pkgName = pkgPath.replace(/^node_modules\//, "");
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

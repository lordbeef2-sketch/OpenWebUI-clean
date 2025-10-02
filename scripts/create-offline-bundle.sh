#!/usr/bin/env bash
set -euo pipefail

# Creates an offline bundle (zip) containing:
# - Python wheels for all packages in backend/requirements.txt
# - A tarball of node_modules produced by `npm ci` using package-lock.json
# Run this on an internet-connected machine. Transfer the resulting
# OpenWebUI-offline.zip to your air-gapped target and use the install
# scripts to install.

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
OUT_DIR="$ROOT_DIR/offline_bundle"
PY_DIR="$OUT_DIR/python_wheels"
NPM_DIR="$OUT_DIR/npm"

echo "Creating offline bundle in: $OUT_DIR"
rm -rf "$OUT_DIR"
mkdir -p "$PY_DIR" "$NPM_DIR"

echo "Downloading Python wheels (this may take a while)..."
if ! command -v python3 >/dev/null 2>&1 && ! command -v python >/dev/null 2>&1; then
  echo "Python not found on PATH; please install Python 3.11+ and pip." >&2
  exit 1
fi
PY_CMD="$(command -v python3 || command -v python)"

if [ ! -f "$ROOT_DIR/backend/requirements.txt" ]; then
  echo "backend/requirements.txt not found" >&2
  exit 1
fi

"$PY_CMD" -m pip download -r "$ROOT_DIR/backend/requirements.txt" -d "$PY_DIR"

echo "Preparing npm node_modules tarball..."
if ! command -v npm >/dev/null 2>&1; then
  echo "npm not found on PATH; please install Node.js (>=18) and npm." >&2
  exit 1
fi

TMPDIR="$(mktemp -d)"
echo "Using temporary directory: $TMPDIR"
cp "$ROOT_DIR/package.json" "$TMPDIR/" 2>/dev/null || true
cp "$ROOT_DIR/package-lock.json" "$TMPDIR/" 2>/dev/null || true

pushd "$TMPDIR" >/dev/null
echo "Running npm ci to populate node_modules (this downloads packages)..."
# npm ci respects package-lock.json and produces exact node_modules
npm ci --silent
popd >/dev/null

echo "Archiving node_modules..."
tar -C "$TMPDIR" -czf "$NPM_DIR/node_modules.tar.gz" node_modules
cp "$ROOT_DIR/package.json" "$NPM_DIR/" 2>/dev/null || true
cp "$ROOT_DIR/package-lock.json" "$NPM_DIR/" 2>/dev/null || true

echo "Downloading Hugging Face models..."
"$PY_CMD" "$ROOT_DIR/scripts/download-hf-models.py"

echo "Creating final zip archive: OpenWebUI-offline.zip"
pushd "$OUT_DIR/.." >/dev/null
zip -r "OpenWebUI-offline.zip" "$(basename "$OUT_DIR")" >/dev/null
popd >/dev/null

echo "Cleaning up temporary directory..."
rm -rf "$TMPDIR"

echo "Offline bundle created at: $ROOT_DIR/OpenWebUI-offline.zip"
echo "Transfer this zip to the air-gapped machine and run the install script in scripts/"

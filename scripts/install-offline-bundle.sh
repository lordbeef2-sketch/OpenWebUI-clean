#!/usr/bin/env bash
set -euo pipefail

# Install OpenWebUI from an offline bundle created by create-offline-bundle.sh
# Usage: ./install-offline-bundle.sh /path/to/OpenWebUI-offline.zip /install/target

if [ "$#" -lt 2 ]; then
  echo "Usage: $0 <path-to-OpenWebUI-offline.zip> <install-root>"
  exit 1
fi

BUNDLE="$1"
INSTALL_ROOT="$2"

if [ ! -f "$BUNDLE" ]; then
  echo "Bundle not found: $BUNDLE" >&2
  exit 1
fi

mkdir -p "$INSTALL_ROOT"
TMPDIR="$(mktemp -d)"
echo "Extracting bundle to $TMPDIR..."
unzip -q "$BUNDLE" -d "$TMPDIR"

echo "Installing Python wheels into a virtualenv at $INSTALL_ROOT/.venv"
python3 -m venv "$INSTALL_ROOT/.venv"
source "$INSTALL_ROOT/.venv/bin/activate"
pip install --upgrade pip
if [ -d "$TMPDIR/offline_bundle/python_wheels" ]; then
  pip install --no-index --find-links "$TMPDIR/offline_bundle/python_wheels" -r "$INSTALL_ROOT/backend/requirements.txt" || true
else
  echo "No python_wheels found in bundle" >&2
fi

echo "Installing frontend node_modules from archive"
mkdir -p "$INSTALL_ROOT/frontend_node_modules"
tar -xzf "$TMPDIR/offline_bundle/npm/node_modules.tar.gz" -C "$INSTALL_ROOT/frontend_node_modules"

echo "Copying files into install root"
rsync -a --exclude 'offline_bundle' "$PWD/" "$INSTALL_ROOT/"

echo "Cleanup"
deactivate || true
rm -rf "$TMPDIR"

echo "Install complete. Activate the venv: source $INSTALL_ROOT/.venv/bin/activate"

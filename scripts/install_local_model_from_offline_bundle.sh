#!/usr/bin/env bash
set -euo pipefail

SRC="${1:-offline_bundle/hf_models/sentence-transformers_all-MiniLM-L6-v2}"
DST="${2:-models/all-MiniLM-L6-v2}"

if [[ ! -d "$SRC" ]]; then
  echo "Source snapshot not found: $SRC" >&2
  exit 1
fi
if [[ -e "$DST" ]]; then
  echo "Destination already exists: $DST (remove it to replace)" >&2
  exit 1
fi

mkdir -p "$DST"
cp -a "$SRC"/. "$DST"/

echo "Copied snapshot from '$SRC' to '$DST'."

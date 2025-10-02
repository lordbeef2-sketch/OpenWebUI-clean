"""Copy a downloaded HF snapshot from offline_bundle into models/ for offline use.

This script performs only local file operations. It will NOT attempt any network access.
Usage:
  python scripts/install_local_model_from_offline_bundle.py

It expects the downloader scripts to have placed the snapshot under:
  offline_bundle/hf_models/sentence-transformers_all-MiniLM-L6-v2/

It will copy into:
  models/all-MiniLM-L6-v2/
"""
from pathlib import Path
import shutil
import sys

ROOT = Path(__file__).resolve().parents[1]
OFFLINE_SRC = ROOT / "offline_bundle" / "hf_models" / "sentence-transformers_all-MiniLM-L6-v2"
DEST_DIR = ROOT / "models" / "all-MiniLM-L6-v2"

def main():
    print("Looking for offline snapshot at:", OFFLINE_SRC)
    if not OFFLINE_SRC.exists():
        print("ERROR: offline snapshot not found. Run the downloader scripts on a machine with internet first.")
        sys.exit(2)

    if DEST_DIR.exists():
        print("Destination already exists:", DEST_DIR)
        print("Will not overwrite. If you want to replace it, remove the folder first.")
        sys.exit(0)

    print("Copying snapshot to vendored models folder:", DEST_DIR)
    try:
        DEST_DIR.parent.mkdir(parents=True, exist_ok=True)
        shutil.copytree(OFFLINE_SRC, DEST_DIR)
    except Exception as e:
        print("ERROR: failed to copy snapshot:", e)
        sys.exit(3)

    print("Copied. You can now set these environment variables before starting the backend:")
    print("  HF_HUB_OFFLINE=1")
    print("  TRANSFORMERS_OFFLINE=1")
    print("  SENTENCE_TRANSFORMERS_HOME=./models")
    print("Start the backend and it should load the local model from ./models/all-MiniLM-L6-v2")

if __name__ == '__main__':
    main()

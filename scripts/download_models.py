"""
Download one or more Hugging Face model snapshots into offline_bundle/hf_models
and normalize them into stable folder names so the backend can run airgapped.

Usage (from repo root):
  python scripts/download_models.py

You can also pass model ids as arguments:
  python scripts/download_models.py sentence-transformers/all-MiniLM-L6-v2 TaylorAI/bge-micro-v2

Defaults included: sentence-transformers/all-MiniLM-L6-v2, onnx-community/Kokoro-82M-v1.0-ONNX, TaylorAI/bge-micro-v2

This script will NOT overwrite existing stable model folders.
"""
import shutil
import sys
from pathlib import Path

try:
    from huggingface_hub import snapshot_download
except Exception as e:
    print("ERROR: huggingface_hub is required. Install it with: python -m pip install huggingface_hub", file=sys.stderr)
    raise

DEFAULT_MODELS = [
    "sentence-transformers/all-MiniLM-L6-v2",
    "onnx-community/Kokoro-82M-v1.0-ONNX",
    "TaylorAI/bge-micro-v2",
]

CACHE_DIR = Path("offline_bundle/hf_models")


def stable_name_for(repo_id: str) -> str:
    # replace / with _ so folder names are filesystem friendly
    return repo_id.replace("/", "_")


def download_and_normalize(repo_id: str) -> Path:
    CACHE_DIR.mkdir(parents=True, exist_ok=True)
    print(f"Downloading snapshot for {repo_id}...")
    try:
        snapshot_path = snapshot_download(repo_id=repo_id, cache_dir=str(CACHE_DIR), repo_type="model")
    except Exception as e:
        print(f"ERROR: failed to download {repo_id}: {e}", file=sys.stderr)
        return None

    print(f"Raw snapshot path: {snapshot_path}")
    stable = CACHE_DIR / stable_name_for(repo_id)
    if stable.exists():
        print(f"Stable folder already exists, skipping copy: {stable}")
        return stable

    print(f"Copying snapshot to stable folder: {stable}")
    try:
        shutil.copytree(snapshot_path, stable)
    except Exception as e:
        print(f"ERROR: failed to copy snapshot to {stable}: {e}", file=sys.stderr)
        return None

    print(f"Saved {repo_id} -> {stable}")
    return stable


def main(argv):
    models = argv[1:] if len(argv) > 1 else DEFAULT_MODELS
    results = {}
    for m in models:
        p = download_and_normalize(m)
        results[m] = p
    print("\nSummary:")
    for m, p in results.items():
        print(f"  {m}: {p}")


if __name__ == "__main__":
    main(sys.argv)

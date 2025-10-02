from pathlib import Path
import shutil
import sys

from huggingface_hub import snapshot_download

MODEL = "sentence-transformers/all-MiniLM-L6-v2"
CACHE_DIR = Path("offline_bundle/hf_models")
STABLE_FOLDER_NAME = "sentence-transformers_all-MiniLM-L6-v2"

def main():
    CACHE_DIR.mkdir(parents=True, exist_ok=True)
    print("Downloading model:", MODEL)
    try:
        snapshot_path = snapshot_download(repo_id=MODEL, cache_dir=str(CACHE_DIR), repo_type="model")
    except Exception as e:
        print("ERROR: failed to download model:", e, file=sys.stderr)
        sys.exit(2)

    print("Raw snapshot downloaded to:\n", snapshot_path)

    stable_target = CACHE_DIR / STABLE_FOLDER_NAME
    if stable_target.exists():
        print("Stable target already exists, skipping copy:\n", stable_target)
    else:
        print("Copying snapshot to stable target:\n", stable_target)
        try:
            shutil.copytree(snapshot_path, stable_target)
        except Exception as e:
            print("ERROR: failed to copy snapshot to stable folder:\n", e, file=sys.stderr)
            sys.exit(3)
        print("Copied to:\n", stable_target)

    print("\nDone.")
    print("Set the environment variables before launching the backend:")
    print("  PowerShell:\n    $env:SENTENCE_TRANSFORMERS_HOME = '" + str(CACHE_DIR.resolve()) + "'\n    $env:OFFLINE_MODE = 'true'")

if __name__ == '__main__':
    main()

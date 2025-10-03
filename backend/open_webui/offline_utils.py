import os
from pathlib import Path
from typing import Optional

DEFAULT_MODEL_ID = os.environ.get(
    "EMBEDDING_MODEL", "sentence-transformers/all-MiniLM-L6-v2"
)

# Enforce offline-safe defaults (won't override if already exported)
os.environ.setdefault("HF_HUB_DISABLE_TELEMETRY", "1")
if os.environ.get("OFFLINE_MODE", ""):
    os.environ.setdefault("HF_HUB_OFFLINE", "1")
    os.environ.setdefault("TRANSFORMERS_OFFLINE", "1")


def _repo_root() -> Path:
    return Path(__file__).resolve().parents[2]


def resolve_embedding_model(model_id: Optional[str] = None) -> str:
    model_id = model_id or DEFAULT_MODEL_ID
    base = os.environ.get("SENTENCE_TRANSFORMERS_HOME", str(_repo_root() / "models"))
    basename = model_id.split("/")[-1]
    local_path = Path(base) / basename

    signature_files = ["config.json", "modules.json", "sentence_bert_config.json"]
    if local_path.is_dir() and any((local_path / f).exists() for f in signature_files):
        return str(local_path)

    offline = bool(os.environ.get("HF_HUB_OFFLINE", "")) or bool(os.environ.get("TRANSFORMERS_OFFLINE", ""))
    if offline:
        raise RuntimeError(
            f"Offline mode is ON, but local embedding model not found at: {local_path}\n"
            "Expected vendored model folder (e.g. copied from offline bundle)."
        )

    return model_id


def get_embedding_function(model_id: Optional[str] = None, device: Optional[str] = None):
    from sentence_transformers import SentenceTransformer

    mid = model_id or DEFAULT_MODEL_ID
    path = resolve_embedding_model(mid)
    # If resolve_embedding_model returned the remote id (string with '/'), SentenceTransformer will handle it
    return SentenceTransformer(path, device=device) if Path(path).exists() else SentenceTransformer(path, device=device)


def safe_snapshot_download(*args, **kwargs):
    if os.environ.get("HF_HUB_OFFLINE", "") or os.environ.get("TRANSFORMERS_OFFLINE", ""):
        raise RuntimeError("Refusing to call snapshot_download while offline.")
    from huggingface_hub import snapshot_download

    return snapshot_download(*args, **kwargs)

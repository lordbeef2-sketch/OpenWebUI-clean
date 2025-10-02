Vendored models directory

This folder is intended to hold vendored model snapshots for offline use by the backend.

To install the `sentence-transformers/all-MiniLM-L6-v2` snapshot from the existing `offline_bundle` (without network access):

1. On a machine with internet, run the downloader scripts in the repo to populate `offline_bundle/hf_models/`.
2. On that same machine, run:

```powershell
python scripts/install_local_model_from_offline_bundle.py
```

This will copy `offline_bundle/hf_models/sentence-transformers_all-MiniLM-L6-v2/` to `models/all-MiniLM-L6-v2/`.

Environment variables to set on the airgapped host before starting the backend:

```powershell
$env:HF_HUB_OFFLINE = "1"
$env:TRANSFORMERS_OFFLINE = "1"
$env:SENTENCE_TRANSFORMERS_HOME = (Resolve-Path -LiteralPath .\models).Path
```

Minimal test (Python) to ensure embeddings load from the local model:

```python
from sentence_transformers import SentenceTransformer
m = SentenceTransformer("./models/all-MiniLM-L6-v2")
emb = m.encode(["hello world"])
assert len(emb) == 1
print('OK')
```

Notes:
- This script will not overwrite an existing `models/all-MiniLM-L6-v2/` folder; remove it first if you need to re-install.
- If the offline snapshot is missing in `offline_bundle`, the script will exit with an error and will not attempt network access.

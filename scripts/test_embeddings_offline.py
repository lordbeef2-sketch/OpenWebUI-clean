import os
os.environ.setdefault("HF_HUB_OFFLINE", "1")
os.environ.setdefault("TRANSFORMERS_OFFLINE", "1")
os.environ.setdefault("SENTENCE_TRANSFORMERS_HOME", "./models")

from backend.open_webui.offline_utils import get_embedding_function

def main():
    try:
        emb = get_embedding_function()
        vec = emb.encode(["hello offline world"])
        print("OK, len:", len(vec))
    except Exception as e:
        print("ERROR:", e)
        raise

if __name__ == '__main__':
    main()

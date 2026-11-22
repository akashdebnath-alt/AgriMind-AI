"""RAG search for the AI adviser.

How it works
  1. Each knowledge-base entry is turned into an "embedding" (a long list of numbers that captures its
     meaning) by Gemini and saved in app/data/kb_index.json. Build it once with:
         python -m app.services.rag          (run from the backend folder)
  2. A farmer's question is embedded the same way and the entries with the closest meaning
     (cosine similarity) are returned.
  3. If embeddings are not available (no key, offline, index not built) it falls back to the old
     keyword search, so the adviser never breaks.

Try a question and see the scores:   python -m app.services.rag "my tomato leaves are curling"
"""
import hashlib
import json
import logging
import math
import sys
import time
from pathlib import Path

import httpx

from app.core.config import settings
from app.services.adviser_knowledge_base import ENTRIES, retrieve as keyword_retrieve

log = logging.getLogger("agrimind.rag")

INDEX_PATH = Path(__file__).resolve().parents[1] / "data" / "kb_index.json"
BASE_URL = "https://generativelanguage.googleapis.com/v1beta/models/{model}:{method}"

_cache: dict = {"mtime": None, "vectors": {}}


# ---------- Gemini embeddings ----------
def _entry_text(entry: dict) -> str:
    return f"{entry['title']}. {entry['text']}"


def _hash(text: str) -> str:
    return hashlib.sha256(text.encode("utf-8")).hexdigest()[:16]


def _post(method: str, bodies: list[dict], timeout: float) -> dict | None:
    """Sends the request. If Gemini rejects the first version (400), tries the next one."""
    key = settings.gemini_api_key.strip()
    if not key:
        return None
    url = BASE_URL.format(model=settings.gemini_embedding_model.strip(), method=method)
    headers = {"x-goog-api-key": key, "Content-Type": "application/json"}
    deadline = time.monotonic() + timeout
    for body in bodies:
        remaining = deadline - time.monotonic()
        if remaining < 0.5:
            return None
        try:
            r = httpx.post(url, headers=headers, json=body, timeout=remaining)
        except httpx.HTTPError as e:
            log.warning("Embedding request failed: %s", type(e).__name__)
            return None
        if r.status_code == 200:
            try:
                return r.json()
            except ValueError:
                return None
        log.warning("Embedding request returned HTTP %s: %s", r.status_code, r.text[:200])
        if r.status_code != 400:
            return None
    return None


def embed_query(text: str, timeout: float = 3.0) -> list[float] | None:
    model = f"models/{settings.gemini_embedding_model.strip()}"
    content = {"parts": [{"text": text}]}
    data = _post("embedContent", [
        {"model": model, "content": content, "taskType": "RETRIEVAL_QUERY"},
        {"model": model, "content": content},
    ], timeout)
    try:
        return [float(x) for x in data["embedding"]["values"]]
    except (TypeError, KeyError, ValueError):
        return None


def embed_documents(texts: list[str], timeout: float = 60.0) -> list[list[float]] | None:
    model = f"models/{settings.gemini_embedding_model.strip()}"
    vectors: list[list[float]] = []
    for start in range(0, len(texts), 50):
        batch = texts[start:start + 50]

        def requests(task: bool) -> dict:
            items = []
            for t in batch:
                item = {"model": model, "content": {"parts": [{"text": t}]}}
                if task:
                    item["taskType"] = "RETRIEVAL_DOCUMENT"
                items.append(item)
            return {"requests": items}

        data = _post("batchEmbedContents", [requests(True), requests(False)], timeout)
        try:
            got = [[float(x) for x in e["values"]] for e in data["embeddings"]]
        except (TypeError, KeyError, ValueError):
            return None
        if len(got) != len(batch):
            return None
        vectors.extend(got)
    return vectors


# ---------- the saved index ----------
def build_index() -> int:
    """Embeds every knowledge-base entry and saves the index. Returns how many entries were indexed."""
    vectors = embed_documents([_entry_text(e) for e in ENTRIES])
    if vectors is None:
        raise RuntimeError("Could not create embeddings. Check GEMINI_API_KEY, the internet and the model name.")
    items = {
        e["id"]: {"hash": _hash(_entry_text(e)), "vector": [round(x, 6) for x in v]}
        for e, v in zip(ENTRIES, vectors)
    }
    INDEX_PATH.parent.mkdir(parents=True, exist_ok=True)
    INDEX_PATH.write_text(
        json.dumps({"model": settings.gemini_embedding_model.strip(), "items": items}), encoding="utf-8"
    )
    _cache["mtime"] = None  # force a reload
    return len(items)


def _load_vectors() -> dict[str, list[float]]:
    """Vectors of the entries whose text has not changed since the index was built."""
    try:
        mtime = INDEX_PATH.stat().st_mtime
    except OSError:
        return {}
    if _cache["mtime"] != mtime:
        vectors: dict[str, list[float]] = {}
        try:
            saved = json.loads(INDEX_PATH.read_text(encoding="utf-8"))
            if saved.get("model") == settings.gemini_embedding_model.strip():
                current = {e["id"]: _hash(_entry_text(e)) for e in ENTRIES}
                for entry_id, item in saved.get("items", {}).items():
                    if current.get(entry_id) == item.get("hash"):
                        vectors[entry_id] = item["vector"]
        except (ValueError, OSError):
            vectors = {}
        _cache.update(mtime=mtime, vectors=vectors)
    return _cache["vectors"]


def _cosine(a: list[float], b: list[float]) -> float:
    if len(a) != len(b):
        return 0.0
    dot = sum(x * y for x, y in zip(a, b))
    na = math.sqrt(sum(x * x for x in a))
    nb = math.sqrt(sum(y * y for y in b))
    return dot / (na * nb) if na and nb else 0.0


# ---------- search ----------
def semantic_scores(query: str, timeout: float = 3.0) -> dict[str, float]:
    """Similarity of the question to every indexed entry (empty if embeddings are unavailable)."""
    vectors = _load_vectors()
    if not vectors:
        return {}
    q = embed_query(query, timeout)
    if q is None:
        return {}
    return {entry_id: _cosine(q, v) for entry_id, v in vectors.items()}


def search(query: str, k: int = 3, timeout: float = 3.0) -> list[dict]:
    """Best knowledge-base entries for the question (each also has a 'score'; None for keyword matches)."""
    query = query.strip()
    by_id = {e["id"]: e for e in ENTRIES}
    scores = semantic_scores(query, timeout)

    ranked = sorted(scores.items(), key=lambda kv: -kv[1])
    hits = [
        dict(by_id[i], score=round(s, 3))
        for i, s in ranked if s >= settings.rag_min_similarity and i in by_id
    ][:k]

    # keyword matches fill any remaining places (and are the whole answer when embeddings are unavailable)
    for entry in keyword_retrieve(query, limit=k):
        if len(hits) >= k:
            break
        if all(h["id"] != entry["id"] for h in hits):
            hits.append(dict(entry, score=None))
    return hits


if __name__ == "__main__":
    if len(sys.argv) > 1:
        question = " ".join(sys.argv[1:])
        all_scores = semantic_scores(question, timeout=10.0)
        if not all_scores:
            print("No semantic scores: the index is missing or the embedding request failed.")
        for entry_id, s in sorted(all_scores.items(), key=lambda kv: -kv[1])[:6]:
            marker = "  <- used" if s >= settings.rag_min_similarity else ""
            print(f"{s:.3f}  {entry_id}{marker}")
        print("minimum similarity to use an entry:", settings.rag_min_similarity)
    else:
        count = build_index()
        print(f"Indexed {count} entries -> {INDEX_PATH}")
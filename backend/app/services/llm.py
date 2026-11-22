"""Asks Google Gemini for an answer.

Returns None if anything goes wrong (no key, no internet, quota used up, ...), so the
caller can fall back to the plain knowledge-base answer and the app never breaks.
"""
import logging
import time

import httpx

from app.core.config import settings

log = logging.getLogger("agrimind.llm")

API_URL = "https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent"


def llm_enabled() -> bool:
    return bool(settings.gemini_api_key.strip())


def ask_gemini(system_prompt: str, user_prompt: str, timeout: float | None = None) -> str | None:
    """`timeout` is the total number of seconds Gemini may take (including the retry)."""
    if not llm_enabled():
        return None

    base_body = {
        "systemInstruction": {"parts": [{"text": system_prompt}]},
        "contents": [{"role": "user", "parts": [{"text": user_prompt}]}],
    }
    # First try with a short "thinking" setting (faster). If Gemini rejects that
    # setting, try again without it.
    attempts = [
        {**base_body, "generationConfig": {"thinkingConfig": {"thinkingLevel": "low"}}},
        base_body,
    ]
    headers = {
        "x-goog-api-key": settings.gemini_api_key.strip(),
        "Content-Type": "application/json",
    }
    url = API_URL.format(model=settings.gemini_model.strip())
    deadline = time.monotonic() + (timeout if timeout is not None else settings.adviser_timeout_seconds)

    for body in attempts:
        remaining = deadline - time.monotonic()
        if remaining < 1.0:
            return None
        try:
            r = httpx.post(url, headers=headers, json=body, timeout=remaining)
        except httpx.HTTPError as e:
            log.warning("Gemini request failed: %s", type(e).__name__)
            return None

        if r.status_code == 200:
            try:
                parts = r.json()["candidates"][0]["content"]["parts"]
                text = "".join(p.get("text", "") for p in parts if not p.get("thought")).strip()
            except (KeyError, IndexError, ValueError, TypeError):
                log.warning("Gemini reply had no usable text")
                return None
            return text or None

        log.warning("Gemini returned HTTP %s: %s", r.status_code, r.text[:300])
        if r.status_code != 400:
            return None  # wrong key, quota, wrong model name... retrying will not help
    return None
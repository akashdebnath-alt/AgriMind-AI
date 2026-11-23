"""Asks Google Gemini for an answer.

If the main model is busy (HTTP 503/429), slow or unavailable, it tries a backup model.
Returns None if everything fails (no key, no internet, quota used up, ...), so the caller
can fall back to the plain knowledge-base answer and the app never breaks.
"""
import logging
import time

import httpx

from app.core.config import settings

log = logging.getLogger("agrimind.llm")

API_URL = "https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent"


def llm_enabled() -> bool:
    return bool(settings.gemini_api_key.strip())


def _try_model(model: str, base_body: dict, headers: dict, deadline: float) -> tuple[str | None, bool]:
    """Asks one model. Returns (answer or None, whether it is worth trying another model)."""
    # First try with a short "thinking" setting (faster). If the model rejects that
    # setting (HTTP 400), try again without it.
    attempts = [
        {**base_body, "generationConfig": {"thinkingConfig": {"thinkingLevel": "low"}}},
        base_body,
    ]
    url = API_URL.format(model=model)
    for body in attempts:
        remaining = deadline - time.monotonic()
        if remaining < 1.0:
            return None, True
        try:
            r = httpx.post(url, headers=headers, json=body, timeout=remaining)
        except httpx.HTTPError as e:
            log.warning("Gemini (%s) request failed: %s", model, type(e).__name__)
            return None, True

        if r.status_code == 200:
            try:
                parts = r.json()["candidates"][0]["content"]["parts"]
                text = "".join(p.get("text", "") for p in parts if not p.get("thought")).strip()
            except (KeyError, IndexError, ValueError, TypeError):
                log.warning("Gemini (%s) reply had no usable text", model)
                return None, True
            return (text or None), not text

        log.warning("Gemini (%s) returned HTTP %s: %s", model, r.status_code, r.text[:300])
        if r.status_code in (401, 403):
            return None, False  # wrong or blocked key: another model will not help
        if r.status_code != 400:
            return None, True  # busy (503), rate limit (429), unknown model (404)...
    return None, True


def ask_gemini(system_prompt: str, user_prompt: str, timeout: float | None = None) -> str | None:
    """`timeout` is the total number of seconds all attempts together may take."""
    if not llm_enabled():
        return None

    base_body = {
        "systemInstruction": {"parts": [{"text": system_prompt}]},
        "contents": [{"role": "user", "parts": [{"text": user_prompt}]}],
    }
    headers = {
        "x-goog-api-key": settings.gemini_api_key.strip(),
        "Content-Type": "application/json",
    }
    started = time.monotonic()
    deadline = started + (timeout if timeout is not None else settings.adviser_timeout_seconds)

    models = [settings.gemini_model.strip()]
    backup = settings.gemini_fallback_model.strip()
    if backup and backup not in models:
        models.append(backup)

    for i, model in enumerate(models):
        is_last = i == len(models) - 1
        # the main model may use at most 60% of the time, so the backup still has a chance
        model_deadline = deadline if is_last else time.monotonic() + (deadline - time.monotonic()) * 0.6
        text, try_next = _try_model(model, base_body, headers, model_deadline)
        if text:
            if i > 0:
                log.warning("Answered by the backup model %s", model)
            return text
        if not try_next:
            return None
    return None
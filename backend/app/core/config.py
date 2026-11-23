from functools import lru_cache

from pydantic_settings import BaseSettings, SettingsConfigDict

DEFAULT_SECRET_KEY = "agrimind-ai-secret-key-32-characters-minimum-production-secure"


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    app_name: str = "AgriMind AI API"
    app_env: str = "development"  # set APP_ENV=production on a real server
    database_url: str = "sqlite:///./agrimind_dev.db"
    secret_key: str = DEFAULT_SECRET_KEY
    access_token_expire_minutes: int = 60 * 24 * 7
    cors_origins: str = "*"
    timezone: str = "Asia/Kolkata"
    weather_timeout_seconds: float = 6.0
    default_et0_mm: float = 4.0  # used only when live weather is unavailable

    gemini_api_key: str = ""
    gemini_model: str = "gemini-3.8-flash"
    gemini_fallback_model: str = "gemini-3.5-flash-lite"
    adviser_timeout_seconds: float = 9.0  # the app gives up after 12 seconds

    gemini_embedding_model: str = "gemini-embedding-001"
    rag_min_similarity: float = 0.6
    adviser_total_seconds: float = 11.0  # the app gives up after 12 seconds

    @property
    def cors_list(self) -> list[str]:
        origins = [o.strip() for o in self.cors_origins.split(",") if o.strip()]
        return ["*"] if "*" in origins or not origins else origins


@lru_cache
def get_settings() -> Settings:
    s = Settings()
    if s.app_env.lower() == "production" and (s.secret_key == DEFAULT_SECRET_KEY or len(s.secret_key) < 32):
        raise RuntimeError(
            "Set a private SECRET_KEY (at least 32 random characters) before running with APP_ENV=production."
        )
    return s


settings = get_settings()
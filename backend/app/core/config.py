from functools import lru_cache

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    app_name: str = "AgriMind AI API"
    database_url: str = "sqlite:///./agrimind_dev.db"
    secret_key: str = "agrimind-ai-secret-key-32-characters-minimum-production-secure"
    access_token_expire_minutes: int = 60 * 24 * 7
    cors_origins: str = "*"
    timezone: str = "Asia/Kolkata"
    weather_timeout_seconds: float = 6.0
    default_et0_mm: float = 4.0  # used only when live weather is unavailable

    gemini_api_key: str = ""
    gemini_model: str = "gemini-3.8-flash"
    adviser_timeout_seconds: float = 9.0  # the app gives up after 12 seconds

    @property
    def cors_list(self) -> list[str]:
        origins = [o.strip() for o in self.cors_origins.split(",") if o.strip()]
        return ["*"] if "*" in origins or not origins else origins


@lru_cache
def get_settings() -> Settings:
    return Settings()


settings = get_settings()

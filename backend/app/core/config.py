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

    @property
    def cors_list(self) -> list[str]:
        return [o.strip() for o in self.cors_origins.split(",") if o.strip()]


@lru_cache
def get_settings() -> Settings:
    return Settings()


settings = get_settings()

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    DATABASE_URL: str = "postgresql+asyncpg://sultan:sultan@localhost:5432/sultan_system"
    REDIS_URL: str = "redis://localhost:6379/0"
    JWT_SECRET: str = "change-me-in-production"
    JWT_ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 720  # 12h — a full shift, not an hour
    TELEGRAM_BOT_TOKEN: str = ""
    # Shared secret the bot sends as X-Bot-Key on every request — the only
    # thing standing between the public internet and client/price/order
    # data, since these endpoints have no per-client login of their own.
    BOT_API_KEY: str = "change-me-in-production"


settings = Settings()

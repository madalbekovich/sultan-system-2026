from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    TELEGRAM_BOT_TOKEN: str
    API_BASE_URL: str = "http://localhost:8000/api/v1"
    BOT_API_KEY: str = ""


settings = Settings()

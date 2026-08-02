"""Runtime configuration. Twelve-factor: everything from env, sane local defaults."""
from functools import lru_cache

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_prefix="CLOUDINTEL_", env_file=".env", extra="ignore")

    environment: str = "local"
    log_level: str = "INFO"

    # Storage
    table_name: str = "cloudintel-main"
    reports_bucket: str = "cloudintel-reports-local"
    aws_region: str = "eu-west-1"

    # Auth (Cognito). When auth_disabled, a dev principal is injected.
    auth_disabled: bool = True
    cognito_user_pool_id: str = ""
    cognito_client_id: str = ""

    # Collector behaviour
    collector_timeout_seconds: float = 15.0
    orchestrator_budget_seconds: float = 25.0
    user_agent: str = "CloudIntel/0.1 (+https://cloudintel.example/bot)"

    # Cache TTL for collector results
    cache_ttl_seconds: int = 3600

    @property
    def is_local(self) -> bool:
        return self.environment == "local"


@lru_cache
def get_settings() -> Settings:
    return Settings()

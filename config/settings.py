"""
config/settings.py
──────────────────
Centralised settings loader using pydantic-settings.
All values are read from environment variables (or .env file).
Usage:
    from config.settings import settings
    print(settings.polygon_api_key)
"""

from functools import lru_cache

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
        extra="ignore",
    )

    # ── Data Source API Keys ──────────────────
    polygon_api_key: str = Field(..., description="Polygon.io API key")
    coingecko_api_key: str = Field("", description="CoinGecko API key (optional for free tier)")
    newsapi_api_key: str = Field(..., description="NewsAPI key")

    # ── OpenAI ───────────────────────────────
    openai_api_key: str = Field(..., description="OpenAI API key for GPT-4o-mini")
    openai_model: str = Field("gpt-4o-mini", description="OpenAI model name")

    # ── Azure ─────────────────────────────────
    azure_subscription_id: str = Field("", description="Azure subscription ID")
    azure_tenant_id: str = Field("", description="Azure tenant ID")
    azure_client_id: str = Field("", description="Service principal client ID")
    azure_client_secret: str = Field("", description="Service principal secret")
    azure_resource_group: str = Field("finsight-rg")

    # ── ADLS Gen2 ────────────────────────────
    adls_account_name: str = Field("finsightadls")
    adls_container_name: str = Field("finsight")
    adls_bronze_path: str = Field("")
    adls_silver_path: str = Field("")
    adls_gold_path: str = Field("")

    # ── Databricks ───────────────────────────
    databricks_host: str = Field("", description="Databricks workspace URL")
    databricks_token: str = Field("", description="Databricks PAT")
    databricks_cluster_id: str = Field("")
    databricks_feature_store_db: str = Field("finsight_features")

    # ── MLflow ───────────────────────────────
    mlflow_tracking_uri: str = Field("databricks")
    mlflow_experiment_name: str = Field("/finsight-ai/experiments")

    # ── FastAPI ──────────────────────────────
    api_host: str = Field("0.0.0.0")
    api_port: int = Field(8000)
    api_env: str = Field("development")

    # ── Local Dev ────────────────────────────
    local_data_path: str = Field("./data/local")
    use_local_spark: bool = Field(True)

    @property
    def is_production(self) -> bool:
        return self.api_env == "production"

    @property
    def bronze_path(self) -> str:
        if self.use_local_spark:
            return f"{self.local_data_path}/bronze"
        return self.adls_bronze_path

    @property
    def silver_path(self) -> str:
        if self.use_local_spark:
            return f"{self.local_data_path}/silver"
        return self.adls_silver_path

    @property
    def gold_path(self) -> str:
        if self.use_local_spark:
            return f"{self.local_data_path}/gold"
        return self.adls_gold_path


@lru_cache
def get_settings() -> Settings:
    """Cached singleton — call this everywhere instead of Settings()."""
    return Settings()


# Convenience alias
settings = get_settings()

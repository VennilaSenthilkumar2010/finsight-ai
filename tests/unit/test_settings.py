"""
tests/unit/test_settings.py
────────────────────────────
Sanity checks for the settings module.
These pass without any API keys by using monkeypatching.
"""

import pytest


def test_settings_loads_with_env(monkeypatch):
    """Settings should load successfully when required env vars are set."""
    monkeypatch.setenv("POLYGON_API_KEY", "test_polygon_key")
    monkeypatch.setenv("NEWSAPI_API_KEY", "test_news_key")
    monkeypatch.setenv("OPENAI_API_KEY", "test_openai_key")

    # Re-import to pick up monkeypatched env
    from importlib import import_module, reload
    import config.settings as settings_module
    reload(settings_module)

    s = settings_module.Settings()
    assert s.polygon_api_key == "test_polygon_key"
    assert s.newsapi_api_key == "test_news_key"
    assert s.openai_api_key == "test_openai_key"


def test_local_spark_paths(monkeypatch):
    """Local Spark mode should return local paths, not ADLS paths."""
    monkeypatch.setenv("POLYGON_API_KEY", "k")
    monkeypatch.setenv("NEWSAPI_API_KEY", "k")
    monkeypatch.setenv("OPENAI_API_KEY", "k")
    monkeypatch.setenv("USE_LOCAL_SPARK", "true")
    monkeypatch.setenv("LOCAL_DATA_PATH", "/tmp/finsight")

    import config.settings as settings_module
    from importlib import reload
    reload(settings_module)

    s = settings_module.Settings()
    assert s.bronze_path == "/tmp/finsight/bronze"
    assert s.silver_path == "/tmp/finsight/silver"
    assert s.gold_path == "/tmp/finsight/gold"


def test_production_flag(monkeypatch):
    """is_production should be True only when API_ENV=production."""
    monkeypatch.setenv("POLYGON_API_KEY", "k")
    monkeypatch.setenv("NEWSAPI_API_KEY", "k")
    monkeypatch.setenv("OPENAI_API_KEY", "k")
    monkeypatch.setenv("API_ENV", "production")

    import config.settings as settings_module
    from importlib import reload
    reload(settings_module)

    s = settings_module.Settings()
    assert s.is_production is True

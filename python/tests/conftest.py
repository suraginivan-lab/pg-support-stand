import os

import pytest

psycopg = pytest.importorskip("psycopg")


@pytest.fixture(scope="session")
def conn():
    """Интеграционные тесты: нужен доступный PostgreSQL (переменные PG*). Иначе тесты пропускаются."""
    if not (os.getenv("PGHOST") or os.getenv("PGDATABASE")):
        pytest.skip("PostgreSQL не настроен (PGHOST/PGDATABASE)")
    try:
        c = psycopg.connect(connect_timeout=3, autocommit=True)
    except psycopg.OperationalError as e:
        pytest.skip(f"PostgreSQL недоступен: {e}")
    yield c
    c.close()

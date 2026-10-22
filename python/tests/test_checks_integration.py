import threading
import time

import psycopg

from pgsupport import checks
from pgsupport.checks import CRITICAL, OK, WARNING


def test_all_checks_run_on_healthy_db(conn):
    results = checks.run_all(conn, expect_replica=False)
    assert {r.name for r in results} >= {"connections", "blocking", "replication"} or len(results) == 5
    assert checks.worst(results) in (OK, WARNING)


def test_replica_expected_but_missing_is_critical(conn):
    if checks._scalar(conn, "SELECT count(*) FROM pg_stat_replication"):
        return  # реплика есть — сценарий неприменим
    assert checks.check_replication_lag(conn, expect_replica=True).status == CRITICAL


def test_blocking_detected(conn):
    """Создаём реальную блокировку двумя сессиями и убеждаемся, что проверка её видит."""
    a = psycopg.connect(autocommit=False)
    a.execute("CREATE TABLE IF NOT EXISTS public.lock_test(id int PRIMARY KEY)")
    a.commit()
    a.execute("LOCK TABLE public.lock_test IN ACCESS EXCLUSIVE MODE")

    def blocked():
        with psycopg.connect(autocommit=True) as b:
            b.execute("SET lock_timeout = '5s'")
            try:
                b.execute("SELECT * FROM public.lock_test")
            except psycopg.errors.LockNotAvailable:
                pass

    t = threading.Thread(target=blocked)
    t.start()
    time.sleep(1)
    try:
        assert checks.check_blocking(conn).status >= WARNING
    finally:
        a.rollback()
        t.join()
        a.execute("DROP TABLE public.lock_test")
        a.commit()
        a.close()

"""Проверки. Чистая логика оценки (evaluate) отделена от запросов к БД, чтобы её можно было тестировать без PostgreSQL."""
from __future__ import annotations

import socket
from dataclasses import dataclass

OK, WARNING, CRITICAL = 0, 1, 2
LABELS = {OK: "OK", WARNING: "WARNING", CRITICAL: "CRITICAL"}


@dataclass(frozen=True)
class Result:
    name: str
    status: int
    detail: str

    @property
    def label(self) -> str:
        return LABELS[self.status]


def evaluate(value: float, warn: float, crit: float) -> int:
    """Статус по порогам: значение >= crit -> CRITICAL, >= warn -> WARNING."""
    if crit < warn:
        raise ValueError("crit не может быть меньше warn")
    if value >= crit:
        return CRITICAL
    if value >= warn:
        return WARNING
    return OK


def worst(results: list[Result]) -> int:
    return max((r.status for r in results), default=OK)


def _scalar(conn, sql: str, params=None):
    with conn.cursor() as cur:
        cur.execute(sql, params)
        return cur.fetchone()[0]


def check_connections(conn, warn: float = 80, crit: float = 95) -> Result:
    pct = float(_scalar(conn, """
        SELECT 100.0 * count(*) / current_setting('max_connections')::int
        FROM pg_stat_activity"""))
    return Result("connections", evaluate(pct, warn, crit), f"{pct:.0f}% от max_connections")


def check_long_transactions(conn, warn_s: int = 300, crit_s: int = 1800) -> Result:
    age = float(_scalar(conn, """
        SELECT coalesce(max(extract(epoch FROM now() - xact_start)), 0)
        FROM pg_stat_activity
        WHERE state <> 'idle' AND pid <> pg_backend_pid() AND xact_start IS NOT NULL"""))
    return Result("long_transactions", evaluate(age, warn_s, crit_s), f"самая долгая транзакция {age:.0f} с")


def check_blocking(conn, warn: int = 1, crit: int = 5) -> Result:
    n = int(_scalar(conn, "SELECT count(*) FROM pg_stat_activity WHERE cardinality(pg_blocking_pids(pid)) > 0"))
    return Result("blocked_sessions", evaluate(n, warn, crit), f"заблокировано сессий: {n}")


def check_dead_tuples(conn, warn: float = 10, crit: float = 30) -> Result:
    pct = float(_scalar(conn, """
        SELECT coalesce(max(100.0 * n_dead_tup / nullif(n_live_tup + n_dead_tup, 0))
                        FILTER (WHERE n_dead_tup > 1000), 0)
        FROM pg_stat_user_tables"""))
    return Result("dead_tuples", evaluate(pct, warn, crit), f"максимум мёртвых строк в таблице: {pct:.1f}%")


def check_replication_lag(conn, expect_replica: bool = True, warn_mb: float = 16, crit_mb: float = 128) -> Result:
    lag = _scalar(conn, """
        SELECT round(max(pg_wal_lsn_diff(pg_current_wal_lsn(), replay_lsn)) / 1048576.0, 1)
        FROM pg_stat_replication""")
    if lag is None:
        return Result("replication", CRITICAL if expect_replica else OK,
                      "реплики не подключены" if expect_replica else "реплики не ожидаются")
    return Result("replication", evaluate(float(lag), warn_mb, crit_mb), f"отставание {lag} МБ")


def check_dns(name: str, expected_ip: str | None = None) -> Result:
    try:
        ip = socket.gethostbyname(name)
    except socket.gaierror as e:
        return Result(f"dns:{name}", CRITICAL, f"не резолвится ({e.strerror})")
    if expected_ip and ip != expected_ip:
        return Result(f"dns:{name}", CRITICAL, f"получили {ip}, ожидали {expected_ip}")
    return Result(f"dns:{name}", OK, ip)


def run_all(conn, expect_replica: bool = False, dns: dict[str, str | None] | None = None) -> list[Result]:
    results = [
        check_connections(conn),
        check_long_transactions(conn),
        check_blocking(conn),
        check_dead_tuples(conn),
        check_replication_lag(conn, expect_replica),
    ]
    results += [check_dns(n, ip) for n, ip in (dns or {}).items()]
    return results

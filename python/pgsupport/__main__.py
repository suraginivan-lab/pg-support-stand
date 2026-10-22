"""CLI:  python -m pgsupport [--format text|json|md] [--replica] [--dns имя[=ip] ...]
Подключение берётся из стандартных переменных libpq (PGHOST, PGUSER, PGPASSWORD, PGDATABASE ...).
Код возврата: 0=OK, 1=WARNING, 2=CRITICAL, 3=ошибка подключения."""
from __future__ import annotations

import argparse
import sys

import psycopg

from .checks import run_all, worst
from .report import FORMATS


def main(argv: list[str] | None = None) -> int:
    p = argparse.ArgumentParser(prog="pgsupport", description=__doc__.splitlines()[0])
    p.add_argument("--format", choices=FORMATS, default="text")
    p.add_argument("--replica", action="store_true", help="реплика ожидается: её отсутствие — CRITICAL")
    p.add_argument("--dns", nargs="*", default=[], metavar="ИМЯ[=IP]", help="проверить резолвинг имён")
    args = p.parse_args(argv)

    dns = {}
    for item in args.dns:
        name, _, ip = item.partition("=")
        dns[name] = ip or None

    try:
        with psycopg.connect(connect_timeout=5, application_name="pgsupport") as conn:
            results = run_all(conn, expect_replica=args.replica, dns=dns)
    except psycopg.OperationalError as e:
        print(f"CRITICAL  connect  {str(e).strip()}", file=sys.stderr)
        return 3

    print(FORMATS[args.format](results))
    return worst(results)


if __name__ == "__main__":
    sys.exit(main())

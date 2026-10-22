# Матрица навыков

Как подтвердить каждый навык: открыть файл, выполнить команду, получить результат.

| Навык | Где в проекте | Как проверить |
|---|---|---|
| **Linux** | `scripts/bash/os_report.sh`, `docker/postgres/postgresql.conf`, раздел «Linux» в [runbook](runbook.md) | `scripts/bash/os_report.sh` — память, диски, inode, порты, `vm.*`, THP, OOM-killer |
| **Bash** | `scripts/bash/*.sh` — общая `lib.sh`, `set -euo pipefail`, коды возврата, ротация, trap-очистка | `shellcheck -x scripts/bash/*.sh`; `make backup && make restore-check` |
| **Git (CI/CD)** | `.github/workflows/ci.yml` | пуш в PR запускает lint и тесты; тег `v1.0.0` публикует образы в GHCR |
| **Docker** | `docker-compose.yml`, `docker/*/Dockerfile`, `replica-entrypoint.sh` | `docker compose up -d --wait`; `docker compose ps` — primary healthy, реплика подключена |
| **PowerShell** | `scripts/powershell/*.ps1` — `Resolve-DnsName`, `Test-NetConnection`, AD-модуль, `SupportsShouldProcess` | `./Sync-PgRolesFromAd.ps1 -WhatIf`; `Invoke-Pester scripts/powershell` |
| **Active Directory** | `docker/ad/entrypoint.sh` (домен, OU, группы), `docker/postgres/pg_hba.conf` (LDAP), `Get-AdHealth.ps1` | `make ad`; вход `psql -h pg-rw.lab.local -U ivanov shop` с доменным паролем |
| **DNS** | `docker/dns/db.lab.local` — A, CNAME, SRV, SOA | `dig @172.28.0.2 pg-rw.lab.local`; `dig @172.28.0.2 _ldap._tcp.lab.local SRV` |
| **SQL** | `sql/init/*` (схема, ограничения, роли, GRANT), `sql/diagnostics/*` (`pg_stat_activity`, `pg_blocking_pids`, `pg_stat_statements`, LATERAL, оконные агрегаты FILTER) | `psql -f sql/diagnostics/02_blocking.sql` во время `make incident-lock` |
| **Python** | `python/pgsupport/` — psycopg 3, argparse, dataclass, чистая логика отдельно от I/O | `pytest -v`; `python -m pgsupport --format json` |

## Что говорить на собеседовании по каждому пункту

- **Бэкап.** «Дамп считается бэкапом только после восстановления» → `restore_check.sh` разворачивает во временную БД, сверяет число строк и проверяет sha256.
- **Репликация.** Слот защищает от потери WAL, но забытый слот забивает диск → запрос `05_replication.sql` показывает удерживаемый WAL.
- **DNS.** Приложения не знают IP: `pg-rw` — CNAME, переключение = смена одной записи + низкий TTL (60 с).
- **AD.** В PostgreSQL нет паролей доменных пользователей — только роли; `Sync-PgRolesFromAd.ps1` создаёт и **отзывает** доступ по членству в группах.
- **CI/CD.** Тесты идут на настоящем PostgreSQL, а не на моках; образы публикуются только после smoke-запуска стенда.

# Стенд сопровождения PostgreSQL

Учебно-практический проект: небольшая инфраструктура вокруг PostgreSQL, на которой отрабатываются задачи
сопровождения БД — развёртывание, репликация, резервное копирование **с проверкой восстановления**, мониторинг,
разбор инцидентов, DNS, интеграция с Active Directory, автоматизация и CI/CD.

Каждый навык подтверждён файлом и командой, которой его можно проверить: [docs/skills-matrix.md](docs/skills-matrix.md).

## Архитектура

```
 docker-сеть 172.28.0.0/24
 ┌────────────────────────────────────────────────────────────────────┐
 │  dns (CoreDNS) 172.28.0.2   зона lab.local, CNAME pg-rw / pg-ro    │
 │  pg-primary    172.28.0.10  PostgreSQL 16, pg_stat_statements      │──WAL──┐
 │  pg-replica    172.28.0.11  streaming replica (слот replica_slot)  │◄──────┘
 │  ad (профиль)  172.28.0.20  Samba AD DC, домен LAB.LOCAL           │
 │  toolbox (профиль)          psql · python · dig · bash-скрипты     │
 └────────────────────────────────────────────────────────────────────┘
 Приложения ходят на pg-rw.lab.local / pg-ro.lab.local. При переключении меняется только CNAME.
 Доменные пользователи входят в PostgreSQL по LDAP (pg_hba.conf, роль-группа ad_users).
```

## Быстрый старт

```bash
cp .env.example .env          # пароли задайте свои
make up                       # dns + primary + replica
make health                   # проверка: БД, соединения, репликация, DNS
make backup                   # дамп + sha256 + ротация
make restore-check FILE=/backups/shop_<дата>.dump
make report                   # отчёт в Markdown (python -m pgsupport)
make ad                       # дополнительно: контроллер домена Samba AD
```

## Структура

| Путь | Что внутри |
|---|---|
| `docker-compose.yml`, `docker/` | сервисы стенда, образы postgres / AD / toolbox, зона DNS |
| `sql/init/` | роли, схема `shop`, 200 тыс. тестовых заказов, права |
| `sql/diagnostics/` | 7 запросов для разбора инцидентов (активность, блокировки, медленные запросы, bloat, репликация, индексы, размеры) |
| `scripts/bash/` | `healthcheck` (Nagios-коды), `backup`, `restore_check`, `maintenance`, `os_report`, `simulate_incident` |
| `scripts/powershell/` | `Check-Stand`, `Get-AdHealth`, `Sync-PgRolesFromAd` (поддерживает `-WhatIf`), Pester-тесты |
| `python/pgsupport/` | CLI-проверки здоровья (text/json/md), тесты pytest |
| `.github/workflows/ci.yml` | lint → тесты на реальном PostgreSQL → smoke-запуск compose → публикация образов по тегу |
| `docs/` | матрица навыков, регламент сопровождения, разбор 5 учебных инцидентов |

## Что проверено, а что нет

Проверено запуском на PostgreSQL 16: все SQL-скрипты, Bash-скрипты (бэкап, проверка восстановления, ловля подмены
контрольной суммы, healthcheck), 14 тестов pytest (включая реальную блокировку двумя сессиями), ruff, shellcheck,
валидность YAML.

**Не запускалось** (в среде разработки не было Docker и PowerShell): `docker compose up`, репликация, контейнер Samba AD,
LDAP-вход, скрипты PowerShell (структура подготовлена, нужен прогон на Windows с RSAT и Pester), CI на GitHub.
Эти части нужно проверить при первом запуске; в CI они покрыты шагами `smoke-compose`, `PSScriptAnalyzer` и `Pester`.

## Ограничения (сознательные)

- LDAP-аутентификация передаёт пароль открытым текстом — для лаборатории; в проде нужен `ldaps` или Kerberos/GSSAPI.
- Пароли в `.env.example` — заглушки. `.env` в git не попадает.
- Реплика асинхронная, автоматического failover нет (это следующий шаг: Patroni).

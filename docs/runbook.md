# Регламент сопровождения

## Ежедневно
1. `make health` — код 0 = OK, 1 = WARNING, 2 = CRITICAL.
2. Убедиться, что ночной `backup.sh` отработал и `sha256` рядом с дампом.

## Еженедельно
1. `restore_check.sh` на последний дамп.
2. `maintenance.sh` — VACUUM ANALYZE для таблиц с долей мёртвых строк ≥ 10 %.
3. `sql/diagnostics/06_indexes.sql` — неиспользуемые индексы и частые seq scan.
4. `Sync-PgRolesFromAd.ps1 -WhatIf` — сверка ролей с группами AD, затем без `-WhatIf`.

## Linux: первые команды при проблеме с хостом
| Симптом | Команда | Что ищем |
|---|---|---|
| Диск | `df -hT; df -i; du -sh $PGDATA/pg_wal` | заполнение, исчерпание inode, разросшийся WAL (забытый слот) |
| Память | `free -m; dmesg \| grep -i oom` | OOM-killer убил postgres |
| Диск (I/O) | `vmstat 1 5; iostat -x 1 5` | высокий `wa`, `await` |
| Сеть | `ss -ltnp \| grep 5432; ss -tan state established '( sport = :5432 )' \| wc -l` | слушает ли, сколько соединений |
| Сервис | `systemctl status postgresql; journalctl -u postgresql -n 100 --no-pager` | причины падения |

Всё сразу: `scripts/bash/os_report.sh`.

## Переключение на реплику (ручное)
1. Убедиться, что primary действительно недоступен и не «мигает».
2. На реплике: `SELECT pg_promote();`
3. Изменить CNAME `pg-rw` на адрес бывшей реплики (TTL 60 с).
4. Старый primary не включать, пока он не пересоздан как реплика (иначе split-brain).

# Учебные инциденты

Запуск: `make incident-lock`, `make incident-slow` или `scripts/bash/simulate_incident.sh <сценарий>`.

## 1. «Приложение зависло» — блокировка
**Симуляция:** `simulate_incident.sh lock`
**Диагностика:** `sql/diagnostics/02_blocking.sql` — видно блокирующий pid и его запрос; `python -m pgsupport` покажет WARNING `blocked_sessions`.
**Решение:** найти владельца транзакции. Крайняя мера — `SELECT pg_terminate_backend(<blocker_pid>);`
**Причина-корень:** транзакция, открытая «на подумать» (`state = idle in transaction`). Профилактика: `idle_in_transaction_session_timeout`.

## 2. Медленный запрос — нет индекса
**Симуляция:** `simulate_incident.sh slow` → в плане `Parallel Seq Scan on orders`.
**Диагностика:** `03_slow_queries.sql`, `06_indexes.sql`.
**Решение:** `CREATE INDEX CONCURRENTLY ON shop.orders (customer_id, created_at DESC);` и повторить `EXPLAIN (ANALYZE, BUFFERS)` — должен быть Index Scan.
**Проверка:** время запроса упало, `seq_scan` по таблице перестал расти.

## 3. «too many connections»
**Симуляция:** `simulate_incident.sh conns 95` — `healthcheck.sh` покажет WARNING/CRITICAL.
**Диагностика:** `07_sizes_connections.sql`, `01_activity.sql` (кто держит соединения).
**Решение:** найти приложение с утечкой, поставить пул (PgBouncer) вместо повышения `max_connections`. У ролей приложений уже `CONNECTION LIMIT 30`.

## 4. Раздувание таблицы (bloat)
**Симуляция:** `simulate_incident.sh bloat` → 50 % мёртвых строк.
**Решение:** `maintenance.sh` (VACUUM ANALYZE). Если место нужно вернуть ОС — `pg_repack`, а не `VACUUM FULL` на проде (эксклюзивная блокировка).

## 5. Реплика отстала / пропала
**Диагностика:** `05_replication.sql` на primary; `pgsupport --replica` даст CRITICAL, если реплики нет вообще.
**Проверить:** DNS (`dig @172.28.0.2 pg-ro.lab.local`), сеть, слот (`active = f` и растущий `retained_wal` — слот копит WAL).

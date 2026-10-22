-- На primary: состояние реплик и отставание.
SELECT application_name, client_addr, state, sync_state,
       pg_wal_lsn_diff(pg_current_wal_lsn(), replay_lsn) AS replay_lag_bytes,
       replay_lag
FROM pg_stat_replication;
-- Слоты: неиспользуемый слот копит WAL и может забить диск.
SELECT slot_name, active,
       pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), restart_lsn)) AS retained_wal
FROM pg_replication_slots;

-- Что сейчас выполняется и как долго. Первым делом при жалобе "всё тормозит".
SELECT pid, usename, application_name, client_addr, state,
       now() - xact_start  AS xact_age,
       now() - query_start AS query_age,
       wait_event_type, wait_event,
       left(query, 120) AS query
FROM pg_stat_activity
WHERE backend_type = 'client backend' AND pid <> pg_backend_pid() AND state <> 'idle'
ORDER BY query_start;

-- Топ запросов по суммарному времени (нужен pg_stat_statements).
SELECT calls,
       round(total_exec_time::numeric, 1) AS total_ms,
       round(mean_exec_time::numeric, 2)  AS mean_ms,
       rows,
       left(regexp_replace(query, '\s+', ' ', 'g'), 100) AS query
FROM pg_stat_statements
WHERE dbid = (SELECT oid FROM pg_database WHERE datname = current_database())
ORDER BY total_exec_time DESC
LIMIT 15;

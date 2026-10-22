SELECT datname, pg_size_pretty(pg_database_size(datname)) AS size
FROM pg_database WHERE NOT datistemplate ORDER BY pg_database_size(datname) DESC;

SELECT count(*) AS used,
       current_setting('max_connections')::int AS max,
       round(100.0 * count(*) / current_setting('max_connections')::int, 1) AS used_pct
FROM pg_stat_activity;

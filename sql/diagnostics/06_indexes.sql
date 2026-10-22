-- Таблицы с частыми seq scan (кандидаты на индекс) ...
SELECT relname, seq_scan, seq_tup_read, idx_scan,
       pg_size_pretty(pg_relation_size(relid)) AS size
FROM pg_stat_user_tables
WHERE seq_scan > 0
ORDER BY seq_tup_read DESC
LIMIT 10;
-- ... и неиспользуемые индексы (кандидаты на удаление).
SELECT s.relname AS tbl, s.indexrelname AS idx, s.idx_scan,
       pg_size_pretty(pg_relation_size(s.indexrelid)) AS size
FROM pg_stat_user_indexes s
JOIN pg_index i USING (indexrelid)
WHERE s.idx_scan = 0 AND NOT i.indisunique AND NOT i.indisprimary
ORDER BY pg_relation_size(s.indexrelid) DESC;

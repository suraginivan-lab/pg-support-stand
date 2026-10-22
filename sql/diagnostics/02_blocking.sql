-- Кто кого блокирует (дерево блокировок).
SELECT blocked.pid                    AS blocked_pid,
       blocked.usename                AS blocked_user,
       now() - blocked.query_start    AS waiting_for,
       left(blocked.query, 80)        AS blocked_query,
       blocker.pid                    AS blocker_pid,
       blocker.usename                AS blocker_user,
       blocker.state                  AS blocker_state,
       left(blocker.query, 80)        AS blocker_query
FROM pg_stat_activity blocked
JOIN LATERAL unnest(pg_blocking_pids(blocked.pid)) AS b(pid) ON true
JOIN pg_stat_activity blocker ON blocker.pid = b.pid
ORDER BY waiting_for DESC;

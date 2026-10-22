#!/usr/bin/env bash
# Проверка стенда в формате Nagios: 0=OK, 1=WARNING, 2=CRITICAL.
# Переменные: PGHOST, REPLICA_HOST (необязательно), DNS_NAMES, LAG_WARN_MB, LAG_CRIT_MB, CONN_WARN_PCT
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
require pg_isready psql

LAG_WARN_MB="${LAG_WARN_MB:-16}"; LAG_CRIT_MB="${LAG_CRIT_MB:-128}"; CONN_WARN_PCT="${CONN_WARN_PCT:-80}"
status=0
bump() { (( $1 > status )) && status=$1; return 0; }
report() { printf '%-9s %-22s %s\n' "$1" "$2" "$3"; }

# 1. доступность primary
if pg_isready -q -h "$PGHOST" -p "$PGPORT"; then
  report OK "primary" "$PGHOST:$PGPORT принимает соединения"
else
  report CRITICAL "primary" "$PGHOST:$PGPORT недоступен"; exit 2
fi

# 2. использование соединений
pct=$(q -c "SELECT round(100.0*count(*)/current_setting('max_connections')::int)::int FROM pg_stat_activity")
if   (( pct >= 95 )); then report CRITICAL "connections" "${pct}% от max_connections"; bump 2
elif (( pct >= CONN_WARN_PCT )); then report WARNING "connections" "${pct}% от max_connections"; bump 1
else report OK "connections" "${pct}%"; fi

# 3. долгие транзакции (> 5 минут)
long=$(q -c "SELECT count(*) FROM pg_stat_activity WHERE state <> 'idle' AND xact_start < now() - interval '5 min'")
if (( long > 0 )); then report WARNING "long_transactions" "$long шт. старше 5 минут"; bump 1
else report OK "long_transactions" "нет"; fi

# 4. отставание реплики
lag=$(q -c "SELECT coalesce(round(max(pg_wal_lsn_diff(pg_current_wal_lsn(), replay_lsn))/1048576.0), -1) FROM pg_stat_replication")
if (( $(printf '%.0f' "$lag") < 0 )); then
  if [ -n "${REPLICA_HOST:-}" ]; then report CRITICAL "replication" "реплик не подключено"; bump 2
  else report OK "replication" "реплики не ожидаются"; fi
elif (( $(printf '%.0f' "$lag") >= LAG_CRIT_MB )); then report CRITICAL "replication" "lag ${lag} MB"; bump 2
elif (( $(printf '%.0f' "$lag") >= LAG_WARN_MB )); then report WARNING "replication" "lag ${lag} MB"; bump 1
else report OK "replication" "lag ${lag} MB"; fi

# 5. DNS-имена (если заданы): DNS_NAMES="pg-rw.lab.local pg-ro.lab.local"
for name in ${DNS_NAMES:-}; do
  if ip=$(getent hosts "$name" | awk '{print $1; exit}') && [ -n "$ip" ]; then report OK "dns:$name" "$ip"
  else report CRITICAL "dns:$name" "не резолвится"; bump 2; fi
done

exit "$status"

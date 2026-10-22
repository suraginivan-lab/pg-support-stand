#!/usr/bin/env bash
# Плановое обслуживание: VACUUM (ANALYZE) для таблиц с долей мёртвых строк выше порога.
# Использование: maintenance.sh [порог_%]  (по умолчанию 10)
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
require psql
threshold="${1:-10}"

mapfile -t tables < <(q -c "
  SELECT format('%I.%I', schemaname, relname)
  FROM pg_stat_user_tables
  WHERE n_dead_tup > 1000
    AND 100.0 * n_dead_tup / NULLIF(n_live_tup + n_dead_tup, 0) >= $threshold")

if (( ${#tables[@]} == 0 )); then info "обслуживание не требуется"; exit 0; fi
for t in "${tables[@]}"; do
  info "VACUUM (ANALYZE) $t"
  q -c "VACUUM (ANALYZE) $t"
done

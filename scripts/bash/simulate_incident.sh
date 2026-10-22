#!/usr/bin/env bash
# Генератор учебных инцидентов. Разбор — в docs/incidents.md.
#   lock   — сессия держит блокировку, вторая ждёт
#   slow   — тяжёлый запрос без индекса
#   conns  — исчерпание соединений
#   bloat  — массовый UPDATE -> мёртвые строки
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
require psql
case "${1:-}" in
  lock)
    info "сессия A: BEGIN + UPDATE и ожидание 60 с (в фоне)"
    psql -X -q -c "BEGIN; UPDATE shop.orders SET status='paid' WHERE order_id=1; SELECT pg_sleep(60); COMMIT;" &
    sleep 1
    info "сессия B: тот же UPDATE — повиснет. Смотрите sql/diagnostics/02_blocking.sql"
    psql -X -q -c "UPDATE shop.orders SET status='shipped' WHERE order_id=1;" &
    wait ;;
  slow)
    info "запрос без индекса по orders(customer_id)"
    psql -X -q -c "SELECT count(*), sum(amount) FROM shop.orders WHERE customer_id = 4242;"
    psql -X -q -c "EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM shop.orders WHERE customer_id = 4242 ORDER BY created_at DESC LIMIT 20;" ;;
  conns)
    n="${2:-95}"; info "открываю $n соединений на 30 с"
    for _ in $(seq "$n"); do psql -X -q -c "SELECT pg_sleep(30)" >/dev/null 2>&1 & done
    sleep 2; "$(dirname "${BASH_SOURCE[0]}")/healthcheck.sh" || true; wait ;;
  bloat)
    info "UPDATE всех строк orders -> мёртвые версии"
    psql -X -q -c "UPDATE shop.orders SET amount = amount + 0;"
    psql -X -q -f "$(dirname "${BASH_SOURCE[0]}")/../../sql/diagnostics/04_vacuum_bloat.sql" ;;
  *) die "использование: $0 lock|slow|conns [N]|bloat" ;;
esac

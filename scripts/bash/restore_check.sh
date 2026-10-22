#!/usr/bin/env bash
# Бэкап, который не проверяли восстановлением, бэкапом не считается.
# Разворачивает дамп во временную БД, сверяет число строк с боевой БД и удаляет её.
# Использование: restore_check.sh <файл.dump>
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
require pg_restore createdb dropdb sha256sum

file="${1:?укажите файл дампа}"; [ -f "$file" ] || die "нет файла: $file"
if [ -f "$file.sha256" ]; then ( cd "$(dirname "$file")" && sha256sum -c "$(basename "$file").sha256" >&2 ) || die "контрольная сумма не совпала"; fi

tmpdb="restore_check_$$"
trap 'dropdb --if-exists "$tmpdb" 2>/dev/null || true' EXIT
createdb "$tmpdb"
pg_restore --no-owner --no-privileges -d "$tmpdb" "$file" 2>&1 | grep -v 'already exists' >&2 || true

fail=0
for t in shop.customers shop.orders; do
  want=$(q -d "$PGDATABASE" -c "SELECT count(*) FROM $t")
  got=$(q -d "$tmpdb" -c "SELECT count(*) FROM $t")
  if [ "$want" = "$got" ]; then info "OK   $t: $got строк"; else warn "FAIL $t: в бэкапе $got, в базе $want"; fail=1; fi
done
(( fail == 0 )) && info "восстановление проверено" || die "данные в бэкапе отличаются от базы (если база менялась после бэкапа — это ожидаемо)"

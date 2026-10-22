#!/usr/bin/env bash
# Логический бэкап в custom-формате + контрольная сумма + проверка читаемости + ротация.
# Использование: backup.sh [каталог]   Переменные: BACKUP_DIR, RETENTION_DAYS (по умолчанию 7)
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
require pg_dump pg_restore sha256sum

dir="${1:-${BACKUP_DIR:-./backups}}"; keep="${RETENTION_DAYS:-7}"
mkdir -p "$dir"
file="$dir/${PGDATABASE}_$(date +%Y%m%d_%H%M%S).dump"

info "pg_dump $PGDATABASE -> $file"
pg_dump -Fc --no-password -f "$file.part" "$PGDATABASE"
mv "$file.part" "$file"

# проверка: архив читается и содержит оглавление
pg_restore --list "$file" >/dev/null || die "архив повреждён: $file"
( cd "$dir" && sha256sum "$(basename "$file")" > "$(basename "$file").sha256" )
info "OK: $(du -h "$file" | cut -f1), sha256 записан"

# ротация
removed=$(find "$dir" -maxdepth 1 -name "${PGDATABASE}_*.dump*" -mtime +"$keep" -print -delete | wc -l)
info "удалено старых файлов: $removed (хранение ${keep} дн.)"
echo "$file"

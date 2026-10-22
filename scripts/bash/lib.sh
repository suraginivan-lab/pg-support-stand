#!/usr/bin/env bash
# Общие функции. Подключается через: source "$(dirname "$0")/lib.sh"
set -euo pipefail

: "${PGHOST:=localhost}" "${PGPORT:=5432}" "${PGUSER:=postgres}" "${PGDATABASE:=shop}"
export PGHOST PGPORT PGUSER PGDATABASE

log()  { printf '%s [%s] %s\n' "$(date '+%F %T')" "${1}" "${*:2}" >&2; }
info() { log INFO "$@"; }
warn() { log WARN "$@"; }
die()  { log ERROR "$@"; exit 1; }

require() { for c in "$@"; do command -v "$c" >/dev/null 2>&1 || die "не найдена команда: $c"; done; }

# psql в «тихом» режиме для скриптов: без заголовков и выравнивания
q() { psql -X -qAt -v ON_ERROR_STOP=1 "$@"; }

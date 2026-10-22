#!/usr/bin/env bash
# Поднимает streaming-реплику: при пустом PGDATA делает pg_basebackup с primary.
set -euo pipefail
PGDATA="${PGDATA:-/var/lib/postgresql/data}"

if [ ! -s "$PGDATA/PG_VERSION" ]; then
  echo "[replica] PGDATA пуст, снимаю базовую копию с ${PRIMARY_HOST}"
  rm -rf "${PGDATA:?}"/* 
  PGPASSWORD="$REPLICATOR_PASSWORD" gosu postgres pg_basebackup \
    -h "$PRIMARY_HOST" -U replicator -D "$PGDATA" -X stream -R -S replica_slot -C -P
  chmod 700 "$PGDATA"
  chown -R postgres:postgres "$PGDATA"
fi

exec gosu postgres postgres -c config_file=/etc/postgresql/postgresql.conf \
                            -c hba_file=/etc/postgresql/pg_hba.conf

#!/usr/bin/env bash
# Роли стенда. Запускается один раз при инициализации primary (docker-entrypoint-initdb.d).
set -euo pipefail
psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" \
  -v app_rw="$APP_RW_PASSWORD" -v app_ro="$APP_RO_PASSWORD" -v repl="$REPLICATOR_PASSWORD" <<'SQL'
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

CREATE ROLE ad_users NOLOGIN;                 -- группа: члены проверяются в AD по LDAP
CREATE ROLE support_dba NOLOGIN IN ROLE pg_monitor, ad_users;
CREATE ROLE support_ro  NOLOGIN IN ROLE ad_users;

CREATE ROLE app_rw LOGIN PASSWORD :'app_rw' CONNECTION LIMIT 30;
CREATE ROLE app_ro LOGIN PASSWORD :'app_ro' CONNECTION LIMIT 30;
CREATE ROLE replicator LOGIN REPLICATION PASSWORD :'repl';
SQL

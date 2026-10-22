ARG PG_VERSION=16
FROM postgres:${PG_VERSION}
COPY postgresql.conf /etc/postgresql/postgresql.conf
COPY pg_hba.conf /etc/postgresql/pg_hba.conf
COPY replica-entrypoint.sh /usr/local/bin/replica-entrypoint.sh
RUN chmod +x /usr/local/bin/replica-entrypoint.sh
CMD ["postgres", "-c", "config_file=/etc/postgresql/postgresql.conf", "-c", "hba_file=/etc/postgresql/pg_hba.conf"]

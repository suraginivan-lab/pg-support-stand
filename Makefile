.PHONY: up down reset ps health backup restore-check test lint report psql incident-lock incident-slow

up:            ## поднять dns + primary + replica
	cp -n .env.example .env || true
	docker compose up -d --build --wait
ad:            ## то же + контроллер домена
	docker compose --profile ad up -d --build
down:
	docker compose --profile ad --profile tools down
reset:         ## всё удалить вместе с данными
	docker compose --profile ad --profile tools down -v
ps:
	docker compose ps
health:
	docker compose --profile tools run --rm -e DNS_NAMES="pg-rw.lab.local pg-ro.lab.local" -e REPLICA_HOST=pg-replica toolbox bash scripts/bash/healthcheck.sh
backup:
	docker compose --profile tools run --rm toolbox bash scripts/bash/backup.sh /backups
restore-check:  ## make restore-check FILE=/backups/shop_....dump
	docker compose --profile tools run --rm toolbox bash scripts/bash/restore_check.sh $(FILE)
report:
	docker compose --profile tools run --rm toolbox python -m pgsupport --format md --replica --dns pg-rw.lab.local pg-ro.lab.local
psql:
	docker compose exec pg-primary psql -U postgres shop
incident-lock:
	docker compose --profile tools run --rm toolbox bash scripts/bash/simulate_incident.sh lock
incident-slow:
	docker compose --profile tools run --rm toolbox bash scripts/bash/simulate_incident.sh slow
test:           ## локально, нужен PostgreSQL (PG* переменные)
	pytest -v
lint:
	ruff check python && shellcheck -x scripts/bash/*.sh

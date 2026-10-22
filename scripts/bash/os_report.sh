#!/usr/bin/env bash
# Снимок состояния Linux-хоста для разбора инцидентов с БД: ресурсы, диски, сеть, ядро.
# Использование: os_report.sh [PGDATA]
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
pgdata="${1:-${PGDATA:-/var/lib/postgresql/data}}"
sec() { printf '\n== %s ==\n' "$*"; }

sec "Хост";        hostname; uname -sr; uptime
sec "Память";      free -m
sec "Нагрузка CPU/IO"; (command -v vmstat >/dev/null && vmstat 1 3) || cat /proc/loadavg
sec "Диски";       df -hT -x tmpfs -x devtmpfs 2>/dev/null
sec "Inode";       df -i "$pgdata" 2>/dev/null || df -i /
sec "Размер PGDATA"; du -sh "$pgdata" 2>/dev/null || echo "нет доступа к $pgdata"
sec "Слушающие порты"; (ss -ltnp 2>/dev/null || ss -ltn) | grep -E ':(5432|53|389|88)\b' || echo "5432/53/389/88 не слушаются"
sec "Топ процессов по памяти"; ps -eo pid,user,%mem,rss,etime,cmd --sort=-%mem | head -6
sec "Параметры ядра, важные для PostgreSQL"
for k in vm.swappiness vm.overcommit_memory vm.dirty_background_ratio vm.dirty_ratio; do printf '%-28s %s\n' "$k" "$(sysctl -n "$k" 2>/dev/null || echo n/a)"; done
printf '%-28s %s\n' "transparent_hugepage" "$(cat /sys/kernel/mm/transparent_hugepage/enabled 2>/dev/null || echo n/a)"
sec "OOM-killer в журнале ядра"; (dmesg 2>/dev/null | grep -iE 'out of memory|oom-kill' | tail -3) || true; echo "(проверено)"

#!/usr/bin/env bash
# Создаёт домен LAB.LOCAL при первом запуске и наполняет его тестовыми пользователями/группами.
set -euo pipefail
: "${AD_ADMIN_PASSWORD:?}" "${AD_REALM:=LAB.LOCAL}" "${AD_DOMAIN:=LAB}"

if [ ! -f /var/lib/samba/private/sam.ldb ]; then
  rm -f /etc/samba/smb.conf
  samba-tool domain provision --use-rfc2307 --realm="$AD_REALM" --domain="$AD_DOMAIN" \
     --server-role=dc --dns-backend=SAMBA_INTERNAL --adminpass="$AD_ADMIN_PASSWORD" \
     --option="dns forwarder=172.28.0.2"
  cp /var/lib/samba/private/krb5.conf /etc/krb5.conf

  # Тестовая структура: OU, группы PostgreSQL и два пользователя
  samba-tool ou create "OU=Support,DC=lab,DC=local"
  samba-tool group add pg_dba
  samba-tool group add pg_readonly
  samba-tool user create ivanov  'Passw0rd_Ivanov!'  --given-name=Ivan --surname=Ivanov --userou="OU=Support"
  samba-tool user create petrova 'Passw0rd_Petrova!' --given-name=Anna --surname=Petrova --userou="OU=Support"
  samba-tool group addmembers pg_dba ivanov
  samba-tool group addmembers pg_readonly petrova
fi

exec samba -i

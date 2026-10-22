FROM ubuntu:24.04
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
      samba samba-dsdb-modules samba-vfs-modules winbind krb5-user krb5-config \
      ldap-utils dnsutils acl attr tini ca-certificates \
    && rm -rf /var/lib/apt/lists/*
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
EXPOSE 53/tcp 53/udp 88/tcp 88/udp 389/tcp 389/udp 445/tcp 636/tcp
ENTRYPOINT ["/usr/bin/tini", "--", "/entrypoint.sh"]

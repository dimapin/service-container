FROM debian:bookworm-slim

ENV MARIADB_VERSION=10.11 \
    MARIADB_ROOT_PASSWORD="" \
    MARIADB_ROOT_USER=root \
    MARIADB_USER="" \
    MARIADB_PASSWORD="" \
    MARIADB_DATABASE="" \
    MARIADB_ALLOW_EMPTY_PASSWORD=no \
    MARIADB_RANDOM_ROOT_PASSWORD=no \
    MARIADB_CHARACTER_SET=utf8mb4 \
    MARIADB_COLLATE=utf8mb4_general_ci \
    MARIADB_BIND_ADDRESS=0.0.0.0 \
    MARIADB_PORT_NUMBER=3306

RUN apt-get update && apt-get install -y \
    wget \
    gnupg \
    ca-certificates \
    gosu \
    pwgen \
    && rm -rf /var/lib/apt/lists/*

RUN wget https://mariadb.org/mariadb_release_signing_key.asc -O /etc/apt/trusted.gpg.d/mariadb.asc && \
    echo "deb https://mirror.mariadb.org/repo/10.11/debian bookworm main" > /etc/apt/sources.list.d/mariadb.list && \
    apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y mariadb-server && \
    rm -rf /var/lib/apt/lists/*

RUN groupadd -r mariadb --gid=999 || true && \
    useradd -r -g mariadb --uid=999 --home-dir=/opt/mariadb --shell=/bin/false mariadb || true && \
    mkdir -p /opt/mariadb/data && \
    mkdir -p /opt/mariadb/conf && \
    mkdir -p /opt/mariadb/logs && \
    mkdir -p /opt/mariadb/tmp && \
    chown -R mariadb:mariadb /opt/mariadb

WORKDIR /opt/mariadb

COPY mariadb-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/mariadb-entrypoint.sh

EXPOSE 3306
VOLUME ["/opt/mariadb/data"]

HEALTHCHECK --interval=30s --timeout=10s --start-period=20s --retries=3 \
  CMD mariadb-admin ping -h 127.0.0.1 --silent || exit 1

ENTRYPOINT ["mariadb-entrypoint.sh"]
CMD ["mysqld"]


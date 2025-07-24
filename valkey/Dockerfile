FROM debian:bookworm-slim

ENV VALKEY_VERSION=7.2.5 \
    VALKEY_PASSWORD="" \
    VALKEY_PORT_NUMBER=6379 \
    VALKEY_DATABASES=16 \
    VALKEY_AOF_ENABLED=yes \
    VALKEY_RDB_POLICY_DISABLED=no

RUN apt-get update && apt-get install -y \
    wget \
    build-essential \
    ca-certificates \
    gosu \
    gettext-base \
    && rm -rf /var/lib/apt/lists/*

RUN wget https://github.com/valkey-io/valkey/archive/refs/tags/${VALKEY_VERSION}.tar.gz && \
    tar xzf ${VALKEY_VERSION}.tar.gz && \
    cd valkey-${VALKEY_VERSION} && \
    make && \
    make install && \
    cd .. && \
    rm -rf valkey-${VALKEY_VERSION}* && \
    apt-get purge -y build-essential && \
    apt-get autoremove -y

RUN groupadd -r valkey --gid=1001 && \
    useradd -r -g valkey --uid=1001 --home-dir=/opt/valkey valkey && \
    mkdir -p /opt/valkey/{data,conf,logs} && \
    chown -R valkey:valkey /opt/valkey

WORKDIR /opt/valkey

COPY valkey.conf.template /opt/valkey/conf/
COPY valkey-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/valkey-entrypoint.sh

EXPOSE 6379
VOLUME ["/opt/valkey/data"]

ENTRYPOINT ["valkey-entrypoint.sh"]
CMD ["valkey-server", "/opt/valkey/conf/valkey.conf"]


FROM debian:bookworm-slim

ENV VALKEY_VERSION=7.2.5 \
    VALKEY_SENTINEL_PORT_NUMBER=26379 \
    VALKEY_MASTER_NAME=mymaster \
    VALKEY_MASTER_HOST=valkey \
    VALKEY_MASTER_PORT_NUMBER=6379 \
    VALKEY_SENTINEL_QUORUM=2

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
    useradd -r -g valkey --uid=1001 --home-dir=/opt/valkey-sentinel valkey && \
    mkdir -p /opt/valkey-sentinel/{conf,logs} && \
    chown -R valkey:valkey /opt/valkey-sentinel

WORKDIR /opt/valkey-sentinel

COPY valkey-sentinel.conf.template /opt/valkey-sentinel/conf/
COPY valkey-sentinel-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/valkey-sentinel-entrypoint.sh

EXPOSE 26379
ENTRYPOINT ["valkey-sentinel-entrypoint.sh"]
CMD ["valkey-sentinel", "/opt/valkey-sentinel/conf/sentinel.conf"]


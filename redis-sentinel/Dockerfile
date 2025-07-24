FROM debian:bullseye-slim

ENV REDIS_VERSION=7.2.3 \
    REDIS_SENTINEL_PORT_NUMBER=26379 \
    REDIS_MASTER_NAME=mymaster \
    REDIS_MASTER_HOST=redis \
    REDIS_MASTER_PORT_NUMBER=6379 \
    REDIS_SENTINEL_QUORUM=2 \
    REDIS_SENTINEL_DOWN_AFTER_MILLISECONDS=5000 \
    REDIS_SENTINEL_FAILOVER_TIMEOUT=10000

RUN apt-get update && apt-get install -y \
    wget \
    build-essential \
    ca-certificates \
    gosu \
    gettext-base \
    && rm -rf /var/lib/apt/lists/*

RUN wget http://download.redis.io/releases/redis-${REDIS_VERSION}.tar.gz && \
    tar xzf redis-${REDIS_VERSION}.tar.gz && \
    cd redis-${REDIS_VERSION} && \
    make && \
    make install && \
    cd .. && \
    rm -rf redis-${REDIS_VERSION}* && \
    apt-get purge -y build-essential && \
    apt-get autoremove -y

RUN groupadd -r redis --gid=1001 && \
    useradd -r -g redis --uid=1001 --home-dir=/opt/redis-sentinel redis && \
    mkdir -p /opt/redis-sentinel/{conf,logs} && \
    chown -R redis:redis /opt/redis-sentinel

WORKDIR /opt/redis-sentinel

COPY sentinel.conf.template /opt/redis-sentinel/conf/
COPY redis-sentinel-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/redis-sentinel-entrypoint.sh

EXPOSE 26379
VOLUME ["/opt/redis-sentinel/conf"]

ENTRYPOINT ["redis-sentinel-entrypoint.sh"]
CMD ["redis-sentinel", "/opt/redis-sentinel/conf/sentinel.conf"]


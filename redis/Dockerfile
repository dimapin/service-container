FROM debian:bookworm-slim

ENV REDIS_VERSION=7.2.3 \
    REDIS_PASSWORD="" \
    REDIS_PORT_NUMBER=6379 \
    REDIS_DATABASES=16 \
    REDIS_AOF_ENABLED=yes \
    REDIS_RDB_POLICY_DISABLED=no \
    REDIS_MASTER_HOST="" \
    REDIS_MASTER_PORT_NUMBER=6379 \
    REDIS_MASTER_PASSWORD="" \
    REDIS_REPLICA_ANNOUNCE_IP="" \
    REDIS_REPLICA_ANNOUNCE_PORT=""

RUN apt-get update && apt-get install -y \
    wget \
    build-essential \
    ca-certificates \
    gosu \
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
    useradd -r -g redis --uid=1001 --home-dir=/opt/redis redis && \
    mkdir -p /opt/redis/{data,conf,logs} && \
    chown -R redis:redis /opt/redis

WORKDIR /opt/redis

COPY redis.conf.template /opt/redis/conf/
COPY redis-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/redis-entrypoint.sh

EXPOSE 6379
VOLUME ["/opt/redis/data"]

ENTRYPOINT ["redis-entrypoint.sh"]
CMD ["redis-server", "/opt/redis/conf/redis.conf"]


#!/bin/bash
set -e

if [ "$(id -u)" = '0' ]; then
    exec gosu redis "$0" "$@"
fi

# Generate Redis configuration
envsubst < /opt/redis/conf/redis.conf.template > /opt/redis/conf/redis.conf

# Set up replication if specified
if [ -n "$REDIS_MASTER_HOST" ]; then
    echo "replicaof $REDIS_MASTER_HOST $REDIS_MASTER_PORT_NUMBER" >> /opt/redis/conf/redis.conf
    if [ -n "$REDIS_MASTER_PASSWORD" ]; then
        echo "masterauth $REDIS_MASTER_PASSWORD" >> /opt/redis/conf/redis.conf
    fi
fi

exec "$@"


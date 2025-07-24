#!/bin/bash
set -e

if [ "$(id -u)" = '0' ]; then
    exec gosu redis "$0" "$@"
fi

# Generate Sentinel configuration
envsubst < /opt/redis-sentinel/conf/sentinel.conf.template > /opt/redis-sentinel/conf/sentinel.conf

exec "$@"

# redis-sentinel/sentinel.conf.template
port ${REDIS_SENTINEL_PORT_NUMBER}
dir /opt/redis-sentinel
logfile /opt/redis-sentinel/logs/sentinel.log

sentinel monitor ${REDIS_MASTER_NAME} ${REDIS_MASTER_HOST} ${REDIS_MASTER_PORT_NUMBER} ${REDIS_SENTINEL_QUORUM}
sentinel down-after-milliseconds ${REDIS_MASTER_NAME} ${REDIS_SENTINEL_DOWN_AFTER_MILLISECONDS}
sentinel failover-timeout ${REDIS_MASTER_NAME} ${REDIS_SENTINEL_FAILOVER_TIMEOUT}


#!/bin/bash
set -e

if [ "$(id -u)" = '0' ]; then
    exec gosu valkey "$0" "$@"
fi

envsubst < /opt/valkey-sentinel/conf/valkey-sentinel.conf.template > /opt/valkey-sentinel/conf/sentinel.conf

exec "$@"

# valkey-sentinel/valkey-sentinel.conf.template
port ${VALKEY_SENTINEL_PORT_NUMBER}
dir /opt/valkey-sentinel
logfile /opt/valkey-sentinel/logs/sentinel.log

sentinel monitor ${VALKEY_MASTER_NAME} ${VALKEY_MASTER_HOST} ${VALKEY_MASTER_PORT_NUMBER} ${VALKEY_SENTINEL_QUORUM}


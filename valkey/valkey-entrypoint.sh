#!/bin/bash
set -e

if [ "$(id -u)" = '0' ]; then
    exec gosu valkey "$0" "$@"
fi

# Generate Valkey configuration
envsubst < /opt/valkey/conf/valkey.conf.template > /opt/valkey/conf/valkey.conf

exec "$@"

# valkey/valkey.conf.template
port ${VALKEY_PORT_NUMBER}
bind 0.0.0.0
dir /opt/valkey/data
logfile /opt/valkey/logs/valkey.log
databases ${VALKEY_DATABASES}

$([ -n "$VALKEY_PASSWORD" ] && echo "requirepass $VALKEY_PASSWORD")

save 900 1
save 300 10
save 60 10000
dbfilename dump.rdb

appendonly ${VALKEY_AOF_ENABLED}
appendfilename "appendonly.aof"
appendfsync everysec


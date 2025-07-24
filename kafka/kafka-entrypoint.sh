#!/bin/bash
set -e

if [ "$(id -u)" = '0' ]; then
    exec gosu kafka "$0" "$@"
fi

# Generate server.properties
cat > /opt/kafka/config/server.properties << EOF
broker.id=${KAFKA_BROKER_ID}
listeners=${KAFKA_LISTENERS}
advertised.listeners=${KAFKA_ADVERTISED_LISTENERS}
num.network.threads=${KAFKA_NUM_NETWORK_THREADS}
num.io.threads=${KAFKA_NUM_IO_THREADS}
socket.send.buffer.bytes=${KAFKA_SOCKET_SEND_BUFFER_BYTES}
socket.receive.buffer.bytes=${KAFKA_SOCKET_RECEIVE_BUFFER_BYTES}
socket.request.max.bytes=${KAFKA_SOCKET_REQUEST_MAX_BYTES}
log.dirs=${KAFKA_LOG_DIRS}
num.partitions=1
default.replication.factor=1
offsets.topic.replication.factor=1
transaction.state.log.replication.factor=1
transaction.state.log.min.isr=1
log.retention.hours=${KAFKA_LOG_RETENTION_HOURS}
log.segment.bytes=${KAFKA_LOG_SEGMENT_BYTES}
log.retention.check.interval.ms=${KAFKA_LOG_RETENTION_CHECK_INTERVAL_MS}
zookeeper.connect=${KAFKA_ZOOKEEPER_CONNECT}
zookeeper.connection.timeout.ms=18000
group.initial.rebalance.delay.ms=0
EOF

# Wait for Zookeeper if needed
if [ "${KAFKA_ZOOKEEPER_CONNECT}" != "localhost:2181" ]; then
    echo "Waiting for Zookeeper at ${KAFKA_ZOOKEEPER_CONNECT}..."
    while ! nc -z ${KAFKA_ZOOKEEPER_CONNECT/:/ }; do
        sleep 1
    done
fi

exec "$@"


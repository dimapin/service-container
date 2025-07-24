FROM debian:bullseye-slim

ENV KAFKA_VERSION=2.8.2 \
    SCALA_VERSION=2.13 \
    KAFKA_HOME=/opt/kafka \
    KAFKA_USER=kafka \
    KAFKA_BROKER_ID=1 \
    KAFKA_ZOOKEEPER_CONNECT=localhost:2181 \
    KAFKA_LISTENERS=PLAINTEXT://0.0.0.0:9092 \
    KAFKA_ADVERTISED_LISTENERS=PLAINTEXT://localhost:9092 \
    KAFKA_LOG_DIRS=/opt/kafka/logs \
    KAFKA_NUM_NETWORK_THREADS=3 \
    KAFKA_NUM_IO_THREADS=8 \
    KAFKA_SOCKET_SEND_BUFFER_BYTES=102400 \
    KAFKA_SOCKET_RECEIVE_BUFFER_BYTES=102400 \
    KAFKA_SOCKET_REQUEST_MAX_BYTES=104857600 \
    KAFKA_LOG_RETENTION_HOURS=168 \
    KAFKA_LOG_SEGMENT_BYTES=1073741824 \
    KAFKA_LOG_RETENTION_CHECK_INTERVAL_MS=300000

RUN apt-get update && apt-get install -y \
    openjdk-11-jre-headless \
    wget \
    netcat \
    gosu \
    && rm -rf /var/lib/apt/lists/*

RUN groupadd -r kafka --gid=1001 && \
    useradd -r -g kafka --uid=1001 --home-dir=$KAFKA_HOME kafka

RUN wget -O kafka.tgz "https://archive.apache.org/dist/kafka/${KAFKA_VERSION}/kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz" && \
    tar -xzf kafka.tgz --strip-components=1 -C /tmp && \
    mkdir -p $KAFKA_HOME && \
    mv /tmp/* $KAFKA_HOME/ && \
    rm kafka.tgz && \
    mkdir -p $KAFKA_LOG_DIRS && \
    chown -R kafka:kafka $KAFKA_HOME

WORKDIR $KAFKA_HOME

COPY kafka-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/kafka-entrypoint.sh

EXPOSE 9092
VOLUME ["$KAFKA_LOG_DIRS"]

ENTRYPOINT ["kafka-entrypoint.sh"]
CMD ["kafka-server-start.sh", "/opt/kafka/config/server.properties"]


FROM debian:bookworm-slim

ENV MONGODB_VERSION=7.0 \
    MONGODB_ROOT_PASSWORD="" \
    MONGODB_ROOT_USER="" \
    MONGODB_USERNAME="" \
    MONGODB_PASSWORD="" \
    MONGODB_DATABASE="" \
    MONGODB_PORT_NUMBER=27017 \
    MONGODB_ENABLE_AUTH=no \
    MONGODB_REPLICA_SET_MODE=no

RUN apt-get update && apt-get install -y \
    wget \
    gnupg \
    ca-certificates \
    gosu \
    && rm -rf /var/lib/apt/lists/*

RUN wget -qO - https://www.mongodb.org/static/pgp/server-7.0.asc | apt-key add - && \
    echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/debian bookworm/mongodb-org/7.0 main" > /etc/apt/sources.list.d/mongodb-org-7.0.list && \
    apt-get update && \
    apt-get install -y mongodb-org && \
    rm -rf /var/lib/apt/lists/*

RUN mkdir -p /opt/mongodb/{data,conf,logs} && \
    chown -R mongodb:mongodb /opt/mongodb && \
    usermod -d /opt/mongodb mongodb

WORKDIR /opt/mongodb

COPY mongodb-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/mongodb-entrypoint.sh

EXPOSE 27017
VOLUME ["/opt/mongodb/data"]

ENTRYPOINT ["mongodb-entrypoint.sh"]
CMD ["mongod"]


FROM debian:bullseye-slim

RUN apt-get update && apt-get install -y \
    wget \
    git \
    golang-go \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /src
RUN git clone https://github.com/percona/mongodb_exporter.git . && \
    go mod download && \
    CGO_ENABLED=0 GOOS=linux go build -o mongodb_exporter

RUN groupadd -r mongodb-exporter --gid=1001 && \
    useradd -r -g mongodb-exporter --uid=1001 --home-dir=/opt/mongodb-exporter mongodb-exporter && \
    mkdir -p /opt/mongodb-exporter && \
    mv mongodb_exporter /opt/mongodb-exporter/ && \
    chown -R mongodb-exporter:mongodb-exporter /opt/mongodb-exporter

WORKDIR /opt/mongodb-exporter
EXPOSE 9216
USER mongodb-exporter
ENV MONGODB_URI=""
ENTRYPOINT ["./mongodb_exporter"]


FROM debian:bullseye-slim

RUN apt-get update && apt-get install -y \
    wget \
    git \
    golang-go \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /src
RUN git clone https://github.com/prometheus-community/postgres_exporter.git . && \
    go mod download && \
    CGO_ENABLED=0 GOOS=linux go build -o postgres_exporter cmd/postgres_exporter/postgres_exporter.go

RUN groupadd -r postgres-exporter --gid=1001 && \
    useradd -r -g postgres-exporter --uid=1001 --home-dir=/opt/postgres-exporter postgres-exporter && \
    mkdir -p /opt/postgres-exporter && \
    mv postgres_exporter /opt/postgres-exporter/ && \
    chown -R postgres-exporter:postgres-exporter /opt/postgres-exporter

WORKDIR /opt/postgres-exporter
EXPOSE 9187
USER postgres-exporter
ENV DATA_SOURCE_NAME=""
ENTRYPOINT ["./postgres_exporter"]


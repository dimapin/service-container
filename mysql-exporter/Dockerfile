FROM debian:bullseye-slim

RUN apt-get update && apt-get install -y \
    wget \
    git \
    golang-go \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /src
RUN git clone https://github.com/prometheus/mysqld_exporter.git . && \
    go mod download && \
    CGO_ENABLED=0 GOOS=linux go build -o mysqld_exporter

RUN groupadd -r mysql-exporter --gid=1001 && \
    useradd -r -g mysql-exporter --uid=1001 --home-dir=/opt/mysql-exporter mysql-exporter && \
    mkdir -p /opt/mysql-exporter && \
    mv mysqld_exporter /opt/mysql-exporter/ && \
    chown -R mysql-exporter:mysql-exporter /opt/mysql-exporter

WORKDIR /opt/mysql-exporter
EXPOSE 9104
USER mysql-exporter
ENV DATA_SOURCE_NAME=""
ENTRYPOINT ["./mysqld_exporter"]


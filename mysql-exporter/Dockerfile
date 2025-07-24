# Build stage
FROM debian:bookworm-slim AS builder

RUN apt-get update && apt-get install -y \
    wget \
    git \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/* \
    && wget -O go.tar.gz https://go.dev/dl/go1.23.4.linux-amd64.tar.gz \
    && tar -C /usr/local -xzf go.tar.gz \
    && rm go.tar.gz

ENV PATH="/usr/local/go/bin:${PATH}"

WORKDIR /src
RUN git clone https://github.com/prometheus/mysqld_exporter.git . && \
    go mod download && \
    CGO_ENABLED=0 GOOS=linux go build -o mysqld_exporter

# Runtime stage
FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN groupadd -r mysql-exporter --gid=1001 && \
    useradd -r -g mysql-exporter --uid=1001 --home-dir=/opt/mysql-exporter mysql-exporter && \
    mkdir -p /opt/mysql-exporter && \
    chown -R mysql-exporter:mysql-exporter /opt/mysql-exporter

COPY --from=builder /src/mysqld_exporter /opt/mysql-exporter/

WORKDIR /opt/mysql-exporter
EXPOSE 9104
USER mysql-exporter
ENV DATA_SOURCE_NAME=""
ENTRYPOINT ["./mysqld_exporter"]


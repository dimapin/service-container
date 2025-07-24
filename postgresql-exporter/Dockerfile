# Build stage
FROM debian:bookworm-slim AS builder

RUN apt-get update && apt-get install -y \
    wget \
    git \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/* \
    && wget -O go.tar.gz https://go.dev/dl/go1.22.5.linux-amd64.tar.gz \
    && tar -C /usr/local -xzf go.tar.gz \
    && rm go.tar.gz

ENV PATH="/usr/local/go/bin:${PATH}"

WORKDIR /src
RUN git clone https://github.com/prometheus-community/postgres_exporter.git . && \
    go mod download && \
    CGO_ENABLED=0 GOOS=linux go build -o postgres_exporter ./cmd/postgres_exporter

# Runtime stage
FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN groupadd -r postgres-exporter --gid=1001 && \
    useradd -r -g postgres-exporter --uid=1001 --home-dir=/opt/postgres-exporter postgres-exporter && \
    mkdir -p /opt/postgres-exporter && \
    chown -R postgres-exporter:postgres-exporter /opt/postgres-exporter

COPY --from=builder /src/postgres_exporter /opt/postgres-exporter/

WORKDIR /opt/postgres-exporter
EXPOSE 9187
USER postgres-exporter
ENV DATA_SOURCE_NAME=""
ENTRYPOINT ["./postgres_exporter"]


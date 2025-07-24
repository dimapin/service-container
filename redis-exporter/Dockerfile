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
RUN git clone https://github.com/oliver006/redis_exporter.git . && \
    go mod download && \
    CGO_ENABLED=0 GOOS=linux go build -o redis_exporter

# Runtime stage
FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN groupadd -r redis-exporter --gid=1001 && \
    useradd -r -g redis-exporter --uid=1001 --home-dir=/opt/redis-exporter redis-exporter && \
    mkdir -p /opt/redis-exporter && \
    chown -R redis-exporter:redis-exporter /opt/redis-exporter

COPY --from=builder /src/redis_exporter /opt/redis-exporter/

WORKDIR /opt/redis-exporter
EXPOSE 9121
USER redis-exporter
ENV REDIS_ADDR="redis://localhost:6379"
ENTRYPOINT ["./redis_exporter"]


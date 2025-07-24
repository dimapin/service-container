FROM debian:bullseye-slim

RUN apt-get update && apt-get install -y \
    wget \
    git \
    golang-go \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /src
RUN git clone https://github.com/oliver006/redis_exporter.git . && \
    go mod download && \
    CGO_ENABLED=0 GOOS=linux go build -o redis_exporter

RUN groupadd -r redis-exporter --gid=1001 && \
    useradd -r -g redis-exporter --uid=1001 --home-dir=/opt/redis-exporter redis-exporter && \
    mkdir -p /opt/redis-exporter && \
    mv redis_exporter /opt/redis-exporter/ && \
    chown -R redis-exporter:redis-exporter /opt/redis-exporter

WORKDIR /opt/redis-exporter
EXPOSE 9121
USER redis-exporter
ENV REDIS_ADDR="redis://localhost:6379"
ENTRYPOINT ["./redis_exporter"]


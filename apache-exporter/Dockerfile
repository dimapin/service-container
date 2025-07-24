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
RUN git clone https://github.com/Lusitaniae/apache_exporter.git . && \
    go mod download && \
    CGO_ENABLED=0 GOOS=linux go build -o apache_exporter

# Runtime stage
FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN groupadd -r apache-exporter --gid=1001 && \
    useradd -r -g apache-exporter --uid=1001 --home-dir=/opt/apache-exporter apache-exporter && \
    mkdir -p /opt/apache-exporter && \
    chown -R apache-exporter:apache-exporter /opt/apache-exporter

COPY --from=builder /src/apache_exporter /opt/apache-exporter/

WORKDIR /opt/apache-exporter
EXPOSE 9117
USER apache-exporter
ENTRYPOINT ["./apache_exporter"]

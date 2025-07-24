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
RUN git clone https://github.com/percona/mongodb_exporter.git . && \
    go mod download && \
    CGO_ENABLED=0 GOOS=linux go build -o mongodb_exporter

# Runtime stage
FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN groupadd -r mongodb-exporter --gid=1001 && \
    useradd -r -g mongodb-exporter --uid=1001 --home-dir=/opt/mongodb-exporter mongodb-exporter && \
    mkdir -p /opt/mongodb-exporter && \
    chown -R mongodb-exporter:mongodb-exporter /opt/mongodb-exporter

COPY --from=builder /src/mongodb_exporter /opt/mongodb-exporter/

WORKDIR /opt/mongodb-exporter
EXPOSE 9216
USER mongodb-exporter
ENV MONGODB_URI=""
ENTRYPOINT ["./mongodb_exporter"]


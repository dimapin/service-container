FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y \
    wget \
    git \
    golang-go \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /src
RUN git clone https://github.com/Lusitaniae/apache_exporter.git . && \
    go mod download && \
    CGO_ENABLED=0 GOOS=linux go build -o apache_exporter

RUN groupadd -r apache-exporter --gid=1001 && \
    useradd -r -g apache-exporter --uid=1001 --home-dir=/opt/apache-exporter apache-exporter && \
    mkdir -p /opt/apache-exporter && \
    mv apache_exporter /opt/apache-exporter/ && \
    chown -R apache-exporter:apache-exporter /opt/apache-exporter

WORKDIR /opt/apache-exporter
EXPOSE 9117
USER apache-exporter
ENTRYPOINT ["./apache_exporter"]

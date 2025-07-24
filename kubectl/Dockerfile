FROM debian:bullseye-slim

ENV KUBECTL_VERSION=v1.28.4

RUN apt-get update && apt-get install -y \
    curl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl" && \
    chmod +x kubectl && \
    mv kubectl /usr/local/bin/

RUN groupadd -r kubectl --gid=1001 && \
    useradd -r -g kubectl --uid=1001 --home-dir=/home/kubectl kubectl && \
    mkdir -p /home/kubectl/.kube && \
    chown -R kubectl:kubectl /home/kubectl

WORKDIR /home/kubectl
USER kubectl
CMD ["kubectl", "version", "--client"]


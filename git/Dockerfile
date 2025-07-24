FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y \
    git \
    git-daemon-run \
    openssh-server \
    curl \
    ca-certificates \
    gosu \
    && rm -rf /var/lib/apt/lists/*

RUN groupadd -r git --gid=1001 && \
    useradd -r -g git --uid=1001 --home-dir=/opt/git git && \
    mkdir -p /opt/git/repositories && \
    chown -R git:git /opt/git

WORKDIR /opt/git

COPY git-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/git-entrypoint.sh

EXPOSE 9418 22
VOLUME ["/opt/git/repositories"]

ENTRYPOINT ["git-entrypoint.sh"]
CMD ["git", "daemon", "--reuseaddr", "--base-path=/opt/git/repositories", "/opt/git/repositories"]


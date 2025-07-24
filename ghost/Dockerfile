FROM debian:bookworm-slim

ENV NODE_VERSION=18.18.2 \
    GHOST_CLI_VERSION=1.24.2 \
    GHOST_VERSION=5.74.0 \
    GHOST_INSTALL=/var/lib/ghost \
    GHOST_CONTENT=/var/lib/ghost/content

RUN apt-get update && apt-get install -y \
    curl \
    ca-certificates \
    gosu \
    xz-utils \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js
RUN curl -fsSL https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-x64.tar.xz | tar -xJ -C /usr/local --strip-components=1

# Install Ghost CLI
RUN npm install -g "ghost-cli@$GHOST_CLI_VERSION"

RUN groupadd -r ghost --gid=1001 && \
    useradd -r -g ghost --uid=1001 --home-dir=$GHOST_INSTALL ghost && \
    mkdir -p $GHOST_INSTALL $GHOST_CONTENT && \
    chown -R ghost:ghost $GHOST_INSTALL $GHOST_CONTENT

WORKDIR $GHOST_INSTALL

COPY ghost-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/ghost-entrypoint.sh

EXPOSE 2368
VOLUME $GHOST_CONTENT

USER ghost
ENTRYPOINT ["ghost-entrypoint.sh"]
CMD ["ghost", "run"]


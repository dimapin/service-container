FROM debian:bookworm-slim

ENV POSTGRESQL_VERSION=15 \
    POSTGRESQL_USER=postgres \
    POSTGRESQL_PASSWORD="" \
    POSTGRESQL_DATABASE="" \
    POSTGRESQL_USERNAME="" \
    POSTGRESQL_POSTGRES_PASSWORD="" \
    POSTGRESQL_PORT_NUMBER=5432 \
    POSTGRESQL_MAX_CONNECTIONS=100

RUN apt-get update && apt-get install -y \
    wget \
    ca-certificates \
    locales \
    gosu \
    gnupg \
    && rm -rf /var/lib/apt/lists/*

# Add PostgreSQL official APT repository
RUN wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - \
    && echo "deb http://apt.postgresql.org/pub/repos/apt/ bookworm-pgdg main" > /etc/apt/sources.list.d/pgdg.list

# Install PostgreSQL
RUN apt-get update && apt-get install -y \
    postgresql-${POSTGRESQL_VERSION} \
    postgresql-client-${POSTGRESQL_VERSION} \
    postgresql-contrib-${POSTGRESQL_VERSION} \
    && rm -rf /var/lib/apt/lists/*

# Create postgresql user and directories
RUN groupadd -r postgresql --gid=1001 && \
    useradd -r -g postgresql --uid=1001 --home-dir=/opt/postgresql postgresql && \
    mkdir -p /opt/postgresql/{data,conf,logs,tmp} && \
    chown -R postgresql:postgresql /opt/postgresql

WORKDIR /opt/postgresql

COPY entrypoint.sh /opt/postgresql/
RUN chmod +x /opt/postgresql/entrypoint.sh

EXPOSE 5432
VOLUME ["/opt/postgresql/data"]

USER postgresql
ENTRYPOINT ["/opt/postgresql/entrypoint.sh"]
CMD ["postgres"]

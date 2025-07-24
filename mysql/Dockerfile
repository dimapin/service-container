FROM debian:bullseye-slim

ENV MYSQL_ROOT_PASSWORD="" \
    MYSQL_USER="" \
    MYSQL_PASSWORD="" \
    MYSQL_DATABASE=""

RUN apt-get update && apt-get install -y \
    wget \
    gnupg \
    ca-certificates \
    gosu \
    lsb-release \
    && rm -rf /var/lib/apt/lists/*

# Add MySQL APT repository
RUN wget https://dev.mysql.com/get/mysql-apt-config_0.8.34-1_all.deb \
    && DEBIAN_FRONTEND=noninteractive dpkg -i mysql-apt-config_0.8.34-1_all.deb \
    && rm mysql-apt-config_0.8.34-1_all.deb

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    mysql-server \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /opt/mysql/{data,conf,logs} && \
    chown -R mysql:mysql /opt/mysql && \
    usermod -d /opt/mysql mysql

EXPOSE 3306
VOLUME ["/opt/mysql/data"]

USER mysql
CMD ["mysqld"]

FROM debian:bullseye-slim

ENV MOODLE_VERSION=4.5.1 \
    MOODLE_DATABASE_TYPE=mariadb \
    MOODLE_DATABASE_HOST=mariadb \
    MOODLE_DATABASE_PORT_NUMBER=3306 \
    MOODLE_DATABASE_USER=moodle \
    MOODLE_DATABASE_PASSWORD="" \
    MOODLE_DATABASE_NAME=moodle \
    MOODLE_USERNAME=admin \
    MOODLE_PASSWORD="" \
    MOODLE_EMAIL=admin@example.com \
    MOODLE_SITE_NAME="Moodle Site"

RUN apt-get update && apt-get install -y \
    apache2 \
    php8.2 \
    php8.2-apache2 \
    php8.2-mysql \
    php8.2-pgsql \
    php8.2-gd \
    php8.2-xml \
    php8.2-mbstring \
    php8.2-curl \
    php8.2-zip \
    php8.2-intl \
    php8.2-soap \
    php8.2-ldap \
    php8.2-opcache \
    unzip \
    wget \
    gosu \
    cron \
    && rm -rf /var/lib/apt/lists/*

RUN groupadd -r moodle --gid=1001 && \
    useradd -r -g moodle --uid=1001 --home-dir=/opt/moodle moodle

RUN wget https://download.moodle.org/download.php/direct/stable403/moodle-${MOODLE_VERSION}.tgz && \
    tar -xzf moodle-${MOODLE_VERSION}.tgz && \
    mv moodle /opt/moodle && \
    mkdir -p /opt/moodledata && \
    chown -R moodle:moodle /opt/moodle /opt/moodledata && \
    rm moodle-${MOODLE_VERSION}.tgz

# Configure Apache
RUN echo 'ServerName localhost' >> /etc/apache2/apache2.conf && \
    a2enmod rewrite

WORKDIR /opt/moodle

COPY moodle-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/moodle-entrypoint.sh

EXPOSE 80
VOLUME ["/opt/moodledata"]

ENTRYPOINT ["moodle-entrypoint.sh"]
CMD ["apache2-foreground"]


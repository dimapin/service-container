FROM debian:bookworm-slim

ENV LDAP_ORGANIZATION="Example Organization" \
    LDAP_DOMAIN=example.org \
    LDAP_BASE_DN="" \
    LDAP_ADMIN_USERNAME=admin \
    LDAP_ADMIN_PASSWORD="" \
    LDAP_USERS="" \
    LDAP_PASSWORDS="" \
    LDAP_USER_DC=users \
    LDAP_GROUP=readers \
    LDAP_PORT_NUMBER=1389 \
    LDAP_LDAPS_PORT_NUMBER=1636 \
    LDAP_ENABLE_TLS=no

RUN apt-get update && apt-get install -y \
    slapd \
    ldap-utils \
    ca-certificates \
    gosu \
    gettext-base \
    && rm -rf /var/lib/apt/lists/*

RUN groupadd -r openldap --gid=1001 && \
    useradd -r -g openldap --uid=1001 --home-dir=/opt/openldap openldap && \
    mkdir -p /opt/openldap/{data,conf} && \
    chown -R openldap:openldap /opt/openldap

WORKDIR /opt/openldap

COPY openldap-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/openldap-entrypoint.sh

EXPOSE 1389 1636
VOLUME ["/opt/openldap/data", "/opt/openldap/conf"]

ENTRYPOINT ["openldap-entrypoint.sh"]
CMD ["slapd", "-d", "32768", "-u", "openldap", "-g", "openldap"]

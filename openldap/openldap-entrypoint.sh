#!/bin/bash
set -e

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*"
}

if [ "$(id -u)" = '0' ]; then
    exec gosu openldap "$0" "$@"
fi

# Set default base DN if not provided
if [ -z "$LDAP_BASE_DN" ]; then
    LDAP_BASE_DN="dc=$(echo $LDAP_DOMAIN | sed 's/\./,dc=/g')"
fi

LDAP_CONFIG_DIR="/opt/openldap/conf"
LDAP_DATA_DIR="/opt/openldap/data"

# Initialize LDAP if not already done
if [ ! -f "$LDAP_DATA_DIR/.ldap_initialized" ]; then
    log "Initializing OpenLDAP..."
    
    # Create basic configuration
    cat > "$LDAP_CONFIG_DIR/slapd.conf" << EOF
include /etc/ldap/schema/core.schema
include /etc/ldap/schema/cosine.schema
include /etc/ldap/schema/nis.schema
include /etc/ldap/schema/inetorgperson.schema

pidfile /var/run/slapd.pid
argsfile /var/run/slapd.args

loglevel none

database mdb
suffix "$LDAP_BASE_DN"
rootdn "cn=$LDAP_ADMIN_USERNAME,$LDAP_BASE_DN"
rootpw $LDAP_ADMIN_PASSWORD
directory $LDAP_DATA_DIR

index objectClass eq
EOF

    # Create initial LDIF
    cat > /tmp/init.ldif << EOF
dn: $LDAP_BASE_DN
objectClass: top
objectClass: dcObject
objectClass: organization
o: $LDAP_ORGANIZATION
dc: $(echo $LDAP_DOMAIN | cut -d. -f1)

dn: cn=$LDAP_ADMIN_USERNAME,$LDAP_BASE_DN
objectClass: simpleSecurityObject
objectClass: organizationalRole
cn: $LDAP_ADMIN_USERNAME
userPassword: $LDAP_ADMIN_PASSWORD

dn: ou=$LDAP_USER_DC,$LDAP_BASE_DN
objectClass: organizationalUnit
ou: $LDAP_USER_DC
EOF

    # Add users if specified
    if [ -n "$LDAP_USERS" ]; then
        IFS=',' read -ra USERS <<< "$LDAP_USERS"
        IFS=',' read -ra PASSWORDS <<< "$LDAP_PASSWORDS"
        
        for i in "${!USERS[@]}"; do
            user="${USERS[$i]}"
            password="${PASSWORDS[$i]:-password}"
            
            cat >> /tmp/init.ldif << EOF

dn: cn=$user,ou=$LDAP_USER_DC,$LDAP_BASE_DN
objectClass: inetOrgPerson
cn: $user
sn: $user
userPassword: $password
EOF
        done
    fi
    
    # Initialize database
    slapadd -f "$LDAP_CONFIG_DIR/slapd.conf" -l /tmp/init.ldif
    
    touch "$LDAP_DATA_DIR/.ldap_initialized"
    log "OpenLDAP initialization completed"
fi

exec slapd -f "$LDAP_CONFIG_DIR/slapd.conf" -h "ldap://0.0.0.0:$LDAP_PORT_NUMBER" -d 32768
default.replication.factor=1
offsets.topic.replication.factor=1
transaction.state.log.replication.factor=1
transaction.state.log.min.isr=1
log.retention.hours=${KAFKA_LOG_RETENTION_HOURS}
log.segment.bytes=${KAFKA_LOG_SEGMENT_BYTES}
log.retention.check.interval.ms=${KAFKA_LOG_RETENTION_CHECK_INTERVAL_MS}
zookeeper.connect=${KAFKA_ZOOKEEPER_CONNECT}
zookeeper.connection.timeout.ms=18000
group.initial.rebalance.delay.ms=0
EOF

# Wait for Zookeeper if needed
if [ "${KAFKA_ZOOKEEPER_CONNECT}" != "localhost:2181" ]; then
    echo "Waiting for Zookeeper at ${KAFKA_ZOOKEEPER_CONNECT}..."
    while ! nc -z ${KAFKA_ZOOKEEPER_CONNECT/:/ }; do
        sleep 1
    done
fi

exec "$@"


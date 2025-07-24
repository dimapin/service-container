#!/bin/bash
set -e

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*"
}

if [ "$(id -u)" = '0' ]; then
    exec gosu postgresql "$0" "$@"
fi

POSTGRESQL_DATA_DIR="/opt/postgresql/data"

# Initialize database if needed
if [ ! -f "$POSTGRESQL_DATA_DIR/PG_VERSION" ]; then
    log "Initializing PostgreSQL database..."
    
    initdb --pgdata="$POSTGRESQL_DATA_DIR" --username=postgres
    
    # Basic configuration
    echo "listen_addresses = '*'" >> "$POSTGRESQL_DATA_DIR/postgresql.conf"
    echo "port = $POSTGRESQL_PORT_NUMBER" >> "$POSTGRESQL_DATA_DIR/postgresql.conf"
    
    # Allow connections
    echo "host all all 0.0.0.0/0 md5" >> "$POSTGRESQL_DATA_DIR/pg_hba.conf"
    
    # Start PostgreSQL temporarily for setup
    pg_ctl -D "$POSTGRESQL_DATA_DIR" -l /opt/postgresql/logs/postgresql.log start
    
    # Set passwords
    if [ -n "$POSTGRESQL_PASSWORD" ]; then
        psql -v ON_ERROR_STOP=1 --username postgres <<-EOSQL
            ALTER USER postgres PASSWORD '$POSTGRESQL_PASSWORD';
EOSQL
    fi
    
    # Create custom user and database
    if [ -n "$POSTGRESQL_USERNAME" ] && [ -n "$POSTGRESQL_DATABASE" ]; then
        psql -v ON_ERROR_STOP=1 --username postgres <<-EOSQL
            CREATE USER "$POSTGRESQL_USERNAME" WITH PASSWORD '${POSTGRESQL_PASSWORD:-password}';
            CREATE DATABASE "$POSTGRESQL_DATABASE" OWNER "$POSTGRESQL_USERNAME";
EOSQL
    fi
    
    pg_ctl -D "$POSTGRESQL_DATA_DIR" stop
    log "PostgreSQL initialization completed"
fi

exec postgres -D "$POSTGRESQL_DATA_DIR"

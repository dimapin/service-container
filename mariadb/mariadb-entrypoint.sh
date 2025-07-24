#!/bin/bash
set -e

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*"
}

if [ "$(id -u)" = '0' ]; then
    exec gosu mariadb "$0" "$@"
fi

MARIADB_DATA_DIR="/opt/mariadb/data"

if [ "$MARIADB_ALLOW_EMPTY_PASSWORD" != "yes" ] && [ -z "$MARIADB_ROOT_PASSWORD" ]; then
    echo "Error: No root password specified"
    exit 1
fi

# Initialize database if needed
if [ ! -d "$MARIADB_DATA_DIR/mysql" ]; then
    log "Initializing MariaDB database..."
    
    mysql_install_db --user=mariadb --datadir="$MARIADB_DATA_DIR"
    
    # Start MariaDB temporarily
    mysqld_safe --datadir="$MARIADB_DATA_DIR" --socket=/tmp/mysql.sock --user=mariadb &
    
    # Wait for MariaDB to start
    for i in {30..0}; do
        if mysqladmin --socket=/tmp/mysql.sock ping >/dev/null 2>&1; then
            break
        fi
        sleep 1
    done
    
    # Configure root user
    if [ -n "$MARIADB_ROOT_PASSWORD" ]; then
        mysql --socket=/tmp/mysql.sock -u root <<-EOSQL
            SET @@SESSION.SQL_LOG_BIN=0;
            ALTER USER 'root'@'localhost' IDENTIFIED BY '$MARIADB_ROOT_PASSWORD';
            CREATE USER 'root'@'%' IDENTIFIED BY '$MARIADB_ROOT_PASSWORD';
            GRANT ALL ON *.* TO 'root'@'%' WITH GRANT OPTION;
EOSQL
    fi
    
    # Create custom database and user
    if [ -n "$MARIADB_DATABASE" ]; then
        mysql --socket=/tmp/mysql.sock -u root ${MARIADB_ROOT_PASSWORD:+-p$MARIADB_ROOT_PASSWORD} <<-EOSQL
            CREATE DATABASE IF NOT EXISTS \`$MARIADB_DATABASE\`;
EOSQL
    fi
    
    if [ -n "$MARIADB_USER" ] && [ -n "$MARIADB_PASSWORD" ]; then
        mysql --socket=/tmp/mysql.sock -u root ${MARIADB_ROOT_PASSWORD:+-p$MARIADB_ROOT_PASSWORD} <<-EOSQL
            CREATE USER '$MARIADB_USER'@'%' IDENTIFIED BY '$MARIADB_PASSWORD';
            GRANT ALL ON \`${MARIADB_DATABASE:-*}\`.* TO '$MARIADB_USER'@'%';
EOSQL
    fi
    
    mysqladmin --socket=/tmp/mysql.sock shutdown
    log "MariaDB initialization completed"
fi

exec "$@"


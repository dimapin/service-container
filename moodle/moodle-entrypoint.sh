#!/bin/bash
set -e

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*"
}

if [ "$(id -u)" = '0' ]; then
    exec gosu moodle "$0" "$@"
fi

# Initialize Moodle if config doesn't exist
if [ ! -f "/opt/moodle/config.php" ]; then
    log "Initializing Moodle..."
    
    # Wait for database
    if [ "$MOODLE_DATABASE_TYPE" = "mariadb" ] || [ "$MOODLE_DATABASE_TYPE" = "mysqli" ]; then
        while ! nc -z "$MOODLE_DATABASE_HOST" "$MOODLE_DATABASE_PORT_NUMBER"; do
            log "Waiting for database..."
            sleep 2
        done
    fi
    
    # Install Moodle
    php /opt/moodle/admin/cli/install.php \
        --lang=en \
        --wwwroot="http://localhost" \
        --dataroot="/opt/moodledata" \
        --dbtype="$MOODLE_DATABASE_TYPE" \
        --dbhost="$MOODLE_DATABASE_HOST" \
        --dbname="$MOODLE_DATABASE_NAME" \
        --dbuser="$MOODLE_DATABASE_USER" \
        --dbpass="$MOODLE_DATABASE_PASSWORD" \
        --fullname="$MOODLE_SITE_NAME" \
        --shortname="Moodle" \
        --adminuser="$MOODLE_USERNAME" \
        --adminpass="$MOODLE_PASSWORD" \
        --adminemail="$MOODLE_EMAIL" \
        --non-interactive \
        --agree-license
        
    log "Moodle installation completed"
fi

exec "$@"


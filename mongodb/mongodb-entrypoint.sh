#!/bin/bash
set -e

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*"
}

if [ "$(id -u)" = '0' ]; then
    exec gosu mongodb "$0" "$@"
fi

MONGODB_DATA_DIR="/opt/mongodb/data"
MONGODB_LOG_DIR="/opt/mongodb/logs"

# Create configuration file
cat > /opt/mongodb/conf/mongod.conf << EOF
storage:
  dbPath: ${MONGODB_DATA_DIR}
  journal:
    enabled: true

systemLog:
  destination: file
  logAppend: true
  path: ${MONGODB_LOG_DIR}/mongod.log

net:
  port: ${MONGODB_PORT_NUMBER}
  bindIp: 0.0.0.0

processManagement:
  timeZoneInfo: /usr/share/zoneinfo
EOF

# Add authentication if enabled
if [ "$MONGODB_ENABLE_AUTH" = "yes" ]; then
    echo "security:" >> /opt/mongodb/conf/mongod.conf
    echo "  authorization: enabled" >> /opt/mongodb/conf/mongod.conf
fi

# Initialize database if needed
if [ ! -f "$MONGODB_DATA_DIR/.mongodb_initialized" ]; then
    log "Initializing MongoDB..."
    
    # Start MongoDB temporarily
    mongod --config /opt/mongodb/conf/mongod.conf --fork
    
    # Wait for MongoDB to start
    until mongo --eval "print('MongoDB is ready')" >/dev/null 2>&1; do
        sleep 1
    done
    
    # Create admin user if specified
    if [ -n "$MONGODB_ROOT_USER" ] && [ -n "$MONGODB_ROOT_PASSWORD" ]; then
        log "Creating admin user..."
        mongo admin <<-EOJS
            db.createUser({
                user: "$MONGODB_ROOT_USER",
                pwd: "$MONGODB_ROOT_PASSWORD",
                roles: ["root"]
            })
EOJS
    fi
    
    # Create custom user and database
    if [ -n "$MONGODB_USERNAME" ] && [ -n "$MONGODB_PASSWORD" ] && [ -n "$MONGODB_DATABASE" ]; then
        log "Creating custom user and database..."
        mongo "$MONGODB_DATABASE" <<-EOJS
            db.createUser({
                user: "$MONGODB_USERNAME",
                pwd: "$MONGODB_PASSWORD",
                roles: ["readWrite"]
            })
EOJS
    fi
    
    # Stop temporary instance
    mongo admin --eval "db.shutdownServer()"
    
    touch "$MONGODB_DATA_DIR/.mongodb_initialized"
    log "MongoDB initialization completed"
fi

exec mongod --config /opt/mongodb/conf/mongod.conf


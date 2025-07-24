#!/bin/bash
set -e

if [ "$(id -u)" = '0' ]; then
    exec gosu ghost "$0" "$@"
fi

# Install Ghost if not already installed
if [ ! -f "$GHOST_INSTALL/package.json" ]; then
    echo "Installing Ghost $GHOST_VERSION..."
    ghost install "$GHOST_VERSION" --db sqlite3 --no-prompt --no-stack --no-setup --dir "$GHOST_INSTALL"
fi

if [ ! -f "$GHOST_INSTALL/config.production.json" ]; then
    echo "Setting up Ghost configuration..."
    
    cat > "$GHOST_INSTALL/config.production.json" << EOF
{
  "url": "${GHOST_URL:-http://localhost:2368}",
  "server": {
    "port": 2368,
    "host": "0.0.0.0"
  },
  "database": {
    "client": "sqlite3",
    "connection": {
      "filename": "${GHOST_CONTENT}/data/ghost.db"
    }
  },
  "mail": {
    "transport": "Direct"
  },
  "logging": {
    "transports": ["stdout"]
  },
  "process": "local",
  "paths": {
    "contentPath": "${GHOST_CONTENT}"
  }
}
EOF
fi

exec "$@"


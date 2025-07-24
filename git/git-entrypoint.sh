#!/bin/bash
set -e

if [ "$(id -u)" = '0' ]; then
    exec gosu git "$0" "$@"
fi

# Initialize repositories directory if empty
if [ ! "$(ls -A /opt/git/repositories)" ]; then
    echo "Initializing Git repositories directory..."
    mkdir -p /opt/git/repositories/sample.git
    cd /opt/git/repositories/sample.git
    git init --bare
    echo "Sample Git repository created"
fi

exec "$@"


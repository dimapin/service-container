#!/bin/bash
set -e

# Set shell user password if provided
if [ -n "$SHELL_PASSWORD" ]; then
    echo "shell:$SHELL_PASSWORD" | chpasswd
fi

# Generate SSH host keys if they don't exist
ssh-keygen -A

exec "$@"


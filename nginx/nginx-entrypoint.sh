#!/bin/bash
set -e

if [ "$(id -u)" = '0' ]; then
    exec gosu nginx "$0" "$@"
fi

# Generate nginx configuration
envsubst '${NGINX_PORT_NUMBER} ${NGINX_SERVER_NAME}' < /opt/nginx/conf/nginx.conf.template > /etc/nginx/nginx.conf

exec "$@"

# nginx/nginx.conf.template
user nginx;
worker_processes auto;
pid /run/nginx.pid;

events {
    worker_connections 1024;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';

    access_log /opt/nginx/logs/access.log main;
    error_log /opt/nginx/logs/error.log;

    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;

    server {
        listen ${NGINX_PORT_NUMBER};
        server_name ${NGINX_SERVER_NAME};
        root /opt/nginx/html;
        index index.html index.htm;

        location / {
            try_files $uri $uri/ =404;
        }

        error_page 500 502 503 504 /50x.html;
        location = /50x.html {
            root /opt/nginx/html;
        }
    }
}


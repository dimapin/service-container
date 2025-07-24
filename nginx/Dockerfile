FROM debian:bookworm-slim

ENV NGINX_VERSION=1.24.0 \
    NGINX_USER=nginx \
    NGINX_DAEMON=off \
    NGINX_SERVER_NAME=localhost \
    NGINX_PORT_NUMBER=8080 \
    NGINX_ENABLE_ABSOLUTE_REDIRECT=yes \
    NGINX_ENABLE_PORT_IN_REDIRECT=no

RUN apt-get update && apt-get install -y \
    nginx \
    ca-certificates \
    gosu \
    gettext-base \
    && rm -rf /var/lib/apt/lists/*

RUN groupadd -r nginx --gid=1001 && \
    useradd -r -g nginx --uid=1001 --home-dir=/opt/nginx nginx && \
    mkdir -p /opt/nginx/{conf,logs,tmp} && \
    chown -R nginx:nginx /opt/nginx /var/log/nginx

WORKDIR /opt/nginx

COPY nginx.conf.template /opt/nginx/conf/
COPY nginx-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/nginx-entrypoint.sh

RUN mkdir -p /opt/nginx/html && \
    echo '<h1>Welcome to nginx!</h1>' > /opt/nginx/html/index.html && \
    chown nginx:nginx /opt/nginx/html/index.html

EXPOSE 8080
VOLUME ["/opt/nginx/html", "/opt/nginx/conf"]

ENTRYPOINT ["nginx-entrypoint.sh"]
CMD ["nginx", "-g", "daemon off;"]


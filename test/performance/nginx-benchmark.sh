#!/bin/bash
# Nginx Performance Benchmark Script

set -e

# Configuration
NGINX_HOST="${NGINX_HOST:-localhost}"
NGINX_PORT="${NGINX_PORT:-8080}"
REQUESTS="${REQUESTS:-1000}"
CONCURRENCY="${CONCURRENCY:-10}"
TIMELIMIT="${TIMELIMIT:-30}"

echo "🚀 Starting Nginx Performance Benchmark"
echo "Host: $NGINX_HOST:$NGINX_PORT"
echo "Requests: $REQUESTS, Concurrency: $CONCURRENCY, Time Limit: ${TIMELIMIT}s"

# Wait for Nginx to be ready
echo "⏳ Waiting for Nginx to be ready..."
until curl -f http://$NGINX_HOST:$NGINX_PORT >/dev/null 2>&1; do
    sleep 1
done
echo "✅ Nginx is ready!"

# Check if Apache Bench is available
if ! command -v ab >/dev/null 2>&1; then
    echo "❌ Apache Bench (ab) is not installed. Installing..."
    if command -v apt-get >/dev/null 2>&1; then
        apt-get update && apt-get install -y apache2-utils
    elif command -v yum >/dev/null 2>&1; then
        yum install -y httpd-tools
    else
        echo "❌ Cannot install Apache Bench automatically"
        exit 1
    fi
fi

# Run Apache Bench
echo "🏃 Running Apache Bench..."
ab -n $REQUESTS -c $CONCURRENCY -t $TIMELIMIT -g nginx_bench.dat http://$NGINX_HOST:$NGINX_PORT/

# Run wrk if available
if command -v wrk >/dev/null 2>&1; then
    echo "🏃 Running wrk benchmark..."
    wrk -t8 -c$CONCURRENCY -d${TIMELIMIT}s http://$NGINX_HOST:$NGINX_PORT/
fi

echo "✅ Nginx benchmark completed!"

#!/bin/bash
# MySQL Performance Benchmark Script

set -e

# Configuration
MYSQL_HOST="${MYSQL_HOST:-localhost}"
MYSQL_PORT="${MYSQL_PORT:-3306}"
MYSQL_USER="${MYSQL_USER:-testuser}"
MYSQL_PASSWORD="${MYSQL_PASSWORD:-testpass123}"
MYSQL_DB="${MYSQL_DB:-testdb}"
THREADS="${THREADS:-8}"
TIME="${TIME:-60}"
TABLE_SIZE="${TABLE_SIZE:-10000}"

echo "🚀 Starting MySQL Performance Benchmark"
echo "Host: $MYSQL_HOST:$MYSQL_PORT"
echo "Database: $MYSQL_DB"
echo "Threads: $THREADS, Time: ${TIME}s, Table Size: $TABLE_SIZE"

# Wait for MySQL to be ready
echo "⏳ Waiting for MySQL to be ready..."
until mysql -h $MYSQL_HOST -P $MYSQL_PORT -u $MYSQL_USER -p$MYSQL_PASSWORD -e "SELECT 1" >/dev/null 2>&1; do
    sleep 1
done
echo "✅ MySQL is ready!"

# Check if sysbench is available
if ! command -v sysbench >/dev/null 2>&1; then
    echo "❌ sysbench is not installed. Installing..."
    if command -v apt-get >/dev/null 2>&1; then
        apt-get update && apt-get install -y sysbench
    elif command -v yum >/dev/null 2>&1; then
        yum install -y sysbench
    else
        echo "❌ Cannot install sysbench automatically"
        exit 1
    fi
fi

# Prepare benchmark
echo "🔧 Preparing sysbench tables..."
sysbench oltp_read_write \
    --mysql-host=$MYSQL_HOST \
    --mysql-port=$MYSQL_PORT \
    --mysql-user=$MYSQL_USER \
    --mysql-password=$MYSQL_PASSWORD \
    --mysql-db=$MYSQL_DB \
    --threads=$THREADS \
    --table-size=$TABLE_SIZE \
    prepare

# Run benchmark
echo "🏃 Running sysbench benchmark..."
sysbench oltp_read_write \
    --mysql-host=$MYSQL_HOST \
    --mysql-port=$MYSQL_PORT \
    --mysql-user=$MYSQL_USER \
    --mysql-password=$MYSQL_PASSWORD \
    --mysql-db=$MYSQL_DB \
    --threads=$THREADS \
    --time=$TIME \
    --table-size=$TABLE_SIZE \
    --report-interval=10 \
    run

# Cleanup
echo "🧹 Cleaning up benchmark tables..."
sysbench oltp_read_write \
    --mysql-host=$MYSQL_HOST \
    --mysql-port=$MYSQL_PORT \
    --mysql-user=$MYSQL_USER \
    --mysql-password=$MYSQL_PASSWORD \
    --mysql-db=$MYSQL_DB \
    cleanup

echo "✅ MySQL benchmark completed!"

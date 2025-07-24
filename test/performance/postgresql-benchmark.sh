#!/bin/bash
# PostgreSQL Performance Benchmark Script

set -e

# Configuration
POSTGRES_HOST="${POSTGRES_HOST:-localhost}"
POSTGRES_PORT="${POSTGRES_PORT:-5432}"
POSTGRES_USER="${POSTGRES_USER:-testuser}"
POSTGRES_PASSWORD="${POSTGRES_PASSWORD:-testpass123}"
POSTGRES_DB="${POSTGRES_DB:-testdb}"
SCALE_FACTOR="${SCALE_FACTOR:-10}"
CLIENTS="${CLIENTS:-10}"
THREADS="${THREADS:-2}"
TRANSACTIONS="${TRANSACTIONS:-1000}"

echo "🚀 Starting PostgreSQL Performance Benchmark"
echo "Host: $POSTGRES_HOST:$POSTGRES_PORT"
echo "Database: $POSTGRES_DB"
echo "Scale Factor: $SCALE_FACTOR"
echo "Clients: $CLIENTS, Threads: $THREADS, Transactions: $TRANSACTIONS"

# Wait for PostgreSQL to be ready
echo "⏳ Waiting for PostgreSQL to be ready..."
until PGPASSWORD=$POSTGRES_PASSWORD psql -h $POSTGRES_HOST -p $POSTGRES_PORT -U $POSTGRES_USER -d $POSTGRES_DB -c "SELECT 1" >/dev/null 2>&1; do
    sleep 1
done
echo "✅ PostgreSQL is ready!"

# Initialize pgbench
echo "🔧 Initializing pgbench tables..."
PGPASSWORD=$POSTGRES_PASSWORD pgbench -h $POSTGRES_HOST -p $POSTGRES_PORT -U $POSTGRES_USER -d $POSTGRES_DB -i -s $SCALE_FACTOR

# Run benchmark
echo "🏃 Running pgbench benchmark..."
PGPASSWORD=$POSTGRES_PASSWORD pgbench -h $POSTGRES_HOST -p $POSTGRES_PORT -U $POSTGRES_USER -d $POSTGRES_DB \
    -c $CLIENTS -j $THREADS -t $TRANSACTIONS -P 10 -r

echo "✅ PostgreSQL benchmark completed!"

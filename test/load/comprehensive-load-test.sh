#!/bin/bash
# Comprehensive load test script

set -e

echo "⚡ Starting comprehensive load test..."

# Configuration
DURATION="${DURATION:-30}"
USERS="${USERS:-10}"

echo "Configuration: Duration=${DURATION}s, Users=${USERS}"

# Start background load tests
echo "🚀 Starting background load tests..."

# PostgreSQL load test
if command -v pgbench >/dev/null 2>&1; then
    echo "🐘 Starting PostgreSQL load test..."
    PGPASSWORD=testpass123 pgbench -h localhost -U testuser -d testdb -c $USERS -T $DURATION -P 5 &
    PG_PID=$!
else
    echo "⚠️  pgbench not available, skipping PostgreSQL load test"
    PG_PID=""
fi

# Redis load test
echo "🟥 Starting Redis load test..."
redis-benchmark -h localhost -a testpass123 -t set,get -n 10000 -c $USERS -q &
REDIS_PID=$!

# HTTP load test
if command -v ab >/dev/null 2>&1; then
    echo "🌐 Starting HTTP load test..."
    ab -t $DURATION -c $USERS http://localhost:8080/ >/dev/null 2>&1 &
    HTTP_PID=$!
else
    echo "⚠️  Apache Bench not available, skipping HTTP load test"
    HTTP_PID=""
fi

# Monitor system resources during load test
echo "📊 Monitoring system resources..."
echo "Timestamp,CPU%,Memory%" > load_test_metrics.csv

for i in $(seq 1 $DURATION); do
    cpu=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | sed 's/%us,//')
    memory=$(free | grep Mem | awk '{printf "%.2f", $3/$2 * 100.0}')
    echo "$(date +%H:%M:%S),$cpu,$memory" >> load_test_metrics.csv
    sleep 1
done

# Wait for all background processes to complete
echo "⏳ Waiting for load tests to complete..."
[ -n "$PG_PID" ] && wait $PG_PID 2>/dev/null || true
wait $REDIS_PID 2>/dev/null || true
[ -n "$HTTP_PID" ] && wait $HTTP_PID 2>/dev/null || true

echo "✅ Comprehensive load test completed!"
echo "📊 Metrics saved to load_test_metrics.csv"

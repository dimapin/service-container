#!/bin/bash
# Redis Performance Benchmark Script

set -e

# Configuration
REDIS_HOST="${REDIS_HOST:-localhost}"
REDIS_PORT="${REDIS_PORT:-6379}"
REDIS_PASSWORD="${REDIS_PASSWORD:-testpass123}"
REQUESTS="${REQUESTS:-10000}"
CLIENTS="${CLIENTS:-50}"
PIPELINE="${PIPELINE:-1}"

echo "🚀 Starting Redis Performance Benchmark"
echo "Host: $REDIS_HOST:$REDIS_PORT"
echo "Requests: $REQUESTS, Clients: $CLIENTS, Pipeline: $PIPELINE"

# Wait for Redis to be ready
echo "⏳ Waiting for Redis to be ready..."
until redis-cli -h $REDIS_HOST -p $REDIS_PORT -a $REDIS_PASSWORD ping >/dev/null 2>&1; do
    sleep 1
done
echo "✅ Redis is ready!"

# Run benchmark
echo "🏃 Running Redis benchmark..."

# Test SET operations
echo "📝 Testing SET operations..."
redis-benchmark -h $REDIS_HOST -p $REDIS_PORT -a $REDIS_PASSWORD \
    -t set -n $REQUESTS -c $CLIENTS -P $PIPELINE -q

# Test GET operations
echo "📖 Testing GET operations..."
redis-benchmark -h $REDIS_HOST -p $REDIS_PORT -a $REDIS_PASSWORD \
    -t get -n $REQUESTS -c $CLIENTS -P $PIPELINE -q

# Test INCR operations
echo "🔢 Testing INCR operations..."
redis-benchmark -h $REDIS_HOST -p $REDIS_PORT -a $REDIS_PASSWORD \
    -t incr -n $REQUESTS -c $CLIENTS -P $PIPELINE -q

# Test LPUSH operations
echo "📋 Testing LPUSH operations..."
redis-benchmark -h $REDIS_HOST -p $REDIS_PORT -a $REDIS_PASSWORD \
    -t lpush -n $REQUESTS -c $CLIENTS -P $PIPELINE -q

# Test LPOP operations
echo "📋 Testing LPOP operations..."
redis-benchmark -h $REDIS_HOST -p $REDIS_PORT -a $REDIS_PASSWORD \
    -t lpop -n $REQUESTS -c $CLIENTS -P $PIPELINE -q

# Mixed workload
echo "🔄 Testing mixed workload..."
redis-benchmark -h $REDIS_HOST -p $REDIS_PORT -a $REDIS_PASSWORD \
    -t set,get,incr,lpush,lpop,sadd,spop -n $REQUESTS -c $CLIENTS -P $PIPELINE

echo "✅ Redis benchmark completed!"

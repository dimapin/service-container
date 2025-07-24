#!/bin/bash
# Test Prometheus queries

set -e

PROMETHEUS_URL="${PROMETHEUS_URL:-http://localhost:9090}"

echo "🔍 Testing Prometheus queries..."

# Test queries
queries=(
    "up"
    "pg_up"
    "mysql_up"
    "redis_up"
    "mongodb_up"
    "rate(pg_stat_database_xact_commit_total[5m])"
    "mysql_global_status_connections"
    "redis_connected_clients"
)

for query in "${queries[@]}"; do
    echo -n "🔍 Testing query: $query... "
    
    result=$(curl -s "$PROMETHEUS_URL/api/v1/query" --data-urlencode "query=$query" | jq -r .status 2>/dev/null || echo "error")
    
    if [ "$result" = "success" ]; then
        echo "✅ OK"
    else
        echo "❌ FAILED"
    fi
done

echo "✅ Prometheus query test completed!"

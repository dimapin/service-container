#!/bin/bash
# Check metrics from all exporters

set -e

echo "📊 Checking metrics from all exporters..."

# PostgreSQL metrics
echo "🐘 Checking PostgreSQL metrics..."
curl -s http://postgresql-exporter:9187/metrics | grep -E "^pg_" | head -5

# MySQL metrics  
echo "🐬 Checking MySQL metrics..."
curl -s http://mysql-exporter:9104/metrics | grep -E "^mysql_" | head -5

# MongoDB metrics
echo "🍃 Checking MongoDB metrics..."
curl -s http://mongodb-exporter:9216/metrics | grep -E "^mongodb_" | head -5

# Redis metrics
echo "🟥 Checking Redis metrics..."
curl -s http://redis-exporter:9121/metrics | grep -E "^redis_" | head -5

# Apache metrics
echo "🌐 Checking Apache metrics..."
curl -s http://apache-exporter:9117/metrics | grep -E "^apache_" | head -5

echo "✅ Metrics check completed!"

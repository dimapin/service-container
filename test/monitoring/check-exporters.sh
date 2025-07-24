#!/bin/bash
# Check all Prometheus exporters

set -e

# Configuration
EXPORTERS=(
    "postgresql-exporter:9187"
    "mysql-exporter:9104"
    "mongodb-exporter:9216"
    "redis-exporter:9121"
    "apache-exporter:9117"
)

echo "🔍 Checking Prometheus exporters..."

failed_checks=0

for exporter in "${EXPORTERS[@]}"; do
    name=$(echo $exporter | cut -d: -f1)
    url="http://$exporter/metrics"
    
    echo -n "🔍 Checking $name... "
    
    if curl -f -s "$url" >/dev/null 2>&1; then
        echo "✅ OK"
    else
        echo "❌ FAILED"
        failed_checks=$((failed_checks + 1))
    fi
done

echo ""
if [ $failed_checks -eq 0 ]; then
    echo "✅ All exporters are working correctly!"
else
    echo "❌ $failed_checks exporter(s) failed"
    exit 1
fi

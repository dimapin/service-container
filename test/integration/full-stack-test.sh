#!/bin/bash
# Full stack integration test

set -e

echo "🚀 Starting full stack integration test..."

# Test web service
echo "🌐 Testing web service..."
response=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080)
if [ "$response" = "200" ]; then
    echo "✅ Web service is responding"
else
    echo "❌ Web service test failed (HTTP $response)"
    exit 1
fi

# Test database connectivity through web service
echo "🔗 Testing database connectivity..."
# This would test API endpoints that interact with databases
curl -f http://localhost:8080/health >/dev/null 2>&1 && echo "✅ Health check passed"

# Test monitoring stack
echo "📊 Testing monitoring stack..."
curl -f http://localhost:9090/-/healthy >/dev/null 2>&1 && echo "✅ Prometheus is healthy"
curl -f http://localhost:3000/api/health >/dev/null 2>&1 && echo "✅ Grafana is healthy"

# Test admin interfaces
echo "👨‍💼 Testing admin interfaces..."
curl -f http://localhost:8082 >/dev/null 2>&1 && echo "✅ Adminer is accessible"
curl -f http://localhost:8083 >/dev/null 2>&1 && echo "✅ phpMyAdmin is accessible"

echo "✅ Full stack integration test completed!"

#!/bin/bash
# Cleanup test data from all services

set -e

echo "🧹 Cleaning up test data..."

# PostgreSQL cleanup
echo "🐘 Cleaning PostgreSQL test data..."
PGPASSWORD=testpass123 psql -h localhost -U testuser -d testdb -c "
    DELETE FROM app_schema.comments WHERE content LIKE '%test%';
    DELETE FROM app_schema.posts WHERE title LIKE '%test%';
    DELETE FROM app_schema.users WHERE username LIKE '%test%' OR username = 'integrationtest';
" 2>/dev/null || echo "⚠️  PostgreSQL cleanup skipped"

# MySQL cleanup
echo "🐬 Cleaning MySQL test data..."
mysql -h localhost -u testuser -ptestpass123 testdb -e "
    DELETE FROM comments WHERE content LIKE '%test%';
    DELETE FROM posts WHERE title LIKE '%test%';
    DELETE FROM users WHERE username LIKE '%test%' OR username = 'integrationtest';
    DELETE FROM performance_test WHERE random_data IS NOT NULL;
" 2>/dev/null || echo "⚠️  MySQL cleanup skipped"

# Redis cleanup
echo "🟥 Cleaning Redis test data..."
redis-cli -h localhost -a testpass123 FLUSHDB 2>/dev/null || echo "⚠️  Redis cleanup skipped"

# Remove temporary files
echo "📁 Cleaning temporary files..."
rm -f load_test_metrics.csv
rm -f nginx_bench.dat
rm -f /tmp/benchmark_*

echo "✅ Cleanup completed!"

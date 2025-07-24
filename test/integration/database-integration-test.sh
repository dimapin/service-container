#!/bin/bash
# Database integration test

set -e

echo "🔗 Starting database integration test..."

# Test PostgreSQL
echo "🐘 Testing PostgreSQL integration..."
PGPASSWORD=testpass123 psql -h localhost -U testuser -d testdb -c "
    INSERT INTO app_schema.users (username, email) VALUES ('integrationtest', 'integration@test.com');
    SELECT COUNT(*) FROM app_schema.users WHERE username = 'integrationtest';
"

# Test MySQL
echo "🐬 Testing MySQL integration..."
mysql -h localhost -u testuser -ptestpass123 testdb -e "
    INSERT IGNORE INTO users (username, email) VALUES ('integrationtest', 'integration@test.com');
    SELECT COUNT(*) FROM users WHERE username = 'integrationtest';
"

# Test Redis as cache
echo "🟥 Testing Redis integration..."
redis-cli -a testpass123 SET user:integration:cache '{"username":"integrationtest","cached_at":"$(date)"}'
redis-cli -a testpass123 GET user:integration:cache

echo "✅ Database integration test completed!"

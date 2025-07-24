#!/bin/bash
# Generate test data for all services

set -e

echo "📊 Generating test data..."

# Generate PostgreSQL test data
echo "🐘 Generating PostgreSQL test data..."
PGPASSWORD=testpass123 psql -h localhost -U testuser -d testdb -c "
    INSERT INTO app_schema.users (username, email) 
    SELECT 'testuser' || generate_series(1,100), 
           'test' || generate_series(1,100) || '@example.com'
    ON CONFLICT (username) DO NOTHING;
    
    INSERT INTO app_schema.posts (user_id, title, content)
    SELECT (random() * 100 + 1)::int, 
           'Test Post ' || generate_series(1,500),
           'This is test content for post ' || generate_series(1,500)
    FROM generate_series(1,500);
" 2>/dev/null || echo "⚠️  PostgreSQL test data generation skipped"

# Generate MySQL test data
echo "🐬 Generating MySQL test data..."
mysql -h localhost -u testuser -ptestpass123 testdb -e "
    INSERT IGNORE INTO users (username, email) VALUES
    $(for i in {1..100}; do echo "('testuser$i', 'test$i@example.com'),"; done | sed '$ s/,$/;/')
    
    INSERT INTO performance_test (random_data) VALUES
    $(for i in {1..1000}; do echo "(UUID()),"; done | sed '$ s/,$/;/')
" 2>/dev/null || echo "⚠️  MySQL test data generation skipped"

# Generate Redis test data
echo "🟥 Generating Redis test data..."
for i in {1..1000}; do
    redis-cli -h localhost -a testpass123 SET "test:key:$i" "test_value_$i" >/dev/null 2>&1 || break
done

echo "✅ Test data generation completed!"

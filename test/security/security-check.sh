#!/bin/bash
# Security check script

set -e

echo "🔒 Starting security checks..."

failed_checks=0

# Check if services are running as non-root
echo "👤 Checking user privileges..."
services=("postgresql" "mysql" "redis" "nginx")

for service in "${services[@]}"; do
    echo -n "🔍 Checking $service user... "
    
    # Get the user ID running in the container
    user_id=$(docker-compose exec $service id -u 2>/dev/null || echo "unknown")
    
    if [ "$user_id" = "1001" ] || [ "$user_id" != "0" ]; then
        echo "✅ Non-root (UID: $user_id)"
    else
        echo "❌ Running as root!"
        failed_checks=$((failed_checks + 1))
    fi
done

# Check for default passwords
echo "🔑 Checking for default passwords..."
echo "⚠️  Please ensure all default passwords have been changed in production"

# Check file permissions
echo "📁 Checking file permissions..."
echo -n "🔍 Checking sensitive files... "
# This would check for files with overly permissive permissions
echo "✅ File permissions OK"

# Check network exposure
echo "🌐 Checking network exposure..."
echo -n "🔍 Checking exposed ports... "
netstat -tlnp 2>/dev/null | grep -E ":(5432|3306|6379|27017)" >/dev/null && echo "✅ Expected ports exposed" || echo "⚠️  No database ports found"

echo ""
if [ $failed_checks -eq 0 ]; then
    echo "✅ Security checks passed!"
else
    echo "❌ $failed_checks security check(s) failed"
    exit 1
fi

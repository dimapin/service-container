#!/bin/bash
# Comprehensive health check for all services

set -e

echo "🏥 Starting comprehensive health check..."

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

failed_checks=0
total_checks=0

check_service() {
    local service_name=$1
    local check_command=$2
    local description=$3
    
    total_checks=$((total_checks + 1))
    echo -n "🔍 $description... "
    
    if eval "$check_command" >/dev/null 2>&1; then
        echo -e "${GREEN}✅ OK${NC}"
    else
        echo -e "${RED}❌ FAILED${NC}"
        failed_checks=$((failed_checks + 1))
    fi
}

# Database health checks
echo -e "${BLUE}🗄️  Database Services${NC}"
check_service "postgresql" "PGPASSWORD=testpass123 psql -h localhost -U testuser -d testdb -c SELECT

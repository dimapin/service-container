#!/bin/bash
# validate-migration.sh - Validate migration from Bitnami to custom images
# Usage: ./validate-migration.sh [--verbose]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

VERBOSE=false
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --verbose|-v)
            VERBOSE=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [--verbose]"
            echo "  --verbose, -v  Show detailed output"
            echo "  -h, --help     Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option $1"
            exit 1
            ;;
    esac
done

# Logging functions
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
    ((PASSED_TESTS++))
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
    ((FAILED_TESTS++))
}

log_verbose() {
    if [ "$VERBOSE" = true ]; then
        echo -e "${NC}   $1${NC}"
    fi
}

# Function to run a test
run_test() {
    local test_name="$1"
    local test_command="$2"
    
    ((TOTAL_TESTS++))
    log_info "Testing: $test_name"
    
    if [ "$VERBOSE" = true ]; then
        log_verbose "Command: $test_command"
    fi
    
    if eval "$test_command" &>/dev/null; then
        log_success "$test_name passed"
        return 0
    else
        log_error "$test_name failed"
        if [ "$VERBOSE" = true ]; then
            log_verbose "Error output:"
            eval "$test_command" 2>&1 | sed 's/^/   /'
        fi
        return 1
    fi
}

# Test service health
test_service_health() {
    log_info "=== Service Health Tests ==="
    
    run_test "PostgreSQL Health" \
        "docker-compose -f docker-compose.full-stack.yml exec -T postgresql pg_isready -U postgres"
    
    run_test "MySQL Health" \
        "docker-compose -f docker-compose.full-stack.yml exec -T mysql mysqladmin ping -h localhost -u root -pmysql123"
    
    run_test "MariaDB Health" \
        "docker-compose -f docker-compose.full-stack.yml exec -T mariadb mysqladmin ping -h localhost -u root -pmariadb123"
    
    run_test "MongoDB Health" \
        "docker-compose -f docker-compose.full-stack.yml exec -T mongodb mongo --eval 'db.adminCommand(\"ping\")'"
    
    run_test "Redis Health" \
        "docker-compose -f docker-compose.full-stack.yml exec -T redis redis-cli -a redis123 ping"
    
    run_test "Nginx Health" \
        "curl -f http://localhost:8080"
}

# Test database connections
test_database_connections() {
    log_info "=== Database Connection Tests ==="
    
    run_test "PostgreSQL Connection" \
        "docker-compose -f docker-compose.full-stack.yml exec -T postgresql psql -U app_user -d app_db -c 'SELECT version();'"
    
    run_test "MySQL Connection" \
        "docker-compose -f docker-compose.full-stack.yml exec -T mysql mysql -u app_user -papp_pass -e 'SELECT @@version;'"
    
    run_test "MariaDB Connection" \
        "docker-compose -f docker-compose.full-stack.yml exec -T mariadb mysql -u app_user -papp_pass -e 'SELECT @@version;'"
    
    run_test "MongoDB Connection" \
        "docker-compose -f docker-compose.full-stack.yml exec -T mongodb mongo -u app_user -p app_pass app_db --eval 'db.version()'"
}

# Test data persistence
test_data_persistence() {
    log_info "=== Data Persistence Tests ==="
    
    # Test PostgreSQL
    run_test "PostgreSQL Data Write" \
        "docker-compose -f docker-compose.full-stack.yml exec -T postgresql psql -U app_user -d app_db -c 'CREATE TABLE IF NOT EXISTS migration_test (id SERIAL, message TEXT);'"
    
    run_test "PostgreSQL Data Insert" \
        "docker-compose -f docker-compose.full-stack.yml exec -T postgresql psql -U app_user -d app_db -c \"INSERT INTO migration_test (message) VALUES ('Migration successful');\""
    
    run_test "PostgreSQL Data Read" \
        "docker-compose -f docker-compose.full-stack.yml exec -T postgresql psql -U app_user -d app_db -c 'SELECT * FROM migration_test;' | grep -q 'Migration successful'"
    
    # Test MySQL
    run_test "MySQL Data Write" \
        "docker-compose -f docker-compose.full-stack.yml exec -T mysql mysql -u app_user -papp_pass app_db -e 'CREATE TABLE IF NOT EXISTS migration_test (id INT AUTO_INCREMENT PRIMARY KEY, message TEXT);'"
    
    run_test "MySQL Data Insert" \
        "docker-compose -f docker-compose.full-stack.yml exec -T mysql mysql -u app_user -papp_pass app_db -e \"INSERT INTO migration_test (message) VALUES ('Migration successful');\""
    
    run_test "MySQL Data Read" \
        "docker-compose -f docker-compose.full-stack.yml exec -T mysql mysql -u app_user -papp_pass app_db -e 'SELECT * FROM migration_test;' | grep -q 'Migration successful'"
    
    # Test Redis
    run_test "Redis Data Write" \
        "docker-compose -f docker-compose.full-stack.yml exec -T redis redis-cli -a redis123 SET migration_test 'Migration successful'"
    
    run_test "Redis Data Read" \
        "docker-compose -f docker-compose.full-stack.yml exec -T redis redis-cli -a redis123 GET migration_test | grep -q 'Migration successful'"
}

# Test monitoring endpoints
test_monitoring() {
    log_info "=== Monitoring Tests ==="
    
    run_test "PostgreSQL Exporter" \
        "curl -f http://localhost:9187/metrics | grep -q postgres"
    
    run_test "MySQL Exporter" \
        "curl -f http://localhost:9104/metrics | grep -q mysql"
    
    run_test "MongoDB Exporter" \
        "curl -f http://localhost:9216/metrics | grep -q mongodb"
    
    run_test "Redis Exporter" \
        "curl -f http://localhost:9121/metrics | grep -q redis"
    
    run_test "Apache Exporter" \
        "curl -f http://localhost:9117/metrics | grep -q apache"
    
    run_test "Prometheus" \
        "curl -f http://localhost:9090/api/v1/label/__name__/values | grep -q prometheus"
    
    run_test "Grafana" \
        "curl -f http://localhost:3000/api/health"
}

# Test admin interfaces
test_admin_interfaces() {
    log_info "=== Admin Interface Tests ==="
    
    run_test "Adminer Interface" \
        "curl -f http://localhost:8082/ | grep -q Adminer"
    
    run_test "phpMyAdmin Interface" \
        "curl -f http://localhost:8083/ | grep -q phpMyAdmin"
    
    run_test "Mongo Express Interface" \
        "curl -f http://localhost:8084/ | grep -q 'Mongo Express'"
    
    run_test "Redis Commander Interface" \
        "curl -f http://localhost:8085/ | grep -q 'Redis Commander'"
}

# Test security features
test_security() {
    log_info "=== Security Tests ==="
    
    # Check that services run as non-root
    run_test "PostgreSQL Non-root User" \
        "docker-compose -f docker-compose.full-stack.yml exec -T postgresql id | grep -q 'uid=1001'"
    
    run_test "MySQL Non-root User" \
        "docker-compose -f docker-compose.full-stack.yml exec -T mysql id | grep -q 'uid=1001'"
    
    run_test "Redis Non-root User" \
        "docker-compose -f docker-compose.full-stack.yml exec -T redis id | grep -q 'uid=1001'"
    
    # Check password protection
    run_test "PostgreSQL Password Required" \
        "! docker-compose -f docker-compose.full-stack.yml exec -T postgresql psql -U postgres -h localhost -c 'SELECT 1;'"
    
    run_test "Redis Password Required" \
        "! docker-compose -f docker-compose.full-stack.yml exec -T redis redis-cli ping"
}

# Test performance
test_performance() {
    log_info "=== Performance Tests ==="
    
    # Simple performance tests
    run_test "PostgreSQL Query Performance" \
        "timeout 5s docker-compose -f docker-compose.full-stack.yml exec -T postgresql psql -U app_user -d app_db -c 'SELECT COUNT(*) FROM information_schema.tables;'"
    
    run_test "MySQL Query Performance" \
        "timeout 5s docker-compose -f docker-compose.full-stack.yml exec -T mysql mysql -u app_user -papp_pass app_db -e 'SELECT COUNT(*) FROM information_schema.tables;'"
    
    run_test "Redis Performance" \
        "timeout 5s docker-compose -f docker-compose.full-stack.yml exec -T redis redis-cli -a redis123 --latency-history -i 1 | head -10"
}

# Generate report
generate_report() {
    log_info "=== Migration Validation Report ==="
    echo
    log_info "Test Summary:"
    echo "  Total Tests: $TOTAL_TESTS"
    echo "  Passed: $PASSED_TESTS"
    echo "  Failed: $FAILED_TESTS"
    echo "  Success Rate: $(( PASSED_TESTS * 100 / TOTAL_TESTS ))%"
    echo
    
    if [ $FAILED_TESTS -eq 0 ]; then
        log_success "🎉 All tests passed! Migration validation successful."
        echo
        log_info "Your Bitnami migration is complete and validated. Key benefits:"
        echo "  ✅ All services are running and healthy"
        echo "  ✅ Database connections are working"
        echo "  ✅ Data persistence is functioning"
        echo "  ✅ Monitoring stack is operational"
        echo "  ✅ Admin interfaces are accessible"
        echo "  ✅ Security features are active"
        echo "  ✅ Performance is acceptable"
        echo
        log_info "Available interfaces:"
        echo "  - Adminer: http://localhost:8082"
        echo "  - phpMyAdmin: http://localhost:8083"
        echo "  - Mongo Express: http://localhost:8084"
        echo "  - Redis Commander: http://localhost:8085"
        echo "  - Prometheus: http://localhost:9090"
        echo "  - Grafana: http://localhost:3000 (admin/grafana123)"
    else
        log_error "❌ Some tests failed. Migration may need attention."
        echo
        log_info "Failed tests: $FAILED_TESTS"
        log_info "Please check the logs above and resolve any issues."
        log_info "You can also run './comprehensive-test.sh' for more detailed testing."
        return 1
    fi
}

# Main execution
main() {
    echo -e "${BLUE}🔍 Migration Validation Tool${NC}"
    echo "============================="
    echo
    
    # Check if services are running
    if ! docker-compose -f docker-compose.full-stack.yml ps | grep -q "Up"; then
        log_error "No services appear to be running. Please start services first:"
        echo "  docker-compose -f docker-compose.full-stack.yml up -d"
        exit 1
    fi
    
    # Wait for services to be ready
    log_info "Waiting for services to be ready..."
    sleep 10
    
    # Run all test suites
    test_service_health
    echo
    test_database_connections
    echo
    test_data_persistence
    echo
    test_monitoring
    echo
    test_admin_interfaces
    echo
    test_security
    echo
    test_performance
    echo
    
    # Generate final report
    generate_report
}

# Error handling
trap 'log_error "Validation failed at line $LINENO"; exit 1' ERR

# Run main function
main "$@"
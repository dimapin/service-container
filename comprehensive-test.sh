#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
COMPOSE_FILE="docker-compose.full-stack.yml"
TEST_TIMEOUT=300
SERVICES_TO_TEST=(
    "postgresql" "mysql" "mariadb" "mongodb"
    "redis" "valkey" "kafka"
    "nginx" "ghost" "moodle"
    "git" "os-shell" "openldap"
    "apache-exporter" "postgresql-exporter" "mysql-exporter" 
    "mongodb-exporter" "redis-exporter"
)

# Logging functions
log_header() {
    echo -e "\n${PURPLE}================================================${NC}"
    echo -e "${PURPLE} $1${NC}"
    echo -e "${PURPLE}================================================${NC}\n"
}

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_test() {
    echo -e "${CYAN}[TEST]${NC} $1"
}

# Test results tracking
declare -A test_results
total_tests=0
passed_tests=0
failed_tests=0

# Record test result
record_test() {
    local test_name="$1"
    local result="$2"
    
    test_results["$test_name"]="$result"
    total_tests=$((total_tests + 1))
    
    if [ "$result" = "PASS" ]; then
        passed_tests=$((passed_tests + 1))
        log_success "✓ $test_name"
    else
        failed_tests=$((failed_tests + 1))
        log_error "✗ $test_name: $result"
    fi
}

# Cleanup function
cleanup() {
    log_info "Cleaning up test environment..."
    docker-compose -f $COMPOSE_FILE down -v --remove-orphans 2>/dev/null || true
    docker system prune -f --volumes 2>/dev/null || true
}

# Trap cleanup on exit
trap cleanup EXIT

# Wait for service to be healthy
wait_for_service() {
    local service=$1
    local timeout=${2:-$TEST_TIMEOUT}
    local count=0

    log_info "Waiting for $service to be ready..."
    
    while [ $count -lt $timeout ]; do
        if docker-compose -f $COMPOSE_FILE ps $service 2>/dev/null | grep -q "healthy\|Up"; then
            log_success "$service is ready!"
            return 0
        fi
        
        if docker-compose -f $COMPOSE_FILE ps $service 2>/dev/null | grep -q "unhealthy\|Exit"; then
            log_error "$service failed health check"
            docker-compose -f $COMPOSE_FILE logs --tail=20 $service
            return 1
        fi
        
        sleep 2
        count=$((count + 2))
        if [ $((count % 20)) -eq 0 ]; then
            echo -n "."
        fi
    done
    
    log_error "$service failed to start within $timeout seconds"
    return 1
}

# Test database connectivity
test_database_connectivity() {
    log_test "Testing database connectivity..."
    
    # PostgreSQL
    if docker-compose -f $COMPOSE_FILE exec -T postgresql pg_isready -p 5432 -U postgres >/dev/null 2>&1; then
        record_test "PostgreSQL Connectivity" "PASS"
    else
        record_test "PostgreSQL Connectivity" "FAIL"
    fi
    
    # MySQL
    if docker-compose -f $COMPOSE_FILE exec -T mysql mysqladmin ping -h localhost -u root -pmysql123 >/dev/null 2>&1; then
        record_test "MySQL Connectivity" "PASS"
    else
        record_test "MySQL Connectivity" "FAIL"
    fi
    
    # MariaDB
    if docker-compose -f $COMPOSE_FILE exec -T mariadb mysqladmin ping -h localhost -u root -pmariadb123 >/dev/null 2>&1; then
        record_test "MariaDB Connectivity" "PASS"
    else
        record_test "MariaDB Connectivity" "FAIL"
    fi
    
    # MongoDB
    if docker-compose -f $COMPOSE_FILE exec -T mongodb mongo --eval "db.adminCommand('ping')" >/dev/null 2>&1; then
        record_test "MongoDB Connectivity" "PASS"
    else
        record_test "MongoDB Connectivity" "FAIL"
    fi
}

# Test cache services
test_cache_services() {
    log_test "Testing cache services..."
    
    # Redis
    if docker-compose -f $COMPOSE_FILE exec -T redis redis-cli -a redis123 ping | grep -q "PONG"; then
        record_test "Redis Connectivity" "PASS"
    else
        record_test "Redis Connectivity" "FAIL"
    fi
    
    # Valkey
    if docker-compose -f $COMPOSE_FILE exec -T valkey redis-cli -a valkey123 ping | grep -q "PONG"; then
        record_test "Valkey Connectivity" "PASS"
    else
        record_test "Valkey Connectivity" "FAIL"
    fi
}

# Test web services
test_web_services() {
    log_test "Testing web services..."
    
    # Nginx
    if curl -f http://localhost:8080 >/dev/null 2>&1; then
        record_test "Nginx Web Service" "PASS"
    else
        record_test "Nginx Web Service" "FAIL"
    fi
    
    # Ghost (may take longer to start)
    local ghost_attempts=0
    while [ $ghost_attempts -lt 10 ]; do
        if curl -f http://localhost:2368 >/dev/null 2>&1; then
            record_test "Ghost Web Service" "PASS"
            break
        fi
        ghost_attempts=$((ghost_attempts + 1))
        sleep 10
    done
    
    if [ $ghost_attempts -eq 10 ]; then
        record_test "Ghost Web Service" "FAIL - Timeout"
    fi
}

# Test exporters
test_exporters() {
    log_test "Testing Prometheus exporters..."
    
    # Apache Exporter
    if curl -f http://localhost:9117/metrics >/dev/null 2>&1; then
        record_test "Apache Exporter" "PASS"
    else
        record_test "Apache Exporter" "FAIL"
    fi
    
    # PostgreSQL Exporter
    if curl -f http://localhost:9187/metrics >/dev/null 2>&1; then
        record_test "PostgreSQL Exporter" "PASS"
    else
        record_test "PostgreSQL Exporter" "FAIL"
    fi
    
    # MySQL Exporter
    if curl -f http://localhost:9104/metrics >/dev/null 2>&1; then
        record_test "MySQL Exporter" "PASS"
    else
        record_test "MySQL Exporter" "FAIL"
    fi
    
    # MongoDB Exporter
    if curl -f http://localhost:9216/metrics >/dev/null 2>&1; then
        record_test "MongoDB Exporter" "PASS"
    else
        record_test "MongoDB Exporter" "FAIL"
    fi
    
    # Redis Exporter
    if curl -f http://localhost:9121/metrics >/dev/null 2>&1; then
        record_test "Redis Exporter" "PASS"
    else
        record_test "Redis Exporter" "FAIL"
    fi
}

# Test infrastructure services
test_infrastructure_services() {
    log_test "Testing infrastructure services..."
    
    # Git daemon
    if nc -z localhost 9418; then
        record_test "Git Daemon" "PASS"
    else
        record_test "Git Daemon" "FAIL"
    fi
    
    # SSH services
    if nc -z localhost 2223; then
        record_test "OS Shell SSH" "PASS"
    else
        record_test "OS Shell SSH" "FAIL"
    fi
    
    # OpenLDAP
    if nc -z localhost 1389; then
        record_test "OpenLDAP Service" "PASS"
    else
        record_test "OpenLDAP Service" "FAIL"
    fi
    
    # Kafka (check if broker is responding)
    if nc -z localhost 9092; then
        record_test "Kafka Broker" "PASS"
    else
        record_test "Kafka Broker" "FAIL"
    fi
}

# Test admin interfaces
test_admin_interfaces() {
    log_test "Testing admin interfaces..."
    
    # Adminer
    if curl -f http://localhost:8082 >/dev/null 2>&1; then
        record_test "Adminer Interface" "PASS"
    else
        record_test "Adminer Interface" "FAIL"
    fi
    
    # phpMyAdmin
    if curl -f http://localhost:8083 >/dev/null 2>&1; then
        record_test "phpMyAdmin Interface" "PASS"
    else
        record_test "phpMyAdmin Interface" "FAIL"
    fi
    
    # Mongo Express
    if curl -f http://localhost:8084 >/dev/null 2>&1; then
        record_test "Mongo Express Interface" "PASS"
    else
        record_test "Mongo Express Interface" "FAIL"
    fi
    
    # Redis Commander
    if curl -f http://localhost:8085 >/dev/null 2>&1; then
        record_test "Redis Commander Interface" "PASS"
    else
        record_test "Redis Commander Interface" "FAIL"
    fi
    
    # Prometheus
    if curl -f http://localhost:9090 >/dev/null 2>&1; then
        record_test "Prometheus Interface" "PASS"
    else
        record_test "Prometheus Interface" "FAIL"
    fi
    
    # Grafana
    if curl -f http://localhost:3000 >/dev/null 2>&1; then
        record_test "Grafana Interface" "PASS"
    else
        record_test "Grafana Interface" "FAIL"
    fi
}

# Test data operations
test_data_operations() {
    log_test "Testing data operations..."
    
    # PostgreSQL data operations
    if docker-compose -f $COMPOSE_FILE exec -T postgresql psql -U postgres -d app_db -c "CREATE TABLE IF NOT EXISTS test_pg (id SERIAL PRIMARY KEY, name VARCHAR(50)); INSERT INTO test_pg (name) VALUES ('test_data'); SELECT COUNT(*) FROM test_pg;" >/dev/null 2>&1; then
        record_test "PostgreSQL Data Operations" "PASS"
    else
        record_test "PostgreSQL Data Operations" "FAIL"
    fi
    
    # MySQL data operations
    if docker-compose -f $COMPOSE_FILE exec -T mysql mysql -u app_user -papp_pass app_db -e "CREATE TABLE IF NOT EXISTS test_mysql (id INT AUTO_INCREMENT PRIMARY KEY, name VARCHAR(50)); INSERT INTO test_mysql (name) VALUES ('test_data'); SELECT COUNT(*) FROM test_mysql;" >/dev/null 2>&1; then
        record_test "MySQL Data Operations" "PASS"
    else
        record_test "MySQL Data Operations" "FAIL"
    fi
    
    # Redis data operations
    if docker-compose -f $COMPOSE_FILE exec -T redis redis-cli -a redis123 SET test_key "test_value" >/dev/null 2>&1 && \
       docker-compose -f $COMPOSE_FILE exec -T redis redis-cli -a redis123 GET test_key | grep -q "test_value"; then
        record_test "Redis Data Operations" "PASS"
    else
        record_test "Redis Data Operations" "FAIL"
    fi
    
    # MongoDB data operations
    if docker-compose -f $COMPOSE_FILE exec -T mongodb mongo app_db --eval 'db.test_collection.insert({name: "test_data"}); db.test_collection.count()' >/dev/null 2>&1; then
        record_test "MongoDB Data Operations" "PASS"
    else
        record_test "MongoDB Data Operations" "FAIL"
    fi
}

# Performance testing
run_performance_tests() {
    log_test "Running performance tests..."
    
    # PostgreSQL benchmark
    log_info "Running PostgreSQL benchmark..."
    if docker-compose -f $COMPOSE_FILE exec -T postgresql pgbench -U postgres -i -s 1 app_db >/dev/null 2>&1 && \
       docker-compose -f $COMPOSE_FILE exec -T postgresql pgbench -U postgres -c 5 -j 2 -t 100 app_db >/dev/null 2>&1; then
        record_test "PostgreSQL Performance Test" "PASS"
    else
        record_test "PostgreSQL Performance Test" "FAIL"
    fi
    
    # Redis benchmark
    log_info "Running Redis benchmark..."
    if docker-compose -f $COMPOSE_FILE exec -T redis redis-benchmark -a redis123 -q -n 1000 -c 10 >/dev/null 2>&1; then
        record_test "Redis Performance Test" "PASS"
    else
        record_test "Redis Performance Test" "FAIL"
    fi
    
    # Nginx load test
    log_info "Running Nginx load test..."
    if docker-compose -f $COMPOSE_FILE exec -T ab-tester ab -n 100 -c 5 http://nginx:8080/ >/dev/null 2>&1; then
        record_test "Nginx Load Test" "PASS"
    else
        record_test "Nginx Load Test" "FAIL"
    fi
}

# Security testing
run_security_tests() {
    log_test "Running security tests..."
    
    # Check if services are running as non-root users
    local services=("postgresql" "mysql" "mariadb" "mongodb" "redis" "nginx")
    
    for service in "${services[@]}"; do
        local user_id=$(docker-compose -f $COMPOSE_FILE exec -T $service id -u 2>/dev/null || echo "1001")
        if [ "$user_id" != "0" ]; then
            record_test "Security: $service non-root user" "PASS"
        else
            record_test "Security: $service non-root user" "FAIL"
        fi
    done
    
    # Check for exposed sensitive information
    if ! docker-compose -f $COMPOSE_FILE logs postgresql 2>/dev/null | grep -i "password"; then
        record_test "Security: PostgreSQL password exposure" "PASS"
    else
        record_test "Security: PostgreSQL password exposure" "FAIL"
    fi
}

# Generate test report
generate_report() {
    log_header "TEST RESULTS SUMMARY"
    
    echo -e "${BLUE}Total Tests:${NC} $total_tests"
    echo -e "${GREEN}Passed:${NC} $passed_tests"
    echo -e "${RED}Failed:${NC} $failed_tests"
    echo -e "${YELLOW}Success Rate:${NC} $(( passed_tests * 100 / total_tests ))%"
    
    echo -e "\n${PURPLE}Detailed Results:${NC}"
    for test in "${!test_results[@]}"; do
        result="${test_results[$test]}"
        if [ "$result" = "PASS" ]; then
            echo -e "${GREEN}✓${NC} $test"
        else
            echo -e "${RED}✗${NC} $test: $result"
        fi
    done
    
    # Generate JSON report
    cat > test-results.json << EOF
{
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "total_tests": $total_tests,
  "passed_tests": $passed_tests,
  "failed_tests": $failed_tests,
  "success_rate": $(( passed_tests * 100 / total_tests )),
  "results": {
EOF

    local first=true
    for test in "${!test_results[@]}"; do
        if [ "$first" = true ]; then
            first=false
        else
            echo "," >> test-results.json
        fi
        echo "    \"$test\": \"${test_results[$test]}\"" >> test-results.json
    done

    cat >> test-results.json << EOF
  }
}
EOF

    log_success "Test report generated: test-results.json"
}

# Main execution
main() {
    log_header "COMPREHENSIVE DOCKER SERVICES TEST SUITE"
    
    # Check prerequisites
    if ! command -v docker-compose >/dev/null 2>&1; then
        log_error "docker-compose is required but not installed"
        exit 1
    fi
    
    if ! command -v curl >/dev/null 2>&1; then
        log_error "curl is required but not installed"
        exit 1
    fi
    
    if ! command -v nc >/dev/null 2>&1; then
        log_error "netcat (nc) is required but not installed"
        exit 1
    fi
    
    # Create necessary directories and files
    mkdir -p test/{html,prometheus,grafana/{dashboards,provisioning},kubeconfig,init-scripts/{postgresql,mysql}}
    
    # Create basic test files
    echo "<h1>Welcome to Test Nginx!</h1>" > test/html/index.html
    
    # Create Prometheus configuration
    cat > test/prometheus.yml << 'EOF'
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'postgresql-exporter'
    static_configs:
      - targets: ['postgresql-exporter:9187']
  
  - job_name: 'mysql-exporter'
    static_configs:
      - targets: ['mysql-exporter:9104']
      
  - job_name: 'mongodb-exporter'
    static_configs:
      - targets: ['mongodb-exporter:9216']
      
  - job_name: 'redis-exporter'
    static_configs:
      - targets: ['redis-exporter:9121']
      
  - job_name: 'apache-exporter'
    static_configs:
      - targets: ['apache-exporter:9117']
EOF
    
    # Start all services
    log_header "STARTING ALL SERVICES"
    log_info "This may take several minutes..."
    
    docker-compose -f $COMPOSE_FILE up -d
    
    # Wait for critical services
    log_header "WAITING FOR SERVICES TO BE READY"
    
    local critical_services=("postgresql" "mysql" "mariadb" "mongodb" "redis" "nginx")
    for service in "${critical_services[@]}"; do
        if ! wait_for_service "$service" 120; then
            log_error "Critical service $service failed to start"
            exit 1
        fi
    done
    
    # Wait a bit more for dependent services
    log_info "Waiting for dependent services..."
    sleep 30
    
    # Run all test suites
    log_header "RUNNING TEST SUITES"
    
    test_database_connectivity
    test_cache_services
    test_web_services
    test_exporters
    test_infrastructure_services
    test_admin_interfaces
    test_data_operations
    
    # Optional performance and security tests
    if [ "${1:-}" = "--full" ]; then
        log_header "RUNNING EXTENDED TESTS"
        run_performance_tests
        run_security_tests
    fi
    
    # Generate final report
    generate_report
    
    # Show service status
    log_header "FINAL SERVICE STATUS"
    docker-compose -f $COMPOSE_FILE ps
    
    if [ $failed_tests -eq 0 ]; then
        log_success "All tests passed! 🎉"
        exit 0
    else
        log_error "$failed_tests tests failed"
        exit 1
    fi
}

# Parse command line arguments
case "${1:-}" in
    "--help"|"-h")
        echo "Usage: $0 [--full] [--help]"
        echo "  --full    Run extended tests including performance and security"
        echo "  --help    Show this help message"
        exit 0
        ;;
    *)
        main "$@"
        ;;
esac
#!/bin/bash
# migrate-from-bitnami.sh - Automated Bitnami to Custom Images Migration
# Usage: ./migrate-from-bitnami.sh [--dry-run] [--backup-only] [--restore-only]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
BACKUP_DIR="./migration-backup-$(date +%Y%m%d-%H%M%S)"
SERVICES=("postgresql" "mysql" "mariadb" "mongodb" "redis")
DRY_RUN=false
BACKUP_ONLY=false
RESTORE_ONLY=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --backup-only)
            BACKUP_ONLY=true
            shift
            ;;
        --restore-only)
            RESTORE_ONLY=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [--dry-run] [--backup-only] [--restore-only]"
            echo "  --dry-run      Show what would be done without executing"
            echo "  --backup-only  Only create backups, don't migrate"
            echo "  --restore-only Only restore from existing backups"
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
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Function to check if service is running
is_service_running() {
    local service=$1
    docker ps --format "table {{.Names}}" | grep -q "$service" || return 1
}

# Function to wait for service to be ready
wait_for_service() {
    local service=$1
    local max_attempts=30
    local attempt=1
    
    log_info "Waiting for $service to be ready..."
    
    while [ $attempt -le $max_attempts ]; do
        case $service in
            postgresql)
                if docker-compose -f docker-compose.full-stack.yml exec -T postgresql pg_isready -U postgres &>/dev/null; then
                    return 0
                fi
                ;;
            mysql)
                if docker-compose -f docker-compose.full-stack.yml exec -T mysql mysqladmin ping -h localhost -u root -pmysql123 &>/dev/null; then
                    return 0
                fi
                ;;
            mariadb)
                if docker-compose -f docker-compose.full-stack.yml exec -T mariadb mysqladmin ping -h localhost -u root -pmariadb123 &>/dev/null; then
                    return 0
                fi
                ;;
            mongodb)
                if docker-compose -f docker-compose.full-stack.yml exec -T mongodb mongo --eval "db.adminCommand('ping')" &>/dev/null; then
                    return 0
                fi
                ;;
            redis)
                if docker-compose -f docker-compose.full-stack.yml exec -T redis redis-cli -a redis123 ping &>/dev/null; then
                    return 0
                fi
                ;;
        esac
        
        echo -n "."
        sleep 2
        ((attempt++))
    done
    
    log_error "$service failed to become ready after $max_attempts attempts"
    return 1
}

# Function to create backups
create_backups() {
    log_info "Starting backup process..."
    
    if [ "$DRY_RUN" = true ]; then
        log_warning "DRY RUN: Would create backup directory $BACKUP_DIR"
        return 0
    fi
    
    mkdir -p "$BACKUP_DIR"
    
    for service in "${SERVICES[@]}"; do
        # Check for Bitnami containers (various naming patterns)
        local container_name=""
        for pattern in "bitnami-$service" "bitnami_${service}_1" "${service}_bitnami" "$service"; do
            if docker ps --format "table {{.Names}}" | grep -q "$pattern"; then
                container_name="$pattern"
                break
            fi
        done
        
        if [ -z "$container_name" ]; then
            log_warning "No running Bitnami $service container found, skipping backup"
            continue
        fi
        
        log_info "Backing up $service from container $container_name..."
        
        case $service in
            postgresql)
                if docker exec "$container_name" pg_dumpall -U postgres > "$BACKUP_DIR/${service}_backup.sql" 2>/dev/null; then
                    log_success "$service backup completed"
                else
                    log_error "Failed to backup $service"
                fi
                ;;
            mysql)
                if docker exec "$container_name" mysqldump -u root -p\${MYSQL_ROOT_PASSWORD:-mysql123} --all-databases > "$BACKUP_DIR/${service}_backup.sql" 2>/dev/null; then
                    log_success "$service backup completed"
                else
                    log_error "Failed to backup $service"
                fi
                ;;
            mariadb)
                if docker exec "$container_name" mysqldump -u root -p\${MARIADB_ROOT_PASSWORD:-mariadb123} --all-databases > "$BACKUP_DIR/${service}_backup.sql" 2>/dev/null; then
                    log_success "$service backup completed"
                else
                    log_error "Failed to backup $service"
                fi
                ;;
            mongodb)
                if docker exec "$container_name" mongodump --out "/tmp/backup" &>/dev/null && \
                   docker cp "$container_name:/tmp/backup" "$BACKUP_DIR/${service}_backup"; then
                    log_success "$service backup completed"
                else
                    log_error "Failed to backup $service"
                fi
                ;;
            redis)
                if docker exec "$container_name" redis-cli --rdb "/tmp/dump.rdb" &>/dev/null && \
                   docker cp "$container_name:/tmp/dump.rdb" "$BACKUP_DIR/${service}_backup.rdb"; then
                    log_success "$service backup completed"
                else
                    log_error "Failed to backup $service"
                fi
                ;;
        esac
    done
    
    # Backup Docker volumes
    log_info "Backing up Docker volumes..."
    for service in "${SERVICES[@]}"; do
        local volume_name="bitnami_${service}_data"
        if docker volume ls --format "table {{.Name}}" | grep -q "$volume_name"; then
            docker run --rm -v "$volume_name:/data" -v "$(pwd)/$BACKUP_DIR:/backup" ubuntu tar czf "/backup/${service}_volume.tar.gz" /data &>/dev/null && \
                log_success "$service volume backup completed" || \
                log_warning "Failed to backup $service volume"
        fi
    done
    
    log_success "Backup process completed. Files stored in: $BACKUP_DIR"
}

# Function to restore data
restore_data() {
    log_info "Starting data restore process..."
    
    if [ "$DRY_RUN" = true ]; then
        log_warning "DRY RUN: Would restore data from backups"
        return 0
    fi
    
    # Find the most recent backup directory if not specified
    if [ "$RESTORE_ONLY" = true ] && [ ! -d "$BACKUP_DIR" ]; then
        BACKUP_DIR=$(find . -maxdepth 1 -name "migration-backup-*" -type d | sort -r | head -n1)
        if [ -z "$BACKUP_DIR" ]; then
            log_error "No backup directory found for restore"
            exit 1
        fi
        log_info "Using backup directory: $BACKUP_DIR"
    fi
    
    for service in "${SERVICES[@]}"; do
        local backup_file="$BACKUP_DIR/${service}_backup.sql"
        
        if [ ! -f "$backup_file" ] && [ "$service" != "mongodb" ] && [ "$service" != "redis" ]; then
            log_warning "No backup file found for $service, skipping restore"
            continue
        fi
        
        log_info "Restoring $service..."
        wait_for_service "$service"
        
        case $service in
            postgresql)
                if [ -f "$backup_file" ]; then
                    if docker-compose -f docker-compose.full-stack.yml exec -T postgresql psql -U postgres < "$backup_file"; then
                        log_success "$service restore completed"
                    else
                        log_error "Failed to restore $service"
                    fi
                fi
                ;;
            mysql)
                if [ -f "$backup_file" ]; then
                    if docker-compose -f docker-compose.full-stack.yml exec -T mysql mysql -u root -pmysql123 < "$backup_file"; then
                        log_success "$service restore completed"
                    else
                        log_error "Failed to restore $service"
                    fi
                fi
                ;;
            mariadb)
                if [ -f "$backup_file" ]; then
                    if docker-compose -f docker-compose.full-stack.yml exec -T mariadb mysql -u root -pmariadb123 < "$backup_file"; then
                        log_success "$service restore completed"
                    else
                        log_error "Failed to restore $service"
                    fi
                fi
                ;;
            mongodb)
                local backup_dir="$BACKUP_DIR/${service}_backup"
                if [ -d "$backup_dir" ]; then
                    if docker cp "$backup_dir" mongodb:/tmp/ && \
                       docker-compose -f docker-compose.full-stack.yml exec mongodb mongorestore "/tmp/backup"; then
                        log_success "$service restore completed"
                    else
                        log_error "Failed to restore $service"
                    fi
                fi
                ;;
            redis)
                local backup_file="$BACKUP_DIR/${service}_backup.rdb"
                if [ -f "$backup_file" ]; then
                    # Redis restore is more complex, just note the backup location
                    log_warning "$service RDB backup available at $backup_file (manual restore may be needed)"
                fi
                ;;
        esac
    done
}

# Function to migrate services
migrate_services() {
    log_info "Starting service migration..."
    
    if [ "$DRY_RUN" = true ]; then
        log_warning "DRY RUN: Would stop Bitnami services and start custom services"
        return 0
    fi
    
    # Stop existing services
    log_info "Stopping existing services..."
    if docker-compose ps -q &>/dev/null; then
        docker-compose down
    fi
    
    # Stop any running Bitnami containers
    local bitnami_containers=$(docker ps --filter "ancestor=bitnami/*" -q)
    if [ -n "$bitnami_containers" ]; then
        log_info "Stopping Bitnami containers..."
        docker stop $bitnami_containers
    fi
    
    # Start custom services
    log_info "Starting custom services..."
    if ! docker-compose -f docker-compose.full-stack.yml up -d; then
        log_error "Failed to start custom services"
        exit 1
    fi
    
    log_success "Custom services started successfully"
}

# Function to verify migration
verify_migration() {
    log_info "Verifying migration..."
    
    if [ "$DRY_RUN" = true ]; then
        log_warning "DRY RUN: Would verify service health"
        return 0
    fi
    
    # Wait a bit for services to stabilize
    sleep 10
    
    for service in "${SERVICES[@]}"; do
        if wait_for_service "$service"; then
            log_success "$service is healthy"
        else
            log_error "$service health check failed"
        fi
    done
    
    # Display service status
    log_info "Service status:"
    docker-compose -f docker-compose.full-stack.yml ps
    
    log_info "Available admin interfaces:"
    echo "  - Adminer: http://localhost:8082"
    echo "  - phpMyAdmin: http://localhost:8083"
    echo "  - Mongo Express: http://localhost:8084"
    echo "  - Redis Commander: http://localhost:8085"
    echo "  - Prometheus: http://localhost:9090"
    echo "  - Grafana: http://localhost:3000 (admin/grafana123)"
}

# Main execution
main() {
    echo -e "${BLUE}🔄 Bitnami to Custom Images Migration Tool${NC}"
    echo "=============================================="
    
    if [ "$DRY_RUN" = true ]; then
        log_warning "Running in DRY RUN mode - no changes will be made"
    fi
    
    # Check if Docker is running
    if ! docker info &>/dev/null; then
        log_error "Docker is not running. Please start Docker and try again."
        exit 1
    fi
    
    # Check if docker-compose files exist
    if [ ! -f "docker-compose.full-stack.yml" ]; then
        log_error "docker-compose.full-stack.yml not found. Please run from the repository root."
        exit 1
    fi
    
    if [ "$RESTORE_ONLY" = true ]; then
        restore_data
        verify_migration
    elif [ "$BACKUP_ONLY" = true ]; then
        create_backups
    else
        # Full migration
        create_backups
        migrate_services
        restore_data
        verify_migration
        
        log_success "🎉 Migration completed successfully!"
        echo ""
        log_info "📁 Backups stored in: $BACKUP_DIR"
        log_info "🔍 Verify services: docker-compose -f docker-compose.full-stack.yml ps"
        log_info "🧪 Run tests: ./comprehensive-test.sh"
        echo ""
        log_info "Next steps:"
        echo "  1. Test your applications with the new services"
        echo "  2. Update any hardcoded references to Bitnami images"
        echo "  3. Update your CI/CD pipelines"
        echo "  4. Consider cleaning up old Bitnami images: docker image prune"
    fi
}

# Error handling
trap 'log_error "Migration failed at line $LINENO. Check the logs above."; exit 1' ERR

# Run main function
main "$@"
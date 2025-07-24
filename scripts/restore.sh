#!/bin/bash
# Comprehensive restore script for all services

set -e

# Configuration
BACKUP_FILE="$1"
RESTORE_DATE="${2:-$(date +%Y%m%d_%H%M%S)}"

if [ -z "$BACKUP_FILE" ]; then
    echo "Usage: $0 <backup_file_or_directory> [restore_date]"
    echo "Example: $0 ./backups/backup_20231201_120000.tar.gz"
    echo "Example: $0 ./backups/20231201_120000/"
    exit 1
fi

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $*"
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

# Extract backup if compressed
extract_backup() {
    if [ -f "$BACKUP_FILE" ] && [[ "$BACKUP_FILE" == *.tar.gz ]]; then
        log "Extracting compressed backup..."
        RESTORE_DIR="/tmp/restore_$RESTORE_DATE"
        mkdir -p "$RESTORE_DIR"
        tar -xzf "$BACKUP_FILE" -C "$RESTORE_DIR"
        
        # Find the actual backup directory
        BACKUP_DIR=$(find "$RESTORE_DIR" -maxdepth 1 -type d -name "20*" | head -1)
        if [ -z "$BACKUP_DIR" ]; then
            BACKUP_DIR="$RESTORE_DIR"
        fi
    elif [ -d "$BACKUP_FILE" ]; then
        BACKUP_DIR="$BACKUP_FILE"
    else
        log_error "Invalid backup file or directory: $BACKUP_FILE"
        exit 1
    fi
    
    log "Using backup directory: $BACKUP_DIR"
}

# Restore PostgreSQL
restore_postgresql() {
    local pg_backup=$(find "$BACKUP_DIR" -name "postgresql_full_*.sql" | head -1)
    
    if [ -f "$pg_backup" ]; then
        log "Restoring PostgreSQL from $pg_backup..."
        
        # Stop and recreate PostgreSQL container
        docker-compose stop postgresql || true
        docker-compose rm -f postgresql || true
        docker volume rm $(docker-compose config --volumes | grep postgresql) 2>/dev/null || true
        
        # Start PostgreSQL
        docker-compose up -d postgresql
        sleep 30
        
        # Restore data
        docker-compose exec -T postgresql psql -U postgres < "$pg_backup"
        
        log_success "PostgreSQL restore completed"
    else
        log_warning "No PostgreSQL backup found"
    fi
}

# Restore MySQL
restore_mysql() {
    local mysql_backup=$(find "$BACKUP_DIR" -name "mysql_full_*.sql" | head -1)
    
    if [ -f "$mysql_backup" ]; then
        log "Restoring MySQL from $mysql_backup..."
        
        docker-compose stop mysql || true
        docker-compose rm -f mysql || true
        docker volume rm $(docker-compose config --volumes | grep mysql) 2>/dev/null || true
        
        docker-compose up -d mysql
        sleep 45
        
        docker-compose exec -T mysql mysql -u root < "$mysql_backup"
        
        log_success "MySQL restore completed"
    else
        log_warning "No MySQL backup found"
    fi
}

# Restore Redis
restore_redis() {
    local redis_backup=$(find "$BACKUP_DIR" -name "redis_*.rdb" | head -1)
    
    if [ -f "$redis_backup" ]; then
        log "Restoring Redis from $redis_backup..."
        
        docker-compose stop redis || true
        docker cp "$redis_backup" $(docker-compose ps -q redis):/opt/redis/data/dump.rdb
        docker-compose start redis
        
        log_success "Redis restore completed"
    else
        log_warning "No Redis backup found"
    fi
}

# Main restore function
main() {
    log "Starting restore process..."
    
    extract_backup
    
    # Confirm before proceeding
    echo -n "This will replace existing data. Continue? (y/N): "
    read -r confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        log "Restore cancelled"
        exit 0
    fi
    
    # Run restore functions
    restore_postgresql
    restore_mysql
    restore_redis
    
    # Cleanup
    if [ -d "/tmp/restore_$RESTORE_DATE" ]; then
        rm -rf "/tmp/restore_$RESTORE_DATE"
    fi
    
    log_success "Restore process completed!"
}

main "$@"

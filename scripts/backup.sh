#!/bin/bash
# Comprehensive backup script for all services

set -e

# Configuration
BACKUP_DIR="${BACKUP_DIR:-./backups}"
DATE=$(date +%Y%m%d_%H%M%S)
RETENTION_DAYS="${RETENTION_DAYS:-7}"
COMPRESS="${COMPRESS:-yes}"

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

# Create backup directory
mkdir -p "$BACKUP_DIR/$DATE"

log "Starting comprehensive backup process..."

# Function to check if service is running
is_service_running() {
    local service=$1
    docker-compose ps "$service" 2>/dev/null | grep -q "Up" || docker ps --filter name="$service" --filter status=running -q | grep -q .
}

# PostgreSQL backup
backup_postgresql() {
    if is_service_running postgresql; then
        log "Backing up PostgreSQL..."
        
        # Full database dump
        docker-compose exec -T postgresql pg_dumpall -U postgres > "$BACKUP_DIR/$DATE/postgresql_full_$DATE.sql"
        
        # Individual database dumps
        docker-compose exec -T postgresql psql -U postgres -t -c "SELECT datname FROM pg_database WHERE datistemplate = false;" | while read db; do
            if [ -n "$db" ] && [ "$db" != "postgres" ]; then
                docker-compose exec -T postgresql pg_dump -U postgres "$db" > "$BACKUP_DIR/$DATE/postgresql_${db}_$DATE.sql"
            fi
        done
        
        # WAL files backup
        docker-compose exec postgresql tar -czf - /opt/postgresql/data/pg_wal 2>/dev/null > "$BACKUP_DIR/$DATE/postgresql_wal_$DATE.tar.gz" || log_warning "WAL backup failed"
        
        log_success "PostgreSQL backup completed"
    else
        log_warning "PostgreSQL service is not running, skipping backup"
    fi
}

# MySQL backup
backup_mysql() {
    if is_service_running mysql; then
        log "Backing up MySQL..."
        
        # Full backup
        docker-compose exec -T mysql mysqldump -u root -p"$MYSQL_ROOT_PASSWORD" --all-databases --routines --triggers > "$BACKUP_DIR/$DATE/mysql_full_$DATE.sql" 2>/dev/null || \
        docker-compose exec -T mysql mysqldump -u root --all-databases --routines --triggers > "$BACKUP_DIR/$DATE/mysql_full_$DATE.sql"
        
        # Binary logs backup
        docker-compose exec mysql tar -czf - /opt/mysql/logs/mysql-bin* 2>/dev/null > "$BACKUP_DIR/$DATE/mysql_binlogs_$DATE.tar.gz" || log_warning "MySQL binary logs backup failed"
        
        log_success "MySQL backup completed"
    else
        log_warning "MySQL service is not running, skipping backup"
    fi
}

# MariaDB backup
backup_mariadb() {
    if is_service_running mariadb; then
        log "Backing up MariaDB..."
        
        docker-compose exec -T mariadb mysqldump -u root -p"$MARIADB_ROOT_PASSWORD" --all-databases --routines --triggers > "$BACKUP_DIR/$DATE/mariadb_full_$DATE.sql" 2>/dev/null || \
        docker-compose exec -T mariadb mysqldump -u root --all-databases --routines --triggers > "$BACKUP_DIR/$DATE/mariadb_full_$DATE.sql"
        
        log_success "MariaDB backup completed"
    else
        log_warning "MariaDB service is not running, skipping backup"
    fi
}

# MongoDB backup
backup_mongodb() {
    if is_service_running mongodb; then
        log "Backing up MongoDB..."
        
        # Create backup directory in container
        docker-compose exec mongodb mkdir -p /tmp/mongodb_backup_$DATE
        
        # Dump all databases
        docker-compose exec mongodb mongodump --out /tmp/mongodb_backup_$DATE
        
        # Copy backup to host
        docker-compose exec mongodb tar -czf /tmp/mongodb_$DATE.tar.gz -C /tmp mongodb_backup_$DATE
        docker cp $(docker-compose ps -q mongodb):/tmp/mongodb_$DATE.tar.gz "$BACKUP_DIR/$DATE/"
        
        # Cleanup container backup
        docker-compose exec mongodb rm -rf /tmp/mongodb_backup_$DATE /tmp/mongodb_$DATE.tar.gz
        
        log_success "MongoDB backup completed"
    else
        log_warning "MongoDB service is not running, skipping backup"
    fi
}

# Redis backup
backup_redis() {
    if is_service_running redis; then
        log "Backing up Redis..."
        
        # Trigger background save
        docker-compose exec redis redis-cli -a "$REDIS_PASSWORD" BGSAVE 2>/dev/null || docker-compose exec redis redis-cli BGSAVE
        
        # Wait for save to complete
        sleep 5
        
        # Copy RDB file
        docker cp $(docker-compose ps -q redis):/opt/redis/data/dump.rdb "$BACKUP_DIR/$DATE/redis_$DATE.rdb"
        
        # AOF backup if enabled
        docker cp $(docker-compose ps -q redis):/opt/redis/data/appendonly.aof "$BACKUP_DIR/$DATE/redis_aof_$DATE.aof" 2>/dev/null || log_warning "AOF file not found"
        
        log_success "Redis backup completed"
    else
        log_warning "Redis service is not running, skipping backup"
    fi
}

# Valkey backup
backup_valkey() {
    if is_service_running valkey; then
        log "Backing up Valkey..."
        
        docker-compose exec valkey redis-cli -a "$VALKEY_PASSWORD" BGSAVE 2>/dev/null || docker-compose exec valkey redis-cli BGSAVE
        sleep 5
        docker cp $(docker-compose ps -q valkey):/opt/valkey/data/dump.rdb "$BACKUP_DIR/$DATE/valkey_$DATE.rdb"
        
        log_success "Valkey backup completed"
    else
        log_warning "Valkey service is not running, skipping backup"
    fi
}

# Configuration backup
backup_configurations() {
    log "Backing up configurations..."
    
    # Docker compose files
    cp docker-compose*.yml "$BACKUP_DIR/$DATE/" 2>/dev/null || true
    
    # Environment files
    cp .env* "$BACKUP_DIR/$DATE/" 2>/dev/null || true
    
    # Service configurations
    for service in postgresql mysql mariadb mongodb redis valkey nginx; do
        if [ -d "$service" ]; then
            tar -czf "$BACKUP_DIR/$DATE/${service}_config_$DATE.tar.gz" "$service/" 2>/dev/null || true
        fi
    done
    
    log_success "Configuration backup completed"
}

# Compress backups if requested
compress_backups() {
    if [ "$COMPRESS" = "yes" ]; then
        log "Compressing backup archive..."
        
        cd "$BACKUP_DIR"
        tar -czf "backup_$DATE.tar.gz" "$DATE/"
        
        if [ $? -eq 0 ]; then
            rm -rf "$DATE/"
            log_success "Backup compressed to backup_$DATE.tar.gz"
        else
            log_error "Compression failed, keeping uncompressed backup"
        fi
    fi
}

# Cleanup old backups
cleanup_old_backups() {
    log "Cleaning up backups older than $RETENTION_DAYS days..."
    
    find "$BACKUP_DIR" -name "backup_*.tar.gz" -mtime +$RETENTION_DAYS -delete 2>/dev/null || true
    find "$BACKUP_DIR" -maxdepth 1 -type d -name "20*" -mtime +$RETENTION_DAYS -exec rm -rf {} \; 2>/dev/null || true
    
    log_success "Cleanup completed"
}

# Main execution
main() {
    # Run all backup functions
    backup_postgresql
    backup_mysql
    backup_mariadb
    backup_mongodb
    backup_redis
    backup_valkey
    backup_configurations
    
    # Post-processing
    compress_backups
    cleanup_old_backups
    
    # Summary
    if [ "$COMPRESS" = "yes" ]; then
        backup_size=$(du -h "$BACKUP_DIR/backup_$DATE.tar.gz" 2>/dev/null | cut -f1 || echo "unknown")
        log_success "Backup completed successfully!"
        log "Backup location: $BACKUP_DIR/backup_$DATE.tar.gz"
        log "Backup size: $backup_size"
    else
        backup_size=$(du -sh "$BACKUP_DIR/$DATE" 2>/dev/null | cut -f1 || echo "unknown")
        log_success "Backup completed successfully!"
        log "Backup location: $BACKUP_DIR/$DATE/"
        log "Backup size: $backup_size"
    fi
}

# Run main function
main "$@"

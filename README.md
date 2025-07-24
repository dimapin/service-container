# Docker Services Collection

[![Docker CI](https://github.com/dimapin/service-container/actions/workflows/docker-ci.yml/badge.svg)](https://github.com/dimapin/service-container/actions/workflows/docker-ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Production-ready Docker images with Bitnami-like features using Debian base images. This collection provides 21 containerized services with comprehensive testing, monitoring, and deployment capabilities.

## 🏗️ Architecture

All services are built on **Debian bookworm Slim** for consistency, security, and reliability. Each service runs as a non-root user and includes comprehensive configuration options.

## 📦 Services Included

### 🗄️ Database Services
- **PostgreSQL** - Advanced relational database
- **MySQL** - Popular relational database  
- **MariaDB** - MySQL-compatible database
- **MongoDB** - NoSQL document database

### 🔄 Cache & Message Queue
- **Redis** + **Redis Sentinel** - In-memory data store with HA
- **Valkey** + **Valkey Sentinel** - Redis-compatible alternative
- **Kafka** - Distributed streaming platform

### 🌐 Web & Applications
- **Nginx** - High-performance web server
- **Ghost** - Modern publishing platform
- **Moodle** - Learning management system

### 🛠️ Infrastructure Tools
- **Git** - Version control with daemon and SSH
- **kubectl** - Kubernetes command-line tool
- **OS Shell** - General-purpose shell environment
- **OpenLDAP** - Directory services

### 📊 Monitoring Exporters
- **Apache Exporter** - Apache metrics for Prometheus
- **PostgreSQL Exporter** - Database metrics
- **MySQL Exporter** - MySQL/MariaDB metrics
- **MongoDB Exporter** - MongoDB metrics
- **Redis Exporter** - Redis metrics

## 🚀 Quick Start

```bash
# Clone repository
git clone https://github.com/dimapin/service-container.git
cd service-container

# Start all services (may take 5-10 minutes)
docker-compose -f docker-compose.full-stack.yml up -d

# Check service status
docker-compose -f docker-compose.full-stack.yml ps

# Run comprehensive tests
./comprehensive-test.sh
```

## 🧪 Testing

### Automated Testing Suite
```bash
# Basic functionality tests
./comprehensive-test.sh

# Extended tests with performance benchmarks
./comprehensive-test.sh --full

# View detailed results
cat test-results.json
```

### Manual Testing
```bash
# Test database connectivity
docker-compose exec postgresql psql -U postgres -c "SELECT version();"
docker-compose exec mysql mysql -u app_user -papp_pass -e "SELECT @@version;"

# Test cache services
docker-compose exec redis redis-cli -a redis123 ping

# Test web services
curl http://localhost:8080  # Nginx
curl http://localhost:2368  # Ghost
```

## 📊 Monitoring & Admin Interfaces

### Admin Interfaces
- **Adminer**: http://localhost:8082 (All databases)
- **phpMyAdmin**: http://localhost:8083 (MySQL/MariaDB)
- **Mongo Express**: http://localhost:8084 (MongoDB)
- **Redis Commander**: http://localhost:8085 (Redis/Valkey)

### Monitoring Stack
- **Prometheus**: http://localhost:9090 (Metrics collection)
- **Grafana**: http://localhost:3000 (Visualization)
  - Username: `admin`
  - Password: `grafana123`

### Metrics Endpoints
- PostgreSQL: http://localhost:9187/metrics
- MySQL: http://localhost:9104/metrics
- MongoDB: http://localhost:9216/metrics
- Redis: http://localhost:9121/metrics
- Apache: http://localhost:9117/metrics

## 🔧 Configuration

### Environment Variables
Each service supports extensive configuration via environment variables. See individual service directories for detailed options.

### Example Configurations
```yaml
# PostgreSQL
environment:
  - POSTGRESQL_PASSWORD=secure_password
  - POSTGRESQL_USERNAME=app_user
  - POSTGRESQL_DATABASE=app_db
  - POSTGRESQL_MAX_CONNECTIONS=200

# Redis
environment:
  - REDIS_PASSWORD=redis_password
  - REDIS_AOF_ENABLED=yes
  - REDIS_DATABASES=16
```

## 🚀 Production Deployment

### Docker Swarm
```bash
docker stack deploy -c docker-stack.yml services-stack
```

### Kubernetes
```bash
kubectl apply -f k8s-deployment.yml
```

### Individual Services
```bash
# Start specific services
docker-compose -f docker-compose.full-stack.yml up -d postgresql redis nginx

# Scale services
docker-compose -f docker-compose.full-stack.yml up -d --scale redis=3
```

## 🔒 Security Features

- ✅ All services run as non-root users (UID/GID 1001)
- ✅ Password-protected access by default
- ✅ Network isolation through Docker networks
- ✅ Security scanning in CI/CD pipeline
- ✅ Proper file permissions and ownership
- ✅ No sensitive data in logs

## 📋 Development

### Building Images
```bash
# Build specific service
docker build -t my-postgresql ./postgresql

# Build all services
for service in postgresql mysql redis nginx; do
  docker build -t "my-$service" "./$service"
done
```

### Contributing
1. Fork the repository
2. Create a feature branch: `git checkout -b feature/new-service`
3. Make your changes
4. Run tests: `./comprehensive-test.sh --full`
5. Submit a pull request

## 📚 Documentation

- [Deployment Guide](docs/deployment-guide.md) - Comprehensive deployment instructions
- [Troubleshooting](docs/troubleshooting.md) - Common issues and solutions
- [Examples](docs/examples/) - Production deployment examples

## 🤝 Community

- **Issues**: [GitHub Issues](https://github.com/dimapin/service-container/issues)
- **Discussions**: [GitHub Discussions](https://github.com/dimapin/service-container/discussions)
- **Contributing**: See [CONTRIBUTING.md](CONTRIBUTING.md)

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Inspired by Bitnami Docker images
- Built with security and production-readiness in mind
- Community-driven development

---

**Ready to deploy 21 production-ready services with one command!** 🎉

```bash
docker-compose -f docker-compose.full-stack.yml up -d
```

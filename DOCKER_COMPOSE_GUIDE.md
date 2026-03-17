# Docker Compose Deployment Guide

This Docker Compose configuration enables deployment of the Google Microservices Demo system with support for running **multiple instances in parallel** using the `INSTANCE_NAME` environment variable.

## Architecture

The docker-compose setup includes 12 microservices + Redis:

```
┌─────────────────────────────────────────────────────────┐
│                    FRONTEND (HTTP)                      │
│                 Port 8080 (configurable)                │
└─────────────────┬───────────────────────────────────────┘
                  │
    ┌─────────────┼──────────────────────────────┐
    │             │                              │
    ▼             ▼                              ▼
┌────────────┐ ┌──────────────┐ ┌──────────────────┐
│ProductCat. │ │Currency Svc  │ │  Cart Service    │
│ Service    │ │ (gRPC:7000)  │ │  (gRPC:7070)     │
│(gRPC:3550) │ └──────────────┘ └────────┬─────────┘
└────────────┘                            │
    │                                     ▼
    ▼                               ┌──────────────┐
┌────────────┐                      │ Redis Cache  │
│ Checkout SE│                      │ (TCP:6379)   │
│Service(505│                      └──────────────┘
└─────┬──────┘
      │
  ┌───┴────────────┬──────────────┬─────────────┐
  │                │              │             │
  ▼                ▼              ▼             ▼
Shipping      Payment        Email            Booking
Service       Service        Service          Service
```

## Services Included

| Service | Language | Protocol | Port | Purpose |
|---------|----------|----------|------|---------|
| **frontend** | Go | HTTP | 8080 | Web interface & entry point |
| **cartservice** | C# | gRPC | 7070 | Shopping cart (uses Redis) |
| **productcatalogservice** | Go | gRPC | 3550 | Product catalog |
| **currencyservice** | Node.js | gRPC | 7000 | Currency conversion |
| **paymentservice** | Node.js | gRPC | 50051 | Payment processing |
| **shippingservice** | Go | gRPC | 50051 | Shipping quotes |
| **emailservice** | Python | gRPC | 8080 | Email notifications |
| **checkoutservice** | Go | gRPC | 5050 | Order orchestration |
| **recommendationservice** | Python | gRPC | 8080 | Recommendations |
| **adservice** | Java | gRPC | 9555 | Advertisements |
| **loadgenerator** | Python | - | - | Traffic simulation (optional) |
| **shoppingassistantservice** | Python | HTTP | 80 | AI assistant (optional, GCP) |
| **redis-cart** | - | TCP | 6379 | Cache backend |

## Prerequisites

### Required
- Docker Engine 20.10+ with Compose 1.29+
- 8+ GB RAM
- 20+ GB free disk space
- All services built locally (see **Building Images** section)

### Optional
- Docker Hub access (for pre-built images)
- GCP account with AlloyDB & Generative AI API (for AI assistant)

## Quick Start

### 1. Basic Setup & Single Instance

```bash
# Copy environment template
cp .env.example .env

# Build all service images (first time only)
docker-compose build

# Start all services
docker-compose up -d

# Watch logs
docker-compose logs -f frontend

# Access the application
# Frontend: http://localhost:8080
```

### 2. Run Multiple Instances in Parallel

Each instance gets its own network and containers with unique names:

```bash
# Instance 1 - Development
INSTANCE_NAME=dev FRONTEND_PORT=8080 docker-compose up -d

# Instance 2 - Testing  
INSTANCE_NAME=test FRONTEND_PORT=8081 docker-compose up -d

# Instance 3 - Staging
INSTANCE_NAME=staging FRONTEND_PORT=8082 docker-compose up -d

# All instances run independently:
# - dev:      http://localhost:8080
# - test:     http://localhost:8081
# - staging:  http://localhost:8082
```

### 3. Using .env File

Create environment-specific `.env` files:

```bash
# .env.dev
INSTANCE_NAME=dev
FRONTEND_PORT=8080

# .env.test
INSTANCE_NAME=test
FRONTEND_PORT=8081

# Run with specific .env
docker-compose --env-file .env.dev up -d
docker-compose --env-file .env.test up -d
```

### 4. Load Testing

Load generator is optional (uses `load-testing` profile):

```bash
# Start with load generator
docker-compose --profile load-testing up -d

# View load generator logs
docker-compose logs -f loadgenerator

# Without load generator (default)
docker-compose up -d
```

### 5. Enable AI Shopping Assistant

Requires Google Cloud Platform setup:

```bash
# Set GCP credentials and configuration
export GCP_PROJECT_ID=your-project
export GCP_REGION=us-central1
export ALLOYDB_CLUSTER_NAME=your-cluster
export ALLOYDB_INSTANCE_NAME=your-instance
export ALLOYDB_DATABASE_NAME=your-db
export GCP_KEY_PATH=/path/to/service-account-key.json

# Start with GCP services
docker-compose --profile gcp up -d

# Access shopping assistant
# http://localhost:8080/assistant
```

## Command Reference

### Container Management

```bash
# Start services (detached)
docker-compose up -d

# Stop services
docker-compose down

# Stop and remove volumes
docker-compose down -v

# View running containers
docker-compose ps

# View logs
docker-compose logs

# Tail logs for specific service
docker-compose logs -f frontend

# Rebuild images
docker-compose build

# Rebuild specific service
docker-compose build frontend

# Execute command in container
docker-compose exec frontend bash
```

### Debugging

```bash
# Inspect network
docker network inspect microservices-dev

# View service health
docker-compose ps

# Test service connectivity (from host)
docker-compose exec frontend curl -s http://cartservice-dev:7070

# View detailed logs
docker-compose logs --follow --tail=50 checkoutservice

# Inspect container filesystem
docker-compose exec adservice bash
```

### Management with Multiple Instances

```bash
# Manage specific instance
docker-compose -p microservices-dev ps
docker-compose -p microservices-dev logs
docker-compose -p microservices-dev down

# Kill all instances
docker-compose -p microservices-dev down
docker-compose -p microservices-test down
docker-compose -p microservices-staging down

# Or use instance name in commands
INSTANCE_NAME=dev docker-compose down
INSTANCE_NAME=test docker-compose down
```

## Environment Variables

### Core Configuration

| Variable | Default | Purpose |
|----------|---------|---------|
| `INSTANCE_NAME` | `default` | Unique identifier for containers & networks |
| `FRONTEND_PORT` | `8080` | External port for frontend HTTP |

### Optional: GCP/AI Assistant

| Variable | Purpose |
|----------|---------|
| `GCP_PROJECT_ID` | Google Cloud project ID |
| `GCP_REGION` | GCP region (default: us-central1) |
| `GCP_KEY_PATH` | Path to GCP service account JSON |
| `ALLOYDB_CLUSTER_NAME` | AlloyDB cluster name |
| `ALLOYDB_INSTANCE_NAME` | AlloyDB instance name |
| `ALLOYDB_DATABASE_NAME` | AlloyDB database name |
| `ALLOYDB_TABLE_NAME` | AlloyDB table for embeddings |
| `ALLOYDB_SECRET_NAME` | Google Secret Manager secret name |

## Networking

### Service Discovery
Services communicate via container hostnames:

```
# From frontend to cartservice
cartservice-${INSTANCE_NAME}:7070

# From checkoutservice to paymentservice
paymentservice-${INSTANCE_NAME}:50051
```

### Isolated Networks per Instance
Each instance has its own network (`microservices-${INSTANCE_NAME}`), preventing cross-instance communication and allowing true parallel deployment.

### Port Mapping
Only frontend exposes a port to host. All other services communicate internally:

```yaml
frontend:  8080 (host) ← 8080 (container)
cartservice: Not exposed → 7070 (internal)
paymentservice: Not exposed → 50051 (internal)
```

## Performance Tuning

### Resource Management

```yaml
# Add to docker-compose.yml
services:
  frontend:
    deploy:
      resources:
        limits:
          cpus: '0.5'
          memory: 512M
        reservations:
          cpus: '0.25'
          memory: 256M
```

### Optimize for High Load

```bash
# Increase Redis memory
docker-compose exec redis-cart redis-cli CONFIG SET maxmemory 2gb

# Monitor containers
docker stats

# View detailed metrics
docker-compose exec frontend top
```

## Troubleshooting

### Services Won't Start

```bash
# Check logs
docker-compose logs

# Verify images built
docker-compose images

# Rebuild all
docker-compose build --no-cache
docker-compose up -d
```

### Service Discovery Issues

```bash
# Verify network connectivity
docker-compose exec frontend ping cartservice-dev
docker-compose exec frontend nslookup productcatalogservice-dev

# Check exposed ports
docker-compose exec frontend netstat -tlnp
```

### Container Crashes

```bash
# View exit codes
docker-compose ps

# Check logs
docker-compose logs frontend

# Inspect specific container
docker inspect microservices-dev-frontend-1

# Try with foreground output
docker-compose up (without -d)
```

### Build Issues

```bash
# Clean build
docker-compose build --no-cache

# Build specific service
docker-compose build --no-cache frontend

# Increase verbosity
docker-compose --verbose build
```

### Memory Issues

```bash
# Check Docker daemon resources
docker system df

# Remove unused images
docker system prune -a

# Limit instances
# Run fewer instances or on separate hosts
```

## Advanced Usage

### Custom Configuration per Service

Edit `docker-compose.yml` to override environment variables:

```yaml
frontend:
  environment:
    - CUSTOM_FEATURE_FLAG=true
    - LOG_LEVEL=debug
```

### Connect to External Services

Modify service addresses in environment variables:

```bash
# Use external Redis instead of local
REDIS_ADDR=redis-external.example.com:6379
```

### Health Checks

Built-in health check for Redis:

```bash
docker-compose ps

# Custom health check for frontend
docker-compose exec frontend curl http://localhost:8080
```

### Logging

```bash
# Ship logs to external system
docker-compose logs | tee deployment-$(date +%s).log

# View only error logs
docker-compose logs | grep ERROR
```

## Cleanup

```bash
# Stop all containers
docker-compose down

# Remove all volumes
docker-compose down -v

# Remove all images
docker-compose down -v --rmi all

# For multiple instances
INSTANCE_NAME=dev docker-compose down -v
INSTANCE_NAME=test docker-compose down -v
INSTANCE_NAME=staging docker-compose down -v
```

## Production Recommendations

1. **Use Docker Swarm or Kubernetes** for production deployments
2. **SSL/TLS** - Add reverse proxy (nginx) in front of frontend
3. **Monitoring** - Add Prometheus + Grafana
4. **Logging** - Use ELK stack or similar
5. **Secrets Management** - Use Docker Secrets or external provider
6. **Resource Limits** - Set CPU & memory limits per service
7. **Backup Strategy** - Persistent volumes for databases
8. **Load Balancing** - Use HAProxy for multiple instances

## References

- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Google Microservices Demo](https://github.com/GoogleCloudPlatform/microservices-demo)
- [gRPC Documentation](https://grpc.io/)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)

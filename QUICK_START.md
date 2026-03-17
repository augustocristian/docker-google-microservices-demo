# Quick Start Guide - Multi-Instance Docker Compose Deployment

## Overview

This guide demonstrates how to deploy the Google Microservices Demo using Docker Compose with support for **multiple parallel instances** - allowing you to run dev, test, and production environments simultaneously.

## What Makes This Special

Unlike typical Docker Compose setups, this configuration:

✓ **Run Multiple Instances** - Dev, test, staging, production all at the same time  
✓ **Independent Networks** - Each instance has its own isolated network  
✓ **Unique Naming** - Container names include the instance name to avoid conflicts  
✓ **Config per Instance** - Different image repositories, ports, or environment variables per instance  
✓ **Simple Scaling** - Add more instances by changing the `INSTANCE_NAME` variable  

## Quick Commands

### Windows (PowerShell)

```powershell
# Start dev instance on port 8080
.\compose-deploy.ps1 up dev 8080

# Start test instance on port 8081
.\compose-deploy.ps1 up test 8081

# View dev instance logs
.\compose-deploy.ps1 logs dev

# Stop and clean
.\compose-deploy.ps1 down dev

# Start all 3 demo instances at once
.\compose-deploy.ps1 multi
```

### Linux/Mac (Bash)

```bash
# Start dev instance on port 8080
./compose-deploy.sh up dev 8080

# Start test instance on port 8081
./compose-deploy.sh up test 8081

# View dev instance logs
./compose-deploy.sh logs dev

# Stop and clean
./compose-deploy.sh down dev

# Start all 3 demo instances at once
./compose-deploy.sh multi
```

### Manual Commands (Any OS)

```bash
# Start single instance
INSTANCE_NAME=dev FRONTEND_PORT=8080 docker-compose up -d
INSTANCE_NAME=test FRONTEND_PORT=8081 docker-compose up -d

# View containers
docker ps | grep microservices

# View logs
INSTANCE_NAME=dev docker-compose logs -f frontend

# Stop instance
INSTANCE_NAME=dev docker-compose down
```

## Use Cases

### 1. Development Workflow

```bash
# Terminal 1: Start dev instance with logs
.\compose-deploy.ps1 up dev 8080
.\compose-deploy.ps1 logs dev

# Terminal 2: Run tests against dev instance
# Your tests here → http://localhost:8080
```

### 2. Parallel Testing

```bash
# Terminal 1: Start dev instance
.\compose-deploy.ps1 up dev 8080

# Terminal 2: Start test instance
.\compose-deploy.ps1 up test 8081

# Terminal 3: Start staging instance
.\compose-deploy.ps1 up staging 8082

# Run different test suites against each:
# Dev:     http://localhost:8080
# Test:    http://localhost:8081
# Staging: http://localhost:8082
```

### 3. CI/CD Pipeline

```bash
# Each CI job gets its own instance
# Job 1 - Unit Tests
INSTANCE_NAME=ci-unit-$BUILD_ID FRONTEND_PORT=9001 docker-compose up -d
# ... run tests ...
INSTANCE_NAME=ci-unit-$BUILD_ID docker-compose down -v

# Job 2 - Integration Tests
INSTANCE_NAME=ci-integration-$BUILD_ID FRONTEND_PORT=9002 docker-compose up -d
# ... run tests ...
INSTANCE_NAME=ci-integration-$BUILD_ID docker-compose down -v
```

### 4. A/B Testing / Performance Comparison

```bash
# Instance A: Original configuration
INSTANCE_NAME=version-a FRONTEND_PORT=8080 docker-compose up -d

# Instance B: Modified configuration (edit docker-compose.yml for service changes)
INSTANCE_NAME=version-b FRONTEND_PORT=8081 docker-compose up -d

# Compare:
# http://localhost:8080 vs http://localhost:8081
```

## Architecture Details

### Container Naming

Each service container includes the `INSTANCE_NAME`:

```
# Instance: dev
- frontend-dev
- cartservice-dev
- redis-cart-dev
- productcatalogservice-dev
- etc.

# Instance: test
- frontend-test
- cartservice-test
- redis-cart-test
- productcatalogservice-test
- etc.
```

### Network Isolation

```yaml
networks:
  microservices-dev        # Dev instance network
  microservices-test       # Test instance network
  microservices-staging    # Staging instance network
```

Services in one network **cannot reach** services in another network.

### Environment Variables

Each service is configured with the correct service addresses:

```yaml
# Frontend in dev instance
environment:
  - PRODUCT_CATALOG_SERVICE_ADDR=productcatalogservice-dev:3550
  - CART_SERVICE_ADDR=cartservice-dev:7070
  - CHECKOUT_SERVICE_ADDR=checkoutservice-dev:5050
  # etc.

# Frontend in test instance
environment:
  - PRODUCT_CATALOG_SERVICE_ADDR=productcatalogservice-test:3550
  - CART_SERVICE_ADDR=cartservice-test:7070
  - CHECKOUT_SERVICE_ADDR=checkoutservice-test:5050
  # etc.
```

## Data Persistence

Redis data is stored in named volumes:

```
redis-data-dev     # Dev instance Redis data
redis-data-test    # Test instance Redis data
redis-data-staging # Staging instance Redis data
```

Clean up with:

```bash
# Remove volume for dev instance
INSTANCE_NAME=dev docker-compose down -v

# Or manually remove all demo volumes
docker volume ls | grep redis-data
docker volume rm redis-data-dev redis-data-test redis-data-staging
```

## Troubleshooting

### Port Already in Use

```bash
# Check what's using the port
netstat -ano | findstr :8080  # Windows
lsof -i :8080                  # Linux/Mac

# Kill the process or use different port
.\compose-deploy.ps1 up dev 9080  # Use port 9080 instead
```

### Containers Won't Start

```bash
# Check logs
.\compose-deploy.ps1 logs dev

# Check if images exist
docker images | grep microservices

# Build images (first time)
$env:INSTANCE_NAME = 'dev'
docker-compose build
```

### Services Can't Communicate

```bash
# Verify network exists
docker network ls | grep microservices

# Check container connectivity
docker exec frontend-dev curl http://cartservice-dev:7070

# Verify service is running
docker ps | grep cartservice-dev
```

### Clean Up Everything

```bash
# Remove all instances, containers, and volumes
.\compose-deploy.ps1 clean dev
.\compose-deploy.ps1 clean test
.\compose-deploy.ps1 clean staging

# Or manually
docker-compose -p microservices-dev down -v
docker-compose -p microservices-test down -v
docker-compose -p microservices-staging down -v

# Remove all microservices images
docker image ls | grep microservices | awk '{print $3}' | xargs docker rmi
```

## Performance Characteristics

### Resource Usage per Instance

- **RAM**: ~2-3 GB (12 services + Redis)
- **Disk**: ~500 MB (base images)
- **CPU**: Variable (load-dependent)

### Running 3 Instances Simultaneously

- **Total RAM**: ~6-9 GB
- **Total Disk**: ~1.5 GB
- **CPU**: Depends on load generator activity

### Optimization Tips

1. **Only run needed instances** - Don't leave unused instances running
2. **Use load-testing profile selectively**
   ```bash
   # With load generator
   docker-compose --profile load-testing up -d
   
   # Without load generator (default, lower resource usage)
   docker-compose up -d
   ```

3. **Monitor resources**
   ```bash
   docker stats
   ```

4. **Disable unneeded services** - Remove from docker-compose.yml if not needed

## Production Considerations

**Docker Compose** is suitable for development but for production use:

- **Kubernetes** - Better resource management, auto-scaling, high availability
- **Docker Swarm** - Simple orchestration without Kubernetes complexity
- **Managed Services** - Use cloud-native managed services instead

## Advanced Configuration

### Use External Redis

Edit `docker-compose.yml` cartservice environment:

```yaml
cartservice:
  environment:
    - REDIS_ADDR=redis-prod.internal:6379
```

### Custom Frontend Port per Instance

```bash
# Using .env files
echo "INSTANCE_NAME=dev" > .env.dev
echo "FRONTEND_PORT=8080" >> .env.dev

echo "INSTANCE_NAME=test" > .env.test
echo "FRONTEND_PORT=8081" >> .env.test

# Run with specific config
docker-compose --env-file .env.dev up -d
docker-compose --env-file .env.test up -d
```

### Enable AI Shopping Assistant

```bash
# Set GCP credentials first
$env:GCP_PROJECT_ID = 'your-project'
$env:ALLOYDB_CLUSTER_NAME = 'your-cluster'
$env:GCP_KEY_PATH = 'C:\path\to\service-account-key.json'

# Start with GCP profile
$env:INSTANCE_NAME = 'dev'
docker-compose --profile gcp up -d
```

## Next Steps

1. **Start first instance**
   ```bash
   .\compose-deploy.ps1 up dev 8080
   ```

2. **Access the application**
   - Visit http://localhost:8080

3. **View logs**
   ```bash
   .\compose-deploy.ps1 logs dev
   ```

4. **Start additional instances** (optional)
   ```bash
   .\compose-deploy.ps1 multi
   ```

5. **Stop when done**
   ```bash
   .\compose-deploy.ps1 down dev
   ```

## References

- [docker-compose.yml](docker-compose.yml) - Configuration file
- [DOCKER_COMPOSE_GUIDE.md](DOCKER_COMPOSE_GUIDE.md) - Comprehensive documentation
- [.env.example](.env.example) - Environment variables template
- [compose-deploy.ps1](compose-deploy.ps1) - Helper script (Windows)
- [compose-deploy.sh](compose-deploy.sh) - Helper script (Linux/Mac)

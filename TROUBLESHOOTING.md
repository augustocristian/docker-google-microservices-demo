# Troubleshooting Guide - Docker Compose Multi-Instance Deployment

## Common Issues & Solutions

### 1. Port Already in Use

**Problem:** Error like "bind: address already in use" or "port 8080 is already in use"

```
Error response from daemon: driver failed programming external connectivity on endpoint frontend-dev:
Bind for 0.0.0.0:8080 failed: port is already allocated
```

**Solution:**

```bash
# Windows - Check what's using the port
netstat -ano | findstr :8080

# Linux/Mac - Check what's using the port
lsof -i :8080

# Kill the process (Windows)
taskkill /PID <PID> /F

# Or use a different port
TJOB_NAME=dev FRONTEND_PORT=9080 docker-compose up -d
```

**Prevention:**
- Use unique ports for each instance: 8080 (dev), 8081 (test), 8082 (staging)
- Check `docker ps` before starting new instances

---

### 2. Network Already Exists

**Problem:** Error "network ... already exists"

```
Error response from daemon: network microservices-dev already exists
```

**Solution:**

```bash
# This happens if compose was interrupted mid-startup
# Safe to ignore - containers will still start

# Or force remove the network (only if stopped)
docker network rm microservices-dev

# Then restart
TJOB_NAME=dev docker-compose up -d
```

---

### 3. Services Can't Communicate

**Problem:** Services trying to connect get "connection refused" or "cannot resolve"

```
Error: cartservice-dev: Temporary failure in name resolution
```

**Cause:** Service names in the network don't include the instance name

**Solution:**

Check `docker-compose.yml` environment variables match the service names:

```yaml
# CORRECT - matches cartservice-dev container name
environment:
  - REDIS_ADDR=redis-cart-dev:6379
  - CART_SERVICE_ADDR=cartservice-dev:7070

# WRONG - doesn't include instance name
environment:
  - REDIS_ADDR=redis-cart:6379
  - CART_SERVICE_ADDR=cartservice:7070
```

**Verify connectivity:**

```bash
# Test from frontend container
docker-compose exec frontend curl http://cartservice-dev:7070

# Or ping the service
docker-compose exec frontend ping cartservice-dev

# Check DNS resolution
docker-compose exec frontend nslookup cartservice-dev
```

---

### 4. Container Names Conflict

**Problem:** Container already exists with that name

```
Error response from daemon: Conflict. The container name "/frontend-dev" is already in use
```

**Solution:**

```bash
# Stop the running container
docker stop frontend-dev

# Or remove it
docker rm frontend-dev

# Or use different instance name
TJOB_NAME=dev-new docker-compose up -d
```

**Prevention:** Always use unique `TJOB_NAME` values

---

### 5. Build Failures

**Problem:** Images fail to build

```
ERROR: failed to build image for service frontend
```

**Solution:**

```bash
# Check Docker daemon is running
docker ps

# Try rebuild with more verbosity
$env:TJOB_NAME = 'dev'
docker-compose build --verbose

# Or rebuild without cache
docker-compose build --no-cache

# Check for disk space
docker system df

# Clean up old images/containers
docker system prune -a
```

---

### 6. Docker Daemon Not Running

**Problem:** Cannot connect to Docker daemon

```
Cannot connect to the Docker daemon at unix:///var/run/docker.sock.
```

**Windows Solution:**
```bash
# Start Docker Desktop
# Or use WSL2 backend if installed
```

**Linux Solution:**
```bash
# Start Docker service
sudo systemctl start docker

# Or with systemd
sudo service docker start
```

---

### 7. Out of Disk Space

**Problem:** "No space left on device" error

```
Error response from daemon: write /var/lib/docker/overlay2/...: no space left on device
```

**Solution:**

```bash
# Check disk usage
docker system df

# Remove unused volumes
docker volume prune

# Remove unused images
docker image prune -a

# Remove stopped containers
docker container prune

# Or aggressive cleanup
docker system prune -a --volumes
```

---

### 8. Out of Memory

**Problem:** Services crash or restart frequently

**Solution:**

```bash
# Check memory usage
docker stats

# Run fewer instances or stop other services
docker ps  # See what's running

# Reduce instances
docker-compose down  # Stop one instance to free RAM

# Or restart Docker service to clear cache
docker system prune
```

---

### 9. Redis Connection Errors

**Problem:** CartService can't connect to Redis

```
Error: Dial tcp 127.0.0.1:6379: connection refused
```

**Solution:**

```bash
# Check Redis container is running
docker ps | grep redis-cart-dev

# Check Redis is healthy
docker-compose exec redis-cart-dev redis-cli ping
# Should respond: PONG

# Check Redis address in cartservice environment
docker-compose config | grep REDIS_ADDR

# Verify network connectivity
docker-compose exec cartservice-dev ping redis-cart-dev
```

---

### 10. Environment Variables Not Set

**Problem:** Services not picking up environment variables

```
NullPointerException: Cannot read field "PRODUCT_CATALOG_SERVICE_ADDR"
```

**Solution:**

```bash
# Verify environment is being set
# Check compose file has correct variable syntax
docker-compose config | grep "PRODUCT_CATALOG"

# Or verify at runtime
docker-compose exec frontend env | grep "PRODUCT_CATALOG"

# If using .env file, make sure docker-compose finds it
ls -la .env  # Verify file exists

# Use explicit env file
docker-compose --env-file .env up -d
```

---

## Diagnostic Commands

### Get System Information

```bash
# Docker version
docker --version

# Docker daemon info
docker info

# Docker compose version
docker-compose --version

# Available disk space
df -h                    # Linux/Mac
dir | findstr "free"     # Windows
```

### Check Running Instances

```bash
# All microservices containers
docker ps | grep microservices

# Specific instance
docker ps | grep -dev

# All compose networks
docker network ls | grep microservices

# All compose volumes
docker volume ls | grep redis-data
```

### Inspect Specific Service

```bash
# Container details
docker inspect frontend-dev

# Container logs
docker logs frontend-dev

# Container stats (CPU, memory)
docker stats frontend-dev

# Run command in container
docker exec frontend-dev curl http://localhost:8080
```

### Verify Networking

```bash
# Inspect network
docker network inspect microservices-dev

# Connected containers
docker network inspect microservices-dev | grep -i container

# Test connectivity from container
docker-compose exec frontend ping cartservice-dev
docker-compose exec frontend curl -I http://cartservice-dev:7070
```

---

## Advanced Debugging

### Enable Verbose Logging

```bash
# Increase Docker verbosity
DOCKER_BUILDKIT=0 docker-compose build --verbose

# Check compose file for errors
docker-compose config

# Validate syntax
docker-compose config > /dev/null && echo "Valid"
```

### Container Debugging

```bash
# Shell access to container
docker-compose exec frontend bash
docker-compose exec frontend sh  # If bash not available

# Inside container, check:
ping cartservice-dev           # DNS resolution
curl http://cartservice-dev:7070  # Connectivity
env | grep SERVICE            # Environment variables
netstat -tlnp                 # Open ports
```

### Docker Compose Debugging

```bash
# Show what docker-compose will do (dry run)
docker-compose --verbose up -d

# See the generated config
docker-compose config

# Validate specific service
docker-compose config --services
```

---

## Getting Help

### Collect Debug Information

```bash
# Create debug bundle
mkdir debug-info
docker ps > debug-info/containers.txt
docker images > debug-info/images.txt
docker network ls > debug-info/networks.txt
docker volume ls > debug-info/volumes.txt
docker compose config > debug-info/compose-config.yml
docker system df > debug-info/disk-usage.txt
docker stats --no-stream > debug-info/stats.txt
docker logs frontend-dev > debug-info/frontend-logs.txt 2>&1
```

### Check Logs

```bash
# All services logs
docker-compose logs

# Specific service logs
docker-compose logs frontend

# Follow logs in real-time
docker-compose logs -f

# Last N lines
docker-compose logs --tail=50

# Logs from specific time
docker-compose logs --since 2h
```

---

## Quick Recovery Steps

If something goes wrong, try these in order:

```bash
# 1. Check what's running
docker ps -a

# 2. View recent logs
docker-compose logs --tail=20

# 3. Restart services
docker-compose restart

# 4. Stop and start fresh
docker-compose down
docker-compose up -d

# 5. Nuclear option (removes everything, data lost)
docker-compose down -v
docker-compose build --no-cache
docker-compose up -d
```

---

## Performance Issues

### Services Running Slow

```bash
# Check CPU/Memory usage
docker stats

# Check disk I/O
# On Linux: iostat -x 1
# On Mac/Windows: Use Activity Monitor or Task Manager

# Restart services to clear cache
docker-compose restart

# Reduce load if load-testing is running
docker-compose --profile load-testing down
```

### High Memory Usage

```bash
# Which container is using most memory?
docker stats

# Stop less important instances
docker-compose -p microservices-test down -v
docker-compose -p microservices-staging down -v

# Or restart Docker daemon
# On Windows: Restart Docker Desktop
# On Linux: sudo systemctl restart docker
```

---

## Performance Optimization

```bash
# Limit resources per service (add to docker-compose.yml)
services:
  frontend:
    deploy:
      resources:
        limits:
          cpus: '0.5'
          memory: 512M

# Build images without running
docker-compose build

# Use image instead of build context
# In docker-compose.yml, change:
# - build: ./src/frontend
# + image: myregistry/frontend:latest
```

---

## References

- [Docker Troubleshooting](https://docs.docker.com/config/daemon/#troubleshoot-the-daemon)
- [Docker Compose Troubleshooting](https://docs.docker.com/compose/faq/)
- [Common Docker Issues](https://docs.docker.com/config/containers/logging/)
- [Network Troubleshooting](https://docs.docker.com/network/troubleshoot/)

---

## Still Having Issues?

1. **Check the logs** - Always start here
   ```bash
   docker-compose logs frontend
   ```

2. **Verify configuration** - Make sure TJOB_NAME is set correctly
   ```bash
   echo $TJOB_NAME
   docker-compose config | head -20
   ```

3. **Test connectivity** - Can services reach each other?
   ```bash
   docker-compose exec frontend ping cartservice-${TJOB_NAME}
   ```

4. **Review docker-compose.yml** - Check service names include instance variable

5. **Try clean restart** - Stop, rebuild, start fresh
   ```bash
   docker-compose down -v
   docker-compose build --no-cache
   docker-compose up -d
   ```

6. **Check disk space** - Many issues are due to full disk
   ```bash
   docker system df
   ```

7. **Consult documentation** - See [DOCKER_COMPOSE_GUIDE.md](DOCKER_COMPOSE_GUIDE.md) and [QUICK_START.md](QUICK_START.md)

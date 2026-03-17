# Docker Compose Deployment - Complete Setup

## 📋 What's Included

This Docker Compose setup enables **multi-instance parallel deployment** of the Google Microservices Demo system, similar to the example you provided but adapted for all 12 microservices.

### Files Created

| File | Purpose |
|------|---------|
| **docker-compose.yml** | Main configuration with all 12 services + Redis |
| **QUICK_START.md** | Fast start guide with practical examples |
| **DOCKER_COMPOSE_GUIDE.md** | Comprehensive reference documentation |
| **TROUBLESHOOTING.md** | Common issues and solutions |
| **.env.example** | Environment variables template |
| **compose-deploy.ps1** | Windows helper script for deployment |
| **compose-deploy.sh** | Linux/Mac helper script for deployment |
| **compose-multi.bat** | Windows batch script for multi-instance management |
| **Makefile** | Unix make targets for common tasks |

---

## 🚀 Quick Start (Windows)

```bash
# 1. Start single instance on port 8080
.\compose-deploy.ps1 up dev 8080

# 2. Access the application
# http://localhost:8080

# 3. View logs
.\compose-deploy.ps1 logs dev

# 4. Stop the instance
.\compose-deploy.ps1 down dev
```

## 🚀 Quick Start (Linux/Mac)

```bash
# 1. Start single instance on port 8080
./compose-deploy.sh up dev 8080

# 2. Access the application
# http://localhost:8080

# 3. View logs
./compose-deploy.sh logs dev

# 4. Stop the instance
./compose-deploy.sh down dev
```

---

## 🔀 Multi-Instance Parallel Deployment

Run multiple instances simultaneously on different ports:

```bash
# Terminal 1: Start development instance
.\compose-deploy.ps1 up dev 8080

# Terminal 2: Start testing instance
.\compose-deploy.ps1 up test 8081

# Terminal 3: Start staging instance
.\compose-deploy.ps1 up staging 8082

# Access all instances:
# http://localhost:8080  (dev)
# http://localhost:8081  (test)
# http://localhost:8082  (staging)
```

Or use the convenient multi-instance command:

```bash
# Start all 3 demo instances at once
.\compose-deploy.ps1 multi
```

---

## 🏛️ Architecture Overview

### Services Included

12 core microservices + Redis:

```
Frontend (HTTP:8080)
├── Cart Service (gRPC:7070) → Redis (TCP:6379)
├── Product Catalog (gRPC:3550) 
├── Currency Service (gRPC:7000)
├── Recommendation Service (gRPC:8080)
├── Checkout Service (gRPC:5050)
│   ├── Payment Service (gRPC:50051)
│   ├── Shipping Service (gRPC:50051)
│   ├── Email Service (gRPC:8080)
│   └── Others...
├── Ad Service (gRPC:9555)
└── Shopping Assistant (HTTP:80) [Optional - GCP required]

Plus:
- Load Generator (optional, for load testing)
```

### Instance Isolation

Each instance gets its own:
- **Network** - `microservices-${INSTANCE_NAME}`
- **Containers** - `servicename-${INSTANCE_NAME}`
- **Volumes** - `redis-data-${INSTANCE_NAME}`

This allows true parallel execution without port conflicts or network interference.

---

## 🔑 Key Features

✅ **Multi-Instance Support** - Run dev, test, staging simultaneously  
✅ **Environment Variables** - Easy configuration per instance  
✅ **Health Checks** - Redis includes health monitoring  
✅ **Service Discovery** - Automatic DNS resolution within networks  
✅ **Volume Persistence** - Redis data persists across restarts  
✅ **Optional Profiles** - Load testing and GCP services can be toggled  
✅ **Cross-Platform** - Scripts for Windows, Linux, and Mac  

---

## 📚 Documentation

### For Quick Setup
→ Read [QUICK_START.md](QUICK_START.md)

### For Comprehensive Reference
→ Read [DOCKER_COMPOSE_GUIDE.md](DOCKER_COMPOSE_GUIDE.md)

### For Troubleshooting
→ Read [TROUBLESHOOTING.md](TROUBLESHOOTING.md)

---

## 💻 Usage Examples

### Example 1: Single Instance

```bash
INSTANCE_NAME=dev FRONTEND_PORT=8080 docker-compose up -d
# Access: http://localhost:8080
INSTANCE_NAME=dev docker-compose down
```

### Example 2: Multiple Instances

```bash
# Terminal 1
INSTANCE_NAME=dev FRONTEND_PORT=8080 docker-compose up -d

# Terminal 2  
INSTANCE_NAME=test FRONTEND_PORT=8081 docker-compose up -d

# Terminal 3
INSTANCE_NAME=staging FRONTEND_PORT=8082 docker-compose up -d

# All run independently without interference
```

### Example 3: Using Helper Scripts

```bash
# Windows PowerShell
.\compose-deploy.ps1 multi      # Start 3 instances
.\compose-deploy.ps1 logs dev   # View dev logs
.\compose-deploy.ps1 down dev   # Stop dev

# Linux/Mac Bash
./compose-deploy.sh multi       # Start 3 instances
./compose-deploy.sh logs dev    # View dev logs
./compose-deploy.sh down dev    # Stop dev

# Or Windows Batch
compose-multi.bat up            # Start all 3 instances
compose-multi.bat ps            # Show all containers
compose-multi.bat down          # Stop all instances
```

### Example 4: Using Make (Linux/Mac)

```bash
make up              # Start dev instance
make multi           # Start 3 instances
make logs            # View dev logs
make status          # Show all instance status
make clean-all       # Stop all and remove data
```

---

## 📦 Deployment Requirements

### Minimum
- Docker Engine 20.10+
- Docker Compose 1.29+
- 8 GB RAM
- 20 GB disk space

### Per Instance
- ~2-3 GB RAM
- ~500 MB disk (base images)
- CPU: Variable based on load

---

## 🔧 Configuration

### Environment Variables

Create a `.env` file (copy from `.env.example`):

```bash
# Instance identifier (used in container/network names)
INSTANCE_NAME=dev

# External port for frontend HTTP interface
FRONTEND_PORT=8080

# Optional: GCP configuration (for AI shopping assistant)
GCP_PROJECT_ID=your-project
GCP_REGION=us-central1
GCP_KEY_PATH=./gcp-key.json
```

### Using .env File

```bash
# Create environment-specific files
echo "INSTANCE_NAME=dev" > .env.dev
echo "FRONTEND_PORT=8080" >> .env.dev

echo "INSTANCE_NAME=test" > .env.test
echo "FRONTEND_PORT=8081" >> .env.test

# Run with specific environment
docker-compose --env-file .env.dev up -d
docker-compose --env-file .env.test up -d
```

---

## 🎯 Use Cases

### 1. **Development** 
Single instance for local development with logging

### 2. **Testing**
Multiple instances for parallel test execution

### 3. **CI/CD**
Each pipeline job gets its own isolated instance

### 4. **Performance Testing**
Compare behavior across multiple instances

### 5. **Load Testing**
Run with load generator profile enabled

### 6. **Production Preview**
Stage production-like configuration before deployment

---

## ⚠️ Important Notes

1. **First Build** - Initial `docker-compose build` may take 10-15 minutes
2. **Disk Space** - Each instance uses ~500MB for base images
3. **RAM Usage** - Each instance uses ~2-3GB RAM (3 instances = 6-9GB)
4. **Database** - Uses ephemeral Redis (not persisted across restarts)
5. **Networking** - Services communicate via container names and internal DNS

---

## 🔄 Common Workflows

### Start and Access

```bash
# Start
$env:INSTANCE_NAME = 'dev'
$env:FRONTEND_PORT = 8080
docker-compose up -d

# Wait a few seconds for startup
Start-Sleep -Seconds 5

# Open in browser
Start-Process http://localhost:8080
```

### Monitoring Logs

```bash
# Run in separate terminal
$env:INSTANCE_NAME = 'dev'
docker-compose logs -f frontend

# Stop with Ctrl+C
```

### Stop and Cleanup

```bash
# Stop containers
$env:INSTANCE_NAME = 'dev'
docker-compose down

# Or stop and remove data
docker-compose down -v
```

---

## 🚨 Troubleshooting

### Port Already in Use
```bash
# Use different port
$env:INSTANCE_NAME = 'dev'
$env:FRONTEND_PORT = 9080
docker-compose up -d
```

### Services Won't Start
```bash
# Check logs
$env:INSTANCE_NAME = 'dev'
docker-compose logs

# Try rebuild
docker-compose build --no-cache
```

### Out of Memory
```bash
# Stop some instances to free RAM
docker-compose -p microservices-test down

# Or check memory usage
docker stats
```

See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for more solutions.

---

## 📖 Next Steps

1. **Review the docker-compose file** - Understand the service configuration
2. **Read QUICK_START.md** - Get hands-on with examples
3. **Start your first instance** - `.\compose-deploy.ps1 up dev 8080`
4. **Access the application** - Visit http://localhost:8080
5. **Explore multi-instance** - Run `.\compose-deploy.ps1 multi`
6. **Check documentation** - Refer to guides as needed

---

## 🔗 Resources

- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Google Microservices Demo](https://github.com/GoogleCloudPlatform/microservices-demo)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [gRPC Documentation](https://grpc.io/)

---

## 📝 Summary

This Docker Compose setup provides a **production-ready** approach to deploying the Google Microservices Demo with genuine multi-instance support. Unlike simple Docker Compose files, this configuration:

- ✅ Supports **parallel instances** via environment variables
- ✅ Includes **all 12 microservices** plus Redis
- ✅ Provides **complete documentation** and helper scripts
- ✅ Offers **troubleshooting guides** for common issues
- ✅ Works **cross-platform** (Windows, Linux, Mac)
- ✅ Enables **realistic testing scenarios** with multiple versions running

Start with `./compose-deploy.ps1 up dev 8080` and explore from there!

---

**Version:** 1.0  
**Last Updated:** March 2026  
**Status:** Ready for Production Use

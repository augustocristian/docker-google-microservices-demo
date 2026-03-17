.PHONY: help up down logs ps build clean multi \
        up-dev down-dev logs-dev ps-dev \
        up-test down-test logs-test ps-test \
        up-staging down-staging logs-staging ps-staging \
        build-all clean-all status health

# Default target
help:
	@echo "╔════════════════════════════════════════════════════════════╗"
	@echo "║ Google Microservices Demo - Docker Compose Manager        ║"
	@echo "╚════════════════════════════════════════════════════════════╝"
	@echo ""
	@echo "QUICK COMMANDS:"
	@echo "  make up              - Start dev instance on port 8080"
	@echo "  make down            - Stop dev instance"
	@echo "  make logs            - Stream dev instance logs"
	@echo "  make ps              - Show dev instance containers"
	@echo "  make status          - Show status of all instances"
	@echo ""
	@echo "MULTI-INSTANCE COMMANDS:"
	@echo "  make multi           - Start 3 instances (dev, test, staging)"
	@echo "  make down-all        - Stop all instances"
	@echo "  make clean-all       - Stop all instances and remove data"
	@echo ""
	@echo "INSTANCE-SPECIFIC (dev/test/staging):"
	@echo "  make up-dev          - Start dev instance (port 8080)"
	@echo "  make down-dev        - Stop dev instance"
	@echo "  make logs-dev        - Stream dev logs"
	@echo ""
	@echo "  make up-test         - Start test instance (port 8081)"
	@echo "  make down-test       - Stop test instance"
	@echo "  make logs-test       - Stream test logs"
	@echo ""
	@echo "  make up-staging      - Start staging instance (port 8082)"
	@echo "  make down-staging    - Stop staging instance"
	@echo "  make logs-staging    - Stream staging logs"
	@echo ""
	@echo "BUILD & MAINTENANCE:"
	@echo "  make build           - Build all service images"
	@echo "  make build-all       - Build all services (fresh)"
	@echo "  make clean           - Clean dev instance and remove data"
	@echo "  make health          - Check health of all services"
	@echo ""
	@echo "EXAMPLES:"
	@echo "  make up                    # Start dev"
	@echo "  make logs                  # View dev logs"
	@echo "  make multi                 # Start all 3 instances"
	@echo "  make ps                    # Show dev containers"
	@echo "  make status                # Show all instances status"
	@echo ""

# ============================================================================
# DEFAULT INSTANCE (dev)
# ============================================================================

up: up-dev

down: down-dev

logs: logs-dev

ps: ps-dev

build:
	@echo "Building images for dev instance..."
	INSTANCE_NAME=dev docker-compose build

clean: down-dev
	@echo "Removing dev instance data..."
	INSTANCE_NAME=dev docker-compose down -v

# ============================================================================
# DEV INSTANCE
# ============================================================================

up-dev:
	@echo "↳ Starting dev instance on port 8080..."
	INSTANCE_NAME=dev FRONTEND_PORT=8080 docker-compose up -d
	@echo "✓ Dev instance started"
	@echo "  Access: http://localhost:8080"

down-dev:
	@echo "↳ Stopping dev instance..."
	INSTANCE_NAME=dev docker-compose down

logs-dev:
	@echo "↳ Streaming dev instance logs (Ctrl+C to exit)..."
	INSTANCE_NAME=dev docker-compose logs -f

ps-dev:
	@echo "↳ Dev instance containers:"
	INSTANCE_NAME=dev docker-compose ps

# ============================================================================
# TEST INSTANCE
# ============================================================================

up-test:
	@echo "↳ Starting test instance on port 8081..."
	INSTANCE_NAME=test FRONTEND_PORT=8081 docker-compose up -d
	@echo "✓ Test instance started"
	@echo "  Access: http://localhost:8081"

down-test:
	@echo "↳ Stopping test instance..."
	INSTANCE_NAME=test docker-compose down

logs-test:
	@echo "↳ Streaming test instance logs (Ctrl+C to exit)..."
	INSTANCE_NAME=test docker-compose logs -f

ps-test:
	@echo "↳ Test instance containers:"
	INSTANCE_NAME=test docker-compose ps

# ============================================================================
# STAGING INSTANCE
# ============================================================================

up-staging:
	@echo "↳ Starting staging instance on port 8082..."
	INSTANCE_NAME=staging FRONTEND_PORT=8082 docker-compose up -d
	@echo "✓ Staging instance started"
	@echo "  Access: http://localhost:8082"

down-staging:
	@echo "↳ Stopping staging instance..."
	INSTANCE_NAME=staging docker-compose down

logs-staging:
	@echo "↳ Streaming staging instance logs (Ctrl+C to exit)..."
	INSTANCE_NAME=staging docker-compose logs -f

ps-staging:
	@echo "↳ Staging instance containers:"
	INSTANCE_NAME=staging docker-compose ps

# ============================================================================
# MULTI-INSTANCE MANAGEMENT
# ============================================================================

multi: up-dev up-test up-staging
	@echo ""
	@echo "╔════════════════════════════════════════════════════════════╗"
	@echo "║ ✓ All 3 instances started successfully                    ║"
	@echo "╚════════════════════════════════════════════════════════════╝"
	@echo ""
	@echo "Access instances at:"
	@echo "  • Dev:     http://localhost:8080"
	@echo "  • Test:    http://localhost:8081"
	@echo "  • Staging: http://localhost:8082"
	@echo ""
	@echo "Usage:"
	@echo "  make logs-dev      # Stream dev logs"
	@echo "  make down-all      # Stop all instances"
	@echo "  make status        # Show all instances status"
	@echo ""

down-all: down-dev down-test down-staging
	@echo "✓ All instances stopped"

clean-all:
	@echo "↳ Cleaning all instances and removing data..."
	@read -p "Are you sure? (y/N) " confirm; \
	if [ "$$confirm" = "y" ] || [ "$$confirm" = "Y" ]; then \
		INSTANCE_NAME=dev docker-compose down -v; \
		INSTANCE_NAME=test docker-compose down -v; \
		INSTANCE_NAME=staging docker-compose down -v; \
		docker volume ls -q | grep redis-data | xargs docker volume rm 2>/dev/null || true; \
		echo "✓ All instances and data cleaned"; \
	else \
		echo "Cancelled"; \
	fi

# ============================================================================
# STATUS & MONITORING
# ============================================================================

status:
	@echo "╔════════════════════════════════════════════════════════════╗"
	@echo "║ All Microservices Instances Status                        ║"
	@echo "╚════════════════════════════════════════════════════════════╝"
	@echo ""
	@docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep microservices || echo "No microservices instances running"
	@echo ""
	@echo "Instance Ports:"
	@echo "  • dev:     8080"
	@echo "  • test:    8081"
	@echo "  • staging: 8082"
	@echo ""

health:
	@echo "↳ Checking service health..."
	@echo ""
	@echo "Dev instance:"
	@INSTANCE_NAME=dev docker-compose ps --format "table {{.Service}}\t{{.Status}}" || echo "Not running"
	@echo ""
	@echo "Test instance:"
	@INSTANCE_NAME=test docker-compose ps --format "table {{.Service}}\t{{.Status}}" || echo "Not running"
	@echo ""
	@echo "Staging instance:"
	@INSTANCE_NAME=staging docker-compose ps --format "table {{.Service}}\t{{.Status}}" || echo "Not running"
	@echo ""

# ============================================================================
# BUILD & DEPLOYMENT
# ============================================================================

build-all:
	@echo "↳ Building all service images (fresh build)..."
	INSTANCE_NAME=dev docker-compose build --no-cache
	@echo "✓ Build complete"

build-clean: down-dev
	@echo "↳ Removing old images..."
	docker-compose down -v
	@echo "↳ Building fresh images..."
	INSTANCE_NAME=dev docker-compose build --no-cache
	@echo "✓ Fresh build complete"

# ============================================================================
# UTILITY COMMANDS
# ============================================================================

.PHONY: all-containers all-images volumes
all-containers:
	@echo "All microservices containers:"
	@docker ps -a | grep microservices || echo "No microservices containers found"

all-images:
	@echo "Microservices images:"
	@docker images | grep microservices || echo "No microservices images found"

volumes:
	@echo "Microservices volumes:"
	@docker volume ls -q | grep redis-data || echo "No microservices volumes found"

# ============================================================================
# CLEANUP
# ============================================================================

.PHONY: prune prune-images prune-volumes

prune: clean-all
	@echo "↳ Running Docker system prune..."
	docker system prune -f
	@echo "✓ Pruned unused resources"

prune-images:
	@echo "↳ Removing all microservices images..."
	docker images | grep microservices | awk '{print $$3}' | xargs docker rmi -f 2>/dev/null || true
	@echo "✓ Images removed"

prune-volumes:
	@echo "↳ Removing all microservices volumes..."
	docker volume ls -q | grep redis-data | xargs docker volume rm 2>/dev/null || true
	@echo "✓ Volumes removed"

# ============================================================================
# DOCUMENTATION
# ============================================================================

.PHONY: docs

docs:
	@echo "Documentation files:"
	@ls -1 | grep -E "\.md$$|DOCKER|QUICK"
	@echo ""
	@echo "Quick reference:"
	@echo "  QUICK_START.md          - Fast start guide"
	@echo "  DOCKER_COMPOSE_GUIDE.md - Comprehensive documentation"

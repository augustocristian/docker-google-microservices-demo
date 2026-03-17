#!/bin/bash

##############################################################################
# Docker Compose Deployment Helper Script
# 
# Usage:
#   ./compose-deploy.sh up dev 8080         # Start dev instance on port 8080
#   ./compose-deploy.sh down dev            # Stop dev instance
#   ./compose-deploy.sh logs dev             # View dev instance logs
#   ./compose-deploy.sh ps dev               # Show dev instance containers
#   ./compose-deploy.sh multi               # Start multiple instances demo
##############################################################################

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
ACTION="${1:-help}"
INSTANCE_NAME="${2:-dev}"
FRONTEND_PORT="${3:-8080}"

print_header() {
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║ Google Microservices Demo - Docker Compose Deployment      ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}→ $1${NC}"
}

show_help() {
    print_header
    cat << EOF

COMMANDS:
  up [INSTANCE] [PORT]     Start instance (default: dev 8080)
  down [INSTANCE]          Stop instance (default: dev)
  logs [INSTANCE]          View instance logs (default: dev)
  ps [INSTANCE]            Show instance containers (default: dev)
  build [INSTANCE]         Build images for instance (default: dev)
  multi                    Demo: Start 3 instances (dev/8080, test/8081, staging/8082)
  clean [INSTANCE]         Stop and remove all volumes (default: dev)
  help                     Show this help message

EXAMPLES:
  # Start single instance
  ./compose-deploy.sh up dev 8080
  ./compose-deploy.sh up test 8081
  ./compose-deploy.sh up prod 8082

  # Stop instance
  ./compose-deploy.sh down dev

  # View logs
  ./compose-deploy.sh logs dev

  # Start multiple demo instances
  ./compose-deploy.sh multi

  # Clean up (stop + remove volumes)
  ./compose-deploy.sh clean staging

ENVIRONMENT:
  INSTANCE_NAME    Container/network prefix (default: dev)
  FRONTEND_PORT    External port for frontend (default: 8080)
  DOCKER_COMPOSE   Override docker-compose command (default: docker-compose)

EOF
}

build_images() {
    print_info "Building images for instance: $INSTANCE_NAME"
    INSTANCE_NAME="$INSTANCE_NAME" docker-compose build
    print_success "Build complete"
}

start_instance() {
    print_header
    print_info "Starting instance: $INSTANCE_NAME"
    print_info "Frontend port: $FRONTEND_PORT"
    
    # Validate port is available
    if netstat -tuln 2>/dev/null | grep -q ":$FRONTEND_PORT " || \
       lsof -i ":$FRONTEND_PORT" 2>/dev/null; then
        print_error "Port $FRONTEND_PORT is already in use"
        exit 1
    fi
    
    print_info "Pulling/building images..."
    INSTANCE_NAME="$INSTANCE_NAME" docker-compose build --pull 2>/dev/null || true
    
    print_info "Starting containers..."
    INSTANCE_NAME="$INSTANCE_NAME" FRONTEND_PORT="$FRONTEND_PORT" docker-compose up -d
    
    print_success "Instance started"
    
    # Wait for frontend to be ready
    print_info "Waiting for frontend to be ready..."
    for i in {1..60}; do
        if docker-compose exec -T frontend curl -s http://localhost:8080 > /dev/null 2>&1; then
            print_success "Frontend is ready"
            break
        fi
        echo -n "."
        sleep 1
    done
    
    echo ""
    print_info "Access the application at: ${GREEN}http://localhost:$FRONTEND_PORT${NC}"
}

stop_instance() {
    print_info "Stopping instance: $INSTANCE_NAME"
    INSTANCE_NAME="$INSTANCE_NAME" docker-compose down
    print_success "Instance stopped"
}

show_logs() {
    local service="${3:-}"
    if [ -z "$service" ]; then
        INSTANCE_NAME="$INSTANCE_NAME" docker-compose logs -f
    else
        INSTANCE_NAME="$INSTANCE_NAME" docker-compose logs -f "$service"
    fi
}

show_ps() {
    print_info "Containers for instance: $INSTANCE_NAME"
    INSTANCE_NAME="$INSTANCE_NAME" docker-compose ps
}

clean_instance() {
    print_header
    print_error "WARNING: This will stop all containers and remove volumes"
    read -p "Are you sure? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_info "Cleaning instance: $INSTANCE_NAME"
        INSTANCE_NAME="$INSTANCE_NAME" docker-compose down -v
        print_success "Instance cleaned"
    else
        print_info "Cancelled"
    fi
}

multi_instance_demo() {
    print_header
    print_info "Starting 3 instances in parallel..."
    
    echo ""
    print_info "Instance 1: dev on port 8080"
    INSTANCE_NAME=dev FRONTEND_PORT=8080 docker-compose up -d
    
    echo ""
    print_info "Instance 2: test on port 8081"
    INSTANCE_NAME=test FRONTEND_PORT=8081 docker-compose up -d
    
    echo ""
    print_info "Instance 3: staging on port 8082"
    INSTANCE_NAME=staging FRONTEND_PORT=8082 docker-compose up -d
    
    echo ""
    print_success "All instances started"
    
    print_info "Access instances at:"
    echo "  • dev:     ${GREEN}http://localhost:8080${NC}"
    echo "  • test:    ${GREEN}http://localhost:8081${NC}"
    echo "  • staging: ${GREEN}http://localhost:8082${NC}"
    
    echo ""
    print_info "View all containers:"
    docker ps | grep "microservices"
    
    echo ""
    print_info "Stop instances with:"
    echo "  ./compose-deploy.sh down dev"
    echo "  ./compose-deploy.sh down test"
    echo "  ./compose-deploy.sh down staging"
}

# Main command dispatch
case "$ACTION" in
    up)
        start_instance
        ;;
    down)
        stop_instance
        ;;
    logs)
        show_logs "$@"
        ;;
    ps)
        show_ps
        ;;
    build)
        build_images
        ;;
    clean)
        clean_instance
        ;;
    multi)
        multi_instance_demo
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        print_error "Unknown command: $ACTION"
        echo ""
        show_help
        exit 1
        ;;
esac

# Docker Compose Deployment Helper Script for Windows
# 
# Usage:
#   .\compose-deploy.ps1 up dev 8080         # Start dev instance on port 8080
#   .\compose-deploy.ps1 down dev            # Stop dev instance
#   .\compose-deploy.ps1 logs dev             # View dev instance logs
#   .\compose-deploy.ps1 ps dev               # Show dev instance containers
#   .\compose-deploy.ps1 multi               # Start multiple instances demo

param(
    [Parameter(Position=0)]
    [ValidateSet('up', 'down', 'logs', 'ps', 'build', 'clean', 'multi', 'help', '--help', '-h')]
    [string]$Action = 'help',

    [Parameter(Position=1)]
    [string]$InstanceName = 'dev',

    [Parameter(Position=2)]
    [int]$FrontendPort = 8080
)

# Color codes for output
function Write-Success { Write-Host "✓ $args" -ForegroundColor Green }
function Write-Error { Write-Host "✗ $args" -ForegroundColor Red }
function Write-Info { Write-Host "→ $args" -ForegroundColor Yellow }
function Write-Header { Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Blue; Write-Host "║ Google Microservices Demo - Docker Compose Deployment      ║" -ForegroundColor Blue; Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Blue }

function Show-Help {
    Write-Header
    @"

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
  .\compose-deploy.ps1 up dev 8080
  .\compose-deploy.ps1 up test 8081
  .\compose-deploy.ps1 up prod 8082

  # Stop instance
  .\compose-deploy.ps1 down dev

  # View logs
  .\compose-deploy.ps1 logs dev

  # Start multiple demo instances
  .\compose-deploy.ps1 multi

  # Clean up (stop + remove volumes)
  .\compose-deploy.ps1 clean staging

"@
}

function Check-Port {
    param([int]$Port)
    
    $portInUse = Get-NetTCPConnection -LocalPort $Port -ErrorAction SilentlyContinue
    if ($portInUse) {
        Write-Error "Port $Port is already in use"
        exit 1
    }
}

function Build-Images {
    Write-Info "Building images for instance: $InstanceName"
    $env:INSTANCE_NAME = $InstanceName
    & docker-compose build
    Write-Success "Build complete"
}

function Start-Instance {
    Write-Header
    Write-Info "Starting instance: $InstanceName"
    Write-Info "Frontend port: $FrontendPort"
    
    # Validate port
    Check-Port $FrontendPort
    
    Write-Info "Pulling/building images..."
    $env:INSTANCE_NAME = $InstanceName
    & docker-compose build --pull 2>$null
    
    Write-Info "Starting containers..."
    $env:INSTANCE_NAME = $InstanceName
    $env:FRONTEND_PORT = $FrontendPort
    & docker-compose up -d
    
    Write-Success "Instance started"
    
    Write-Info "Access the application at: http://localhost:$FrontendPort"
}

function Stop-Instance {
    Write-Info "Stopping instance: $InstanceName"
    $env:INSTANCE_NAME = $InstanceName
    & docker-compose down
    Write-Success "Instance stopped"
}

function Show-Logs {
    $env:INSTANCE_NAME = $InstanceName
    & docker-compose logs -f
}

function Show-PS {
    Write-Info "Containers for instance: $InstanceName"
    $env:INSTANCE_NAME = $InstanceName
    & docker-compose ps
}

function Clean-Instance {
    Write-Header
    Write-Error "WARNING: This will stop all containers and remove volumes"
    $confirm = Read-Host "Are you sure? (y/N)"
    if ($confirm -eq 'y' -or $confirm -eq 'Y') {
        Write-Info "Cleaning instance: $InstanceName"
        $env:INSTANCE_NAME = $InstanceName
        & docker-compose down -v
        Write-Success "Instance cleaned"
    } else {
        Write-Info "Cancelled"
    }
}

function Start-MultiInstance {
    Write-Header
    Write-Info "Starting 3 instances in parallel..."
    Write-Info ""
    
    Write-Info "Instance 1: dev on port 8080"
    $env:INSTANCE_NAME = 'dev'
    $env:FRONTEND_PORT = 8080
    & docker-compose up -d
    
    Write-Info "Instance 2: test on port 8081"
    $env:INSTANCE_NAME = 'test'
    $env:FRONTEND_PORT = 8081
    & docker-compose up -d
    
    Write-Info "Instance 3: staging on port 8082"
    $env:INSTANCE_NAME = 'staging'
    $env:FRONTEND_PORT = 8082
    & docker-compose up -d
    
    Write-Info ""
    Write-Success "All instances started"
    
    Write-Info "Access instances at:"
    Write-Host "  • dev:     http://localhost:8080" -ForegroundColor Green
    Write-Host "  • test:    http://localhost:8081" -ForegroundColor Green
    Write-Host "  • staging: http://localhost:8082" -ForegroundColor Green
    
    Write-Info "View all containers:"
    & docker ps | Select-String "microservices"
    
    Write-Info "Stop instances with:"
    Write-Host "  .\compose-deploy.ps1 down dev"
    Write-Host "  .\compose-deploy.ps1 down test"
    Write-Host "  .\compose-deploy.ps1 down staging"
}

# Main command dispatch
switch ($Action) {
    'up' {
        Start-Instance
    }
    'down' {
        Stop-Instance
    }
    'logs' {
        Show-Logs
    }
    'ps' {
        Show-PS
    }
    'build' {
        Build-Images
    }
    'clean' {
        Clean-Instance
    }
    'multi' {
        Start-MultiInstance
    }
    'help' {
        Show-Help
    }
    '--help' {
        Show-Help
    }
    '-h' {
        Show-Help
    }
    default {
        Write-Error "Unknown command: $Action"
        Write-Info ""
        Show-Help
        exit 1
    }
}

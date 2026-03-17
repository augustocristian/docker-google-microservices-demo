@echo off
REM Docker Compose Multi-Instance Management Script for Windows
REM 
REM Usage:
REM   compose-multi.bat up              - Start all demo instances (dev, test, staging)
REM   compose-multi.bat down            - Stop all demo instances
REM   compose-multi.bat ps              - Show all instances
REM   compose-multi.bat logs [INSTANCE] - Show logs for instance or all
REM   compose-multi.bat clean           - Stop and remove all data
REM   compose-multi.bat help            - Show this help

setlocal enabledelayedexpansion

set "ACTION=%1"
if "%ACTION%"=="" set "ACTION=help"

set "INSTANCE=%2"

set "INSTANCES=dev test staging"
set "PORTS=8080 8081 8082"

goto %ACTION%

:up
    echo.
    echo ╔════════════════════════════════════════════════════════════╗
    echo ║ Starting Multiple Instances in Parallel                   ║
    echo ╚════════════════════════════════════════════════════════════╝
    echo.
    
    REM Parse instances and ports
    for /f "tokens=1-3" %%a in ("%INSTANCES% and %PORTS%") do (
        set "i=0"
        for %%x in (%INSTANCES%) do (
            set /a i=!i!+1
            if !i! equ 1 (
                set "instance1=%%x"
                echo [^>] Instance 1: !instance1! on port 8080
                set INSTANCE_NAME=!instance1!
                set FRONTEND_PORT=8080
                call :run_compose up
            )
            if !i! equ 2 (
                set "instance2=%%x"
                echo [^>] Instance 2: !instance2! on port 8081
                set INSTANCE_NAME=!instance2!
                set FRONTEND_PORT=8081
                call :run_compose up
            )
            if !i! equ 3 (
                set "instance3=%%x"
                echo [^>] Instance 3: !instance3! on port 8082
                set INSTANCE_NAME=!instance3!
                set FRONTEND_PORT=8082
                call :run_compose up
            )
        )
    )
    
    echo.
    echo [V] All instances started successfully
    echo.
    echo Access your instances at:
    echo   - dev:     https://localhost:8080
    echo   - test:    https://localhost:8081
    echo   - staging: https://localhost:8082
    echo.
    goto end

:down
    echo.
    echo [^>] Stopping all instances...
    for %%x in (dev test staging) do (
        echo [^>] Stopping %%x
        set INSTANCE_NAME=%%x
        call :run_compose down
    )
    echo [V] All instances stopped
    echo.
    goto end

:ps
    echo.
    echo ╔════════════════════════════════════════════════════════════╗
    echo ║ All Microservices Containers                              ║
    echo ╚════════════════════════════════════════════════════════════╝
    echo.
    docker ps | findstr "microservices" || (
        echo [X] No running microservices containers found
    )
    echo.
    goto end

:logs
    if "%INSTANCE%"=="" (
        echo [X] Please specify instance: dev, test, or staging
        echo Usage: compose-multi.bat logs [INSTANCE]
        goto end
    )
    echo.
    echo [^>] Showing logs for instance: %INSTANCE%
    echo.
    set INSTANCE_NAME=%INSTANCE%
    call :run_compose logs
    goto end

:clean
    echo.
    echo ╔════════════════════════════════════════════════════════════╗
    echo ║ WARNING: This will remove all containers and volumes      ║
    echo ╚════════════════════════════════════════════════════════════╝
    echo.
    set /p confirm="Are you sure? (y/N): "
    if /i not "%confirm%"=="y" (
        echo Cancelled
        goto end
    )
    
    echo.
    echo [^>] Cleaning all instances...
    for %%x in (dev test staging) do (
        echo [^>] Cleaning %%x
        set INSTANCE_NAME=%%x
        call :run_compose_clean
    )
    
    echo [^>] Removing unused volumes...
    for /f "tokens=*" %%x in ('docker volume ls -q ^| findstr "redis-data"') do (
        echo [^>] Removing volume: %%x
        docker volume rm %%x 2>nul
    )
    
    echo [V] Cleanup complete
    echo.
    goto end

:help
    echo.
    echo Docker Compose Multi-Instance Manager
    echo.
    echo COMMANDS:
    echo   up        - Start all demo instances (dev:8080, test:8081, staging:8082)
    echo   down      - Stop all demo instances
    echo   ps        - Show all running containers
    echo   logs      - Show logs for specific instance (dev, test, or staging)
    echo   clean     - Stop and remove all data
    echo   help      - Show this help message
    echo.
    echo EXAMPLES:
    echo   compose-multi.bat up
    echo   compose-multi.bat ps
    echo   compose-multi.bat logs dev
    echo   compose-multi.bat down
    echo   compose-multi.bat clean
    echo.
    goto end

:run_compose
    set "cmd=%1"
    if "%cmd%"=="up" (
        docker-compose up -d
    ) else if "%cmd%"=="down" (
        docker-compose down
    ) else if "%cmd%"=="logs" (
        docker-compose logs -f frontend
    )
    exit /b 0

:run_compose_clean
    docker-compose down -v 2>nul
    exit /b 0

:end
endlocal

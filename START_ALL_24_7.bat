@echo off
REM ================================================================
REM Script para iniciar todo el stack: Docker Compose + ngrok Dual
REM ================================================================
REM Este batch inicia en paralelo:
REM   1. Docker Compose (API + OLLAMA)
REM   2. ngrok Dual 24/7 (expone ambos servicios)
REM ================================================================

setlocal enabledelayedexpansion

echo.
echo ================================================================
echo  INICIANDO STACK COMPLETO: Docker Compose + ngrok Dual
echo ================================================================
echo.

REM Verificar que Docker está instalado
docker --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Docker no está instalado o no está en el PATH
    echo [INFO]  Descarga Docker desde: https://www.docker.com/products/docker-desktop
    pause
    exit /b 1
)

REM Verificar que ngrok está instalado
if not exist "C:\ngrok\ngrok.exe" (
    echo [ERROR] ngrok no encontrado en C:\ngrok\ngrok.exe
    echo [INFO]  Descarga ngrok desde: https://ngrok.com/download
    pause
    exit /b 1
)

echo [OK] Docker encontrado
echo [OK] ngrok encontrado
echo.

REM Cambiar al directorio del proyecto
cd /d "%~dp0"

echo [INFO] Directorio actual: %cd%
echo.

REM ================================================================
REM 1. INICIAR DOCKER COMPOSE EN TERMINAL SEPARADA
REM ================================================================

echo [INFO] Iniciando Docker Compose (API + OLLAMA)...
start "Docker Compose - Log Analyzer" cmd /k "docker-compose up -d && echo. && echo [SUCCESS] Docker Compose iniciado. && pause"

timeout /t 3 /nobreak

REM ================================================================
REM 2. INICIAR NGROK DUAL EN TERMINAL SEPARADA
REM ================================================================

echo [INFO] Iniciando ngrok Dual 24/7...
start "ngrok Dual 24/7" powershell -ExecutionPolicy Bypass -NoExit -File "ngrok_dual_24_7.ps1"

echo.
echo ================================================================
echo  STACK INICIADO
echo ================================================================
echo.
echo [INFO] Terminal 1: Docker Compose (logs de contenedores)
echo [INFO] Terminal 2: ngrok Dual 24/7 (monitoreo de túneles)
echo.
echo [PRÓXIMO PASO] Espera a que ambas terminales estén listas
echo [PRÓXIMO PASO] Las URLs públicas aparecerán en la terminal de ngrok
echo.
echo ================================================================
echo.

pause

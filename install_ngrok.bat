@echo off
REM Script para instalar ngrok en Windows

setlocal enabledelayedexpansion

echo ===== Instalación de ngrok =====
echo.

REM 1. Crear directorio
set NGROK_DIR=C:\ngrok
if not exist "%NGROK_DIR%" (
    mkdir "%NGROK_DIR%"
    echo [+] Directorio creado: %NGROK_DIR%
) else (
    echo [+] Directorio existe: %NGROK_DIR%
)

REM 2. Descargar ngrok
echo.
echo [*] Descargando ngrok v3 para Windows...
powershell -Command "^
    $ProgressPreference = 'SilentlyContinue'; ^
    Invoke-WebRequest -Uri 'https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-windows-amd64.zip' ^
    -OutFile 'C:\ngrok\ngrok.zip' -UseBasicParsing; ^
    Write-Host '[+] Descarga completada'
"

REM 3. Descomprimir
echo [*] Descomprimiendo ngrok...
powershell -Command "^
    Add-Type -AssemblyName 'System.IO.Compression.FileSystem'; ^
    [System.IO.Compression.ZipFile]::ExtractToDirectory('C:\ngrok\ngrok.zip', 'C:\ngrok', $true); ^
    Remove-Item 'C:\ngrok\ngrok.zip' -Force; ^
    Write-Host '[+] Descompresión completada'
"

REM 4. Agregar al PATH del sistema
echo.
echo [*] Agregando al PATH del sistema...
setx PATH "%PATH%;C:\ngrok"
echo [+] PATH actualizado

REM 5. Verificar instalación
echo.
echo [*] Verificando instalación...
if exist "C:\ngrok\ngrok.exe" (
    echo [+] ngrok.exe encontrado en C:\ngrok\ngrok.exe
    C:\ngrok\ngrok.exe --version
) else (
    echo [-] ngrok.exe NO encontrado
    exit /b 1
)

echo.
echo [+] ===== Instalación completada =====
echo.
echo Ahora debes:
echo 1. Crear cuenta en https://ngrok.com
echo 2. Ejecutar: ngrok config add-authtoken YOUR_TOKEN
echo 3. Luego ejecutar: ngrok http 5000
echo.
pause

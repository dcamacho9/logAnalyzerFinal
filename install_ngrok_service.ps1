# Script para instalar ngrok como servicio de Windows permanente
# Requiere: NSSM (Non-Sucking Service Manager)
# Uso: powershell -ExecutionPolicy Bypass -File install_ngrok_service.ps1

param(
    [string]$ServiceName = "ngrok-log-analyzer",
    [int]$Port = 5000,
    [string]$DisplayName = "ngrok Log Analyzer Agent"
)

Write-Host @"
╔═════════════════════════════════════════════════════════════════╗
║          🔧 Instalador: ngrok como Servicio de Windows         ║
║                   (Solución 24/7 Robusta)                      ║
╚═════════════════════════════════════════════════════════════════╝
"@ -ForegroundColor Cyan

# ================================
# Verificar permisos de Administrador
# ================================

$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")

if (-not $isAdmin) {
    Write-Host "❌ Este script requiere permisos de Administrador" -ForegroundColor Red
    Write-Host "   Ejecuta PowerShell como Administrador y vuelve a intentar" -ForegroundColor Yellow
    exit 1
}

Write-Host "✅ Ejecutándose como Administrador`n" -ForegroundColor Green

# ================================
# Verificar ngrok
# ================================

Write-Host "📦 Verificando ngrok..." -ForegroundColor Yellow

$ngrokCmd = Get-Command ngrok -ErrorAction SilentlyContinue

if (-not $ngrokCmd) {
    Write-Host "❌ ngrok no está instalado" -ForegroundColor Red
    Write-Host "`n   Opciones:" -ForegroundColor Yellow
    Write-Host "   1. Descargar: https://ngrok.com/download" -ForegroundColor White
    Write-Host "   2. O instalar con: choco install ngrok" -ForegroundColor White
    exit 1
}

Write-Host "✅ ngrok encontrado en: $($ngrokCmd.Source)`n" -ForegroundColor Green

# ================================
# Descargar e instalar NSSM
# ================================

Write-Host "📦 Verificando NSSM (Non-Sucking Service Manager)..." -ForegroundColor Yellow

$nssmPath = "C:\Program Files\nssm\nssm.exe"

if (-not (Test-Path $nssmPath)) {
    Write-Host "`n⚙️  NSSM no encontrado. Descargando..." -ForegroundColor Yellow
    
    $nssmDir = "C:\Program Files\nssm"
    
    if (-not (Test-Path $nssmDir)) {
        New-Item -ItemType Directory -Path $nssmDir -Force | Out-Null
        Write-Host "   ✅ Directorio creado: $nssmDir" -ForegroundColor Green
    }
    
    try {
        # Descargar NSSM
        $nssmUrl = "https://nssm.cc/download/nssm-2.24-101-g897c7ad.zip"
        $zipPath = "$nssmDir\nssm.zip"
        
        Write-Host "   Descargando desde: $nssmUrl" -ForegroundColor Cyan
        Invoke-WebRequest -Uri $nssmUrl -OutFile $zipPath -TimeoutSec 30
        
        # Extraer NSSM
        Write-Host "   ✅ Descarga completada. Extrayendo..." -ForegroundColor Green
        Expand-Archive -Path $zipPath -DestinationPath $nssmDir -Force
        
        # Encontrar nssm.exe
        $nssmExe = Get-ChildItem -Path $nssmDir -Filter "nssm.exe" -Recurse | Select-Object -First 1
        
        if ($nssmExe) {
            Copy-Item -Path $nssmExe.FullName -Destination $nssmPath -Force
            Write-Host "   ✅ NSSM instalado: $nssmPath" -ForegroundColor Green
        }
        
        # Limpiar
        Remove-Item -Path $zipPath -Force -ErrorAction SilentlyContinue
        
    }
    catch {
        Write-Host "   ❌ Error descargando NSSM: $_" -ForegroundColor Red
        Write-Host "   Descarga manual desde: https://nssm.cc/download" -ForegroundColor Yellow
        exit 1
    }
}
else {
    Write-Host "✅ NSSM encontrado en: $nssmPath`n" -ForegroundColor Green
}

# ================================
# Crear Servicio Windows
# ================================

Write-Host "⚙️  Creando servicio Windows..." -ForegroundColor Yellow
Write-Host "   Nombre: $ServiceName" -ForegroundColor Cyan
Write-Host "   Display Name: $DisplayName" -ForegroundColor Cyan
Write-Host "   Puerto: $Port`n" -ForegroundColor Cyan

# Obtener ruta completa de ngrok
$ngrokFullPath = $ngrokCmd.Source

try {
    # Verificar si el servicio ya existe
    $existingService = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
    
    if ($existingService) {
        Write-Host "⚠️  Servicio ya existe. Deteniéndolo..." -ForegroundColor Yellow
        Stop-Service -Name $ServiceName -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 2
        
        Write-Host "   Eliminando servicio anterior..." -ForegroundColor Cyan
        & $nssmPath remove $ServiceName confirm
        Start-Sleep -Seconds 2
    }
    
    # Crear nuevo servicio
    Write-Host "   Instalando nuevo servicio..." -ForegroundColor Cyan
    & $nssmPath install $ServiceName $ngrokFullPath "http $Port"
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "   ✅ Servicio instalado" -ForegroundColor Green
    }
    else {
        Write-Host "   ❌ Error al instalar servicio" -ForegroundColor Red
        exit 1
    }
    
    # Configurar el servicio
    Write-Host "   Configurando parámetros del servicio..." -ForegroundColor Cyan
    
    # Descripción
    & $nssmPath set $ServiceName Description "ngrok - Expone Log Analyzer Agent a internet de forma permanente"
    
    # Reinicio automático
    & $nssmPath set $ServiceName AppRestartDelay 5000
    & $nssmPath set $ServiceName AppExit Default Restart
    
    # Display name
    & $nssmPath set $ServiceName DisplayName $DisplayName
    
    # Inicio automático
    & $nssmPath set $ServiceName Start SERVICE_AUTO_START
    
    Write-Host "   ✅ Parámetros configurados" -ForegroundColor Green
    
    # Iniciar servicio
    Write-Host "   Iniciando servicio..." -ForegroundColor Cyan
    Start-Service -Name $ServiceName -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 5
    
    # Verificar estado
    $service = Get-Service -Name $ServiceName
    
    if ($service.Status -eq "Running") {
        Write-Host "   ✅ Servicio iniciado correctamente" -ForegroundColor Green
    }
    else {
        Write-Host "   ⚠️  Servicio en estado: $($service.Status)" -ForegroundColor Yellow
    }
    
}
catch {
    Write-Host "   ❌ Error: $_" -ForegroundColor Red
    exit 1
}

# ================================
# Crear Script de Monitoreo Adicional
# ================================

Write-Host "`n📝 Creando script de monitoreo complementario..." -ForegroundColor Yellow

$monitorScript = @"
# Script de monitoreo que se ejecuta como tarea programada
# Verifica cada 5 minutos si ngrok está funcionando

`$serviceName = "$ServiceName"

`$service = Get-Service -Name `$serviceName -ErrorAction SilentlyContinue

if (`$service.Status -ne "Running") {
    `$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path "C:\logs\ngrok-monitor.log" -Value "`$timestamp - Servicio `$serviceName no estaba activo. Reiniciando..."
    
    try {
        Start-Service -Name `$serviceName
    }
    catch {
        Add-Content -Path "C:\logs\ngrok-monitor.log" -Value "`$timestamp - Error al reiniciar: `$_"
    }
}
"@

$monitorScriptPath = "C:\Program Files\nssm\ngrok-monitor.ps1"
Set-Content -Path $monitorScriptPath -Value $monitorScript

Write-Host "   ✅ Script creado en: $monitorScriptPath" -ForegroundColor Green

# ================================
# Crear Tarea Programada de Windows (Opcional)
# ================================

Write-Host "`n📅 Creando Tarea Programada (Health Check cada 5 minutos)..." -ForegroundColor Yellow

$taskName = "ngrok-Monitor"
$taskDescription = "Monitorea y reinicia ngrok si es necesario"

$trigger = New-ScheduledTaskTrigger -AtLogOn
$repeatTrigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 5) -RepetitionDuration (New-TimeSpan -Days 36500)

$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File `"$monitorScriptPath`""

$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -RunWithoutNetwork

try {
    Register-ScheduledTask -TaskName $taskName `
                          -Description $taskDescription `
                          -Action $action `
                          -Trigger $repeatTrigger `
                          -Settings $settings `
                          -Force `
                          -ErrorAction Stop | Out-Null
    
    Write-Host "   ✅ Tarea programada creada: $taskName" -ForegroundColor Green
}
catch {
    Write-Host "   ⚠️  No se pudo crear la tarea programada: $_" -ForegroundColor Yellow
}

# ================================
# Resumen Final
# ================================

Write-Host @"
╔═════════════════════════════════════════════════════════════════╗
║                    ✅ INSTALACIÓN COMPLETADA                   ║
╚═════════════════════════════════════════════════════════════════╝

📋 INFORMACIÓN DEL SERVICIO:
   Nombre:          $ServiceName
   Estado:          $($service.Status)
   Inicio:          Automático (en cada reinicio)

🔗 ACCESO:
   ngrok API:       http://localhost:4040/api/tunnels (desde el equipo)
   Puerto Local:    $Port
   URL Pública:     Se obtiene en tiempo real desde ngrok

🛠️  COMANDOS ÚTILES:

   Ver estado del servicio:
   > Get-Service $ServiceName

   Ver la URL pública actual:
   > `$(Invoke-WebRequest -Uri 'http://localhost:4040/api/tunnels' -TimeoutSec 5).Content | ConvertFrom-Json

   Detener servicio:
   > Stop-Service $ServiceName

   Reiniciar servicio:
   > Restart-Service $ServiceName

   Ver logs:
   > Get-EventLog -LogName System -Source nssm-$ServiceName -Newest 10

📊 MONITOREO ADICIONAL:
   - Tarea programada: $taskName (cada 5 minutos)
   - Log: C:\logs\ngrok-monitor.log

⚠️  NOTAS IMPORTANTES:
   - El servicio se inicia automáticamente al encender el PC
   - Se reinicia automáticamente si falla
   - La URL pública cambia (ngrok gratis)
   - Para URL estática, actualiza a ngrok Pro: https://ngrok.com/pricing

"@ -ForegroundColor Green

Write-Host "Presiona cualquier tecla para salir..." -ForegroundColor Gray
Read-Host

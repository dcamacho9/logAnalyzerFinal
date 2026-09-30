# Script para mantener ngrok activo 24/7 con TWO túneles (API + OLLAMA)
# Uso: powershell -ExecutionPolicy Bypass -File ngrok_dual_24_7.ps1
# 
# Expone:
#   - API en puerto 5000
#   - OLLAMA en puerto 11434

param(
    [int]$ApiPort = 5000,
    [int]$OllamaPort = 11434,
    [int]$HealthCheckIntervalSeconds = 60,
    [bool]$AutoRestart = $true
)

$script:Config = @{
    ApiPort = $ApiPort
    OllamaPort = $OllamaPort
    HealthCheckInterval = $HealthCheckIntervalSeconds
    AutoRestart = $AutoRestart
    LogFile = ".\ngrok_dual_24_7.log"
    StartTime = Get-Date
    RestartCount = 0
    FailureCount = @{ API = 0; OLLAMA = 0 }
    ProcessIds = @{ API = $null; OLLAMA = $null }
}

# ================================
# Funciones de Utilidad
# ================================

function Write-Log {
    param([string]$Message, [string]$Level = "INFO", [string]$Service = "CORE")
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Service] [$Level] $Message"
    
    Write-Host $logMessage -ForegroundColor $(
        switch ($Level) {
            "ERROR" { "Red" }
            "WARN" { "Yellow" }
            "SUCCESS" { "Green" }
            "INFO" { "Cyan" }
            default { "White" }
        }
    )
    
    Add-Content -Path $script:Config.LogFile -Value $logMessage
}

function Get-NgrokStatus {
    param([int]$Port)
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:4040/api/tunnels" `
            -Method GET -TimeoutSec 5 -ErrorAction Stop
        return $response.StatusCode -eq 200
    }
    catch {
        return $false
    }
}

function Get-NgrokTunnels {
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:4040/api/tunnels" `
            -TimeoutSec 5 -ErrorAction Stop
        $data = $response.Content | ConvertFrom-Json
        return $data.tunnels
    }
    catch {
        return $null
    }
}

function Get-TunnelUrl {
    param([string]$ServiceName, [int]$LocalPort)
    
    try {
        $tunnels = Get-NgrokTunnels
        if (-not $tunnels) { return $null }
        
        # Buscar el túnel con el nombre correcto
        $tunnel = $tunnels | Where-Object { 
            $_.name -eq $ServiceName -and $_.proto -eq "https"
        } | Select-Object -First 1
        
        if ($tunnel) {
            return $tunnel.public_url
        }
        return $null
    }
    catch {
        return $null
    }
}

function Start-NgrokProcess {
    param([string]$Service, [int]$LocalPort)
    
    Write-Log "Iniciando ngrok para $Service en puerto $LocalPort..." "WARN" $Service
    
    try {
        # Usar ngrok config file para múltiples túneles o iniciar por separado
        # Para simplificar, usaremos ngrok cli directo
        $process = Start-Process -FilePath "C:\ngrok\ngrok.exe" `
            -ArgumentList "http", $LocalPort, "--log=stdout", "--log-level=info" `
            -PassThru -NoNewWindow -ErrorAction Stop
        
        Write-Log "Proceso iniciado (PID: $($process.Id))" "SUCCESS" $Service
        $script:Config.ProcessIds.$Service = $process.Id
        $script:Config.RestartCount++
        $script:Config.FailureCount.$Service = 0
        
        # Esperar a que ngrok esté listo
        $maxRetries = 15
        $retry = 0
        
        while ($retry -lt $maxRetries) {
            Start-Sleep -Seconds 2
            if (Get-NgrokStatus -Port $LocalPort) {
                Write-Log "$Service conectado exitosamente" "SUCCESS" $Service
                $url = Get-TunnelUrl -ServiceName $Service -LocalPort $LocalPort
                if ($url) {
                    Write-Log "URL Pública: $url" "SUCCESS" $Service
                    # Guardar URL en archivo para consulta rápida
                    "$Service URL: $url" | Out-File -FilePath ".\ngrok_${Service}_url.txt" -Encoding UTF8
                }
                return $true
            }
            $retry++
        }
        
        Write-Log "No conectó después de 30 segundos" "ERROR" $Service
        return $false
    }
    catch {
        Write-Log "Error al iniciar: $_" "ERROR" $Service
        return $false
    }
}

function Test-ServiceHealth {
    param([string]$Service, [int]$LocalPort)
    
    # Verificar si el proceso sigue vivo
    $process = Get-Process -Id $script:Config.ProcessIds.$Service -ErrorAction SilentlyContinue
    if (-not $process) {
        Write-Log "Proceso no existe (PID: $($script:Config.ProcessIds.$Service))" "ERROR" $Service
        return $false
    }
    
    # Verificar conexión ngrok
    $isHealthy = Get-NgrokStatus -Port $LocalPort
    
    if ($isHealthy) {
        $script:Config.FailureCount.$Service = 0
        Write-Log "Activo y funcionando" "SUCCESS" $Service
        
        $url = Get-TunnelUrl -ServiceName $Service -LocalPort $LocalPort
        if ($url) {
            Write-Log "URL: $url" "INFO" $Service
        }
        return $true
    }
    else {
        $script:Config.FailureCount.$Service++
        Write-Log "No responde (Fallo #$($script:Config.FailureCount.$Service))" "ERROR" $Service
        
        if ($script:Config.AutoRestart -and $script:Config.FailureCount.$Service -ge 2) {
            Write-Log "Reintentando reinicio automático..." "WARN" $Service
            return $false
        }
        return $true
    }
}

function Invoke-Cleanup {
    Write-Log "Limpiando procesos..." "WARN" "CLEANUP"
    
    if ($script:Config.ProcessIds.API) {
        Stop-Process -Id $script:Config.ProcessIds.API -ErrorAction SilentlyContinue
        Write-Log "Proceso API terminado" "INFO" "CLEANUP"
    }
    
    if ($script:Config.ProcessIds.OLLAMA) {
        Stop-Process -Id $script:Config.ProcessIds.OLLAMA -ErrorAction SilentlyContinue
        Write-Log "Proceso OLLAMA terminado" "INFO" "CLEANUP"
    }
}

# Cleanup al salir
Register-EngineEvent -SourceIdentifier PowerShell.Exiting -Action {
    Invoke-Cleanup
} | Out-Null

# ================================
# Inicialización
# ================================

Write-Host ""
Write-Host "=================================================="
Write-Host "ngrok Dual 24/7 - Monitor y Controlador"
Write-Host "API (5000) + OLLAMA (11434)"
Write-Host "=================================================="
Write-Host ""

Write-Log "===============================================" "INFO"
Write-Log "Script ngrok Dual 24/7 iniciado" "INFO"
Write-Log "Puerto API: $ApiPort" "INFO"
Write-Log "Puerto OLLAMA: $OllamaPort" "INFO"
Write-Log "Auto-Restart: $AutoRestart" "INFO"
Write-Log "Health Check cada: ${HealthCheckIntervalSeconds}s" "INFO"
Write-Log "Log: $($script:Config.LogFile)" "INFO"
Write-Log "===============================================" "INFO"

# Verificar ngrok
if (-not (Test-Path "C:\ngrok\ngrok.exe")) {
    Write-Log "ERROR: ngrok no encontrado en C:\ngrok\ngrok.exe" "ERROR"
    Write-Log "Descarga desde: https://ngrok.com/download" "WARN"
    exit 1
}

Write-Log "ngrok encontrado en C:\ngrok\ngrok.exe" "SUCCESS"

# Matar procesos ngrok anteriores
Write-Log "Limpiando procesos ngrok anteriores..." "WARN"
Stop-Process -Name ngrok -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2

# Iniciar ambos servicios
if (-not (Start-NgrokProcess -Service "API" -LocalPort $ApiPort)) {
    Write-Log "Error crítico al iniciar API" "ERROR"
    exit 1
}

Start-Sleep -Seconds 3

if (-not (Start-NgrokProcess -Service "OLLAMA" -LocalPort $OllamaPort)) {
    Write-Log "Error al iniciar OLLAMA (continuando con API)" "WARN"
}

# ================================
# Loop de Monitoreo Principal
# ================================

$lastHealthCheck = Get-Date
$lastUrlNotification = Get-Date

Write-Host ""
Write-Host "Monitor iniciado. Presiona Ctrl+C para detener" -ForegroundColor Green
Write-Host ""

while ($true) {
    $now = Get-Date
    $uptime = $now - $script:Config.StartTime
    
    # Health check periódico
    if (($now - $lastHealthCheck).TotalSeconds -ge $script:Config.HealthCheckInterval) {
        Write-Log "─────────────────────────────────────────" "INFO"
        Write-Log "Verificando salud de servicios..." "INFO"
        
        $apiHealth = Test-ServiceHealth -Service "API" -LocalPort $ApiPort
        if (-not $apiHealth -and $script:Config.AutoRestart) {
            Write-Log "Reiniciando API..." "WARN" "API"
            Invoke-Cleanup
            Start-Sleep -Seconds 3
            Start-NgrokProcess -Service "API" -LocalPort $ApiPort
        }
        
        $ollamaHealth = Test-ServiceHealth -Service "OLLAMA" -LocalPort $OllamaPort
        if (-not $ollamaHealth -and $script:Config.AutoRestart) {
            Write-Log "Reiniciando OLLAMA..." "WARN" "OLLAMA"
            Start-NgrokProcess -Service "OLLAMA" -LocalPort $OllamaPort
        }
        
        $lastHealthCheck = $now
        Write-Log "─────────────────────────────────────────" "INFO"
    }
    
    # Mostrar URLs cada 5 minutos
    if (($now - $lastUrlNotification).TotalSeconds -ge 300) {
        $hoursUp = $uptime.Hours
        $minutesUp = $uptime.Minutes
        $secondsUp = $uptime.Seconds
        
        Write-Host ""
        Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Green
        Write-Host "║           INFORMACIÓN DE TÚNELES NGROK ACTIVOS             ║" -ForegroundColor Green
        Write-Host "╠════════════════════════════════════════════════════════════╣" -ForegroundColor Green
        
        $apiUrl = Get-TunnelUrl -ServiceName "API" -LocalPort $ApiPort
        if ($apiUrl) {
            Write-Host "║ API (puerto $ApiPort):" -ForegroundColor Cyan
            Write-Host "║   $apiUrl" -ForegroundColor Yellow
        }
        
        $ollamaUrl = Get-TunnelUrl -ServiceName "OLLAMA" -LocalPort $OllamaPort
        if ($ollamaUrl) {
            Write-Host "║" -ForegroundColor Green
            Write-Host "║ OLLAMA (puerto $OllamaPort):" -ForegroundColor Cyan
            Write-Host "║   $ollamaUrl" -ForegroundColor Yellow
        }
        
        Write-Host "║" -ForegroundColor Green
        Write-Host "║ Tiempo activo: ${hoursUp}h ${minutesUp}m ${secondsUp}s" -ForegroundColor Cyan
        Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Green
        Write-Host ""
        
        $lastUrlNotification = $now
    }
    
    Start-Sleep -Seconds 10
}

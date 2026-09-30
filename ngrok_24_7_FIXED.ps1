# Script para mantener ngrok activo 24/7 con monitoreo y reintentos
# Uso: powershell -ExecutionPolicy Bypass -File ngrok_24_7_FIXED.ps1

param(
    [int]$Port = 5000,
    [int]$RestartDelaySeconds = 30,
    [int]$HealthCheckIntervalSeconds = 60,
    [bool]$AutoRestart = $true
)

$script:Config = @{
    Port = $Port
    RestartDelay = $RestartDelaySeconds
    HealthCheckInterval = $HealthCheckIntervalSeconds
    AutoRestart = $AutoRestart
    LogFile = ".\ngrok_24_7.log"
    StartTime = Get-Date
    RestartCount = 0
    FailureCount = 0
}

# ================================
# Funciones de Utilidad
# ================================

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    
    Write-Host $logMessage -ForegroundColor $(
        switch ($Level) {
            "ERROR" { "Red" }
            "WARN" { "Yellow" }
            "SUCCESS" { "Green" }
            default { "White" }
        }
    )
    
    Add-Content -Path $script:Config.LogFile -Value $logMessage
}

function Get-NgrokStatus {
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:4040/api/tunnels" -Method GET -TimeoutSec 5 -ErrorAction Stop
        return $response.StatusCode -eq 200
    }
    catch {
        return $false
    }
}

function Get-NgrokUrl {
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:4040/api/tunnels" -TimeoutSec 5 -ErrorAction Stop
        $data = $response.Content | ConvertFrom-Json
        
        $httpTunnel = $data.tunnels | Where-Object { $_.proto -eq "https" } | Select-Object -First 1
        
        if ($httpTunnel) {
            return $httpTunnel.public_url
        }
        return $null
    }
    catch {
        return $null
    }
}

function Start-NgrokProcess {
    Write-Log "Iniciando ngrok en puerto $($script:Config.Port)..." "WARN"
    
    try {
        # Matar procesos ngrok anteriores
        $existingProcess = Get-Process ngrok -ErrorAction SilentlyContinue
        if ($existingProcess) {
            Write-Log "Terminando proceso ngrok anterior (PID: $($existingProcess.Id))" "WARN"
            Stop-Process -Id $existingProcess.Id -Force -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 2
        }
        
        # Iniciar nuevo proceso ngrok
        $process = Start-Process -FilePath "C:\ngrok\ngrok.exe" -ArgumentList "http $($script:Config.Port)" -PassThru -NoNewWindow -ErrorAction Stop
        
        Write-Log "ngrok iniciado (PID: $($process.Id))" "SUCCESS"
        $script:Config.RestartCount++
        $script:Config.FailureCount = 0
        
        # Esperar a que ngrok esté listo
        $maxRetries = 10
        $retry = 0
        
        while ($retry -lt $maxRetries) {
            Start-Sleep -Seconds 3
            if (Get-NgrokStatus) {
                Write-Log "ngrok conectado exitosamente" "SUCCESS"
                $url = Get-NgrokUrl
                if ($url) {
                    Write-Log "URL Publica: $url" "SUCCESS"
                }
                return $true
            }
            $retry++
        }
        
        Write-Log "ngrok no respondio despues de 30 segundos" "ERROR"
        return $false
    }
    catch {
        Write-Log "Error al iniciar ngrok: $_" "ERROR"
        return $false
    }
}

function Test-NgrokHealth {
    $isHealthy = Get-NgrokStatus
    
    if ($isHealthy) {
        $script:Config.FailureCount = 0
        Write-Log "ngrok esta activo y funcionando" "SUCCESS"
        
        $url = Get-NgrokUrl
        if ($url) {
            Write-Log "URL: $url" "INFO"
        }
        return $true
    }
    else {
        $script:Config.FailureCount++
        Write-Log "ngrok no responde (Fallo #$($script:Config.FailureCount))" "ERROR"
        
        if ($script:Config.AutoRestart -and $script:Config.FailureCount -ge 2) {
            Write-Log "Reintentando reinicio automatico..." "WARN"
            return $false
        }
        return $true
    }
}

# ================================
# Inicializacion
# ================================

Write-Host ""
Write-Host "======================================"
Write-Host "ngrok 24/7 - Monitor y Controlador"
Write-Host "======================================"
Write-Host ""

Write-Log "===============================================" "INFO"
Write-Log "Script ngrok 24/7 iniciado" "INFO"
Write-Log "Puerto: $Port" "INFO"
Write-Log "Auto-Restart: $AutoRestart" "INFO"
Write-Log "Health Check cada: ${HealthCheckIntervalSeconds}s" "INFO"
Write-Log "Log: $($script:Config.LogFile)" "INFO"
Write-Log "===============================================" "INFO"

# Verificar ngrok
if (-not (Test-Path "C:\ngrok\ngrok.exe")) {
    Write-Log "ERROR: ngrok no encontrado en C:\ngrok\ngrok.exe" "ERROR"
    Write-Log "Descarga ngrok desde: https://ngrok.com/download" "WARN"
    exit 1
}

Write-Log "OK: ngrok encontrado" "SUCCESS"

# Iniciar ngrok
if (-not (Start-NgrokProcess)) {
    Write-Log "Error critico al iniciar ngrok" "ERROR"
    exit 1
}

# ================================
# Loop de Monitoreo Principal
# ================================

$lastHealthCheck = Get-Date
$lastUrlNotification = Get-Date

while ($true) {
    $now = Get-Date
    $uptime = $now - $script:Config.StartTime
    
    # Health check periodico
    if (($now - $lastHealthCheck).TotalSeconds -ge $script:Config.HealthCheckInterval) {
        if (-not (Test-NgrokHealth)) {
            if ($script:Config.AutoRestart) {
                Write-Log "Reiniciando ngrok..." "WARN"
                if (-not (Start-NgrokProcess)) {
                    Write-Log "Error al reiniciar ngrok" "ERROR"
                }
            }
        }
        $lastHealthCheck = $now
    }
    
    # Mostrar URL cada 5 minutos
    if (($now - $lastUrlNotification).TotalSeconds -ge 300) {
        $url = Get-NgrokUrl
        if ($url) {
            $hoursUp = $uptime.Hours
            $minutesUp = $uptime.Minutes
            Write-Log "URL actual: $url (Tiempo activo: ${hoursUp}h ${minutesUp}m)" "INFO"
        }
        $lastUrlNotification = $now
    }
    
    Start-Sleep -Seconds 10
}

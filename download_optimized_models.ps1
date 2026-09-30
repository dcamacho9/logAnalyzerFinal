# Script para descargar y configurar modelos OLLAMA optimizados
# Uso: .\download_optimized_models.ps1

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "OLLAMA Model Download Manager" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Verificar si OLLAMA esta ejecutandose
Write-Host "Checking if Ollama is running..." -ForegroundColor Yellow

try {
    $response = Invoke-WebRequest -Uri "http://localhost:11434/api/tags" `
        -Method GET `
        -TimeoutSec 5 `
        -ErrorAction Stop
    
    $data = $response.Content | ConvertFrom-Json
    $models = $data.models
    
    Write-Host "[OK] Ollama is running" -ForegroundColor Green
    Write-Host ""
    Write-Host "Currently installed models:" -ForegroundColor Cyan
    
    if ($models.Count -gt 0) {
        foreach ($model in $models) {
            $name = $model.name
            $size = [math]::Round($model.size / 1GB, 2)
            Write-Host "  - $name ($size GB)" -ForegroundColor Green
        }
    } else {
        Write-Host "  (No models installed)" -ForegroundColor Yellow
    }
    
    Write-Host ""
    
} catch {
    Write-Host "[ERROR] Ollama is not running" -ForegroundColor Red
    Write-Host "Start Ollama first: ollama serve" -ForegroundColor Yellow
    Write-Host ""
    exit 1
}

# Modelos disponibles
$recommendedModels = @(
    @{
        name = "mistral:7b"
        size = "4GB"
        speed = "[FAST] Rapido"
        precision = "Muy buena"
        recommended = $true
        estimated_time = "3-5 min"
    },
    @{
        name = "phi:2.7b"
        size = "1.6GB"
        speed = "[VERY FAST] Muy Rapido"
        precision = "Buena"
        recommended = $false
        estimated_time = "2-3 min"
    },
    @{
        name = "neural-chat:7b"
        size = "4GB"
        speed = "[FAST] Rapido"
        precision = "Muy buena"
        recommended = $false
        estimated_time = "3-5 min"
    },
    @{
        name = "orca-mini:3b"
        size = "2GB"
        speed = "[VERY FAST] Muy Rapido"
        precision = "Aceptable"
        recommended = $false
        estimated_time = "2-3 min"
    }
)

Write-Host "Available optimized models:" -ForegroundColor Cyan
Write-Host ""

for ($i = 0; $i -lt $recommendedModels.Count; $i++) {
    $model = $recommendedModels[$i]
    $badge = if ($model.recommended) { "[RECOMMENDED] " } else { "" }
    
    Write-Host "$($i+1). $badge$($model.name)" -ForegroundColor Green
    Write-Host "   Size: $($model.size) | Speed: $($model.speed)" -ForegroundColor Yellow
    Write-Host "   Precision: $($model.precision) | Est. Time: $($model.estimated_time)" -ForegroundColor Cyan
    Write-Host ""
}

# Pregunta al usuario qué modelo descargar
Write-Host "Enter model number to download (1-$($recommendedModels.Count)) or 'all' to download all, or 'q' to quit:" -ForegroundColor Yellow
$choice = Read-Host "Choice"

if ($choice -eq 'q') {
    Write-Host "Exiting..." -ForegroundColor Yellow
    exit 0
}

$modelsToDownload = @()

if ($choice -eq 'all') {
    $modelsToDownload = $recommendedModels
} else {
    $choiceInt = [int]$choice - 1
    if ($choiceInt -ge 0 -and $choiceInt -lt $recommendedModels.Count) {
        $modelsToDownload = @($recommendedModels[$choiceInt])
    } else {
        Write-Host "Invalid choice" -ForegroundColor Red
        exit 1
    }
}

Write-Host ""
Write-Host "Starting download..." -ForegroundColor Cyan
Write-Host ""

$startTime = Get-Date
$successCount = 0
$failCount = 0

foreach ($model in $modelsToDownload) {
    $modelName = $model.name
    
    Write-Host "Downloading $modelName..." -ForegroundColor Yellow
    
    try {
        $modelStart = Get-Date
        
        # Ejecutar ollama pull
        $output = & ollama pull $modelName 2>&1
        
        $modelElapsed = (Get-Date) - $modelStart
        
        Write-Host "[OK] Downloaded $modelName in $([math]::Round($modelElapsed.TotalSeconds, 1))s" -ForegroundColor Green
        $successCount++
        
    } catch {
        Write-Host "[FAIL] Failed to download $modelName" -ForegroundColor Red
        Write-Host "Error: $_" -ForegroundColor Red
        $failCount++
    }
    
    Write-Host ""
}

# Resumen
$totalElapsed = (Get-Date) - $startTime

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "DOWNLOAD SUMMARY" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "[OK] Successful: $successCount" -ForegroundColor Green
Write-Host "[FAIL] Failed: $failCount" -ForegroundColor Red
Write-Host "Total time: $([math]::Round($totalElapsed.TotalMinutes, 1)) minutes" -ForegroundColor Cyan
Write-Host ""

# Verificar modelos instalados
Write-Host "Checking installed models..." -ForegroundColor Yellow
Write-Host ""

try {
    $response = Invoke-WebRequest -Uri "http://localhost:11434/api/tags" `
        -Method GET `
        -TimeoutSec 5 `
        -ErrorAction Stop
    
    $data = $response.Content | ConvertFrom-Json
    $models = $data.models
    
    Write-Host "Final installed models:" -ForegroundColor Cyan
    
    foreach ($model in $models) {
        $name = $model.name
        $size = [math]::Round($model.size / 1GB, 2)
        Write-Host "  - $name ($size GB)" -ForegroundColor Green
    }
    
} catch {
    Write-Host "Could not verify models" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1. Update docker-compose.yml with OLLAMA_MODEL=$($modelsToDownload[0].name)" -ForegroundColor Yellow
Write-Host "2. Run: docker-compose -f docker-compose-optimized.yml up -d" -ForegroundColor Yellow
Write-Host "3. Test: .\test_latency_optimized.ps1" -ForegroundColor Yellow
Write-Host ""

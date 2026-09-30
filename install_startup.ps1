# Script para instalar el launcher automático en Windows
# Uso: powershell -ExecutionPolicy Bypass -File install_startup.ps1

param(
    [switch]$Remove
)

$projectPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$managerBat = Join-Path $projectPath "manager.bat"
$startupFolder = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup"
$shortcutPath = Join-Path $startupFolder "Log-Analyzer-Stack.lnk"

function Create-StartupShortcut {
    try {
        # Crear objeto COM de WScript.Shell
        $shell = New-Object -ComObject WScript.Shell
        
        # Crear acceso directo
        $shortcut = $shell.CreateShortcut($shortcutPath)
        $shortcut.TargetPath = "cmd.exe"
        $shortcut.Arguments = "/k `"$managerBat start`""
        $shortcut.WorkingDirectory = $projectPath
        $shortcut.WindowStyle = 1  # Normal
        $shortcut.IconLocation = "cmd.exe,0"
        $shortcut.Description = "Inicia el stack permanente: API + OLLAMA + ngrok"
        
        # Guardar
        $shortcut.Save()
        
        Write-Host "✅ Acceso directo creado en:" -ForegroundColor Green
        Write-Host "   $shortcutPath" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "ℹ️  El stack iniciará automáticamente cuando enciendes Windows"
        Write-Host ""
        
        # Ofrecer opción de ejecutar ahora
        $response = Read-Host "¿Deseas iniciar el stack ahora? (S/N)"
        if ($response -eq "S" -or $response -eq "s") {
            Write-Host "Iniciando stack..." -ForegroundColor Yellow
            & cmd /k "$managerBat start"
        }
    }
    catch {
        Write-Host "❌ Error al crear acceso directo:" -ForegroundColor Red
        Write-Host "   $_" -ForegroundColor Red
        exit 1
    }
}

function Remove-StartupShortcut {
    try {
        if (Test-Path $shortcutPath) {
            Remove-Item $shortcutPath -Force
            Write-Host "✅ Acceso directo removido" -ForegroundColor Green
        } else {
            Write-Host "ℹ️  No hay acceso directo instalado" -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "❌ Error al remover acceso directo:" -ForegroundColor Red
        Write-Host "   $_" -ForegroundColor Red
        exit 1
    }
}

# Verificar permisos
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "⚠️  Este script requiere permisos de administrador" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Reiniciando con permisos elevados..." -ForegroundColor Cyan
    Start-Process powershell -ArgumentList "-ExecutionPolicy Bypass -File `"$($MyInvocation.MyCommand.Path)`" $args" -Verb RunAs
    exit
}

Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║     Instalador de Stack Automático - Log Analyzer         ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

if ($Remove) {
    Write-Host "Removiendo acceso directo de inicio..." -ForegroundColor Yellow
    Remove-StartupShortcut
}
else {
    Write-Host "Creando acceso directo de inicio automático..." -ForegroundColor Yellow
    Write-Host "Directorio del proyecto: $projectPath" -ForegroundColor Gray
    Write-Host ""
    Create-StartupShortcut
}

Write-Host ""

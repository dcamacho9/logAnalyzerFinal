@echo off
REM Script para iniciar Ollama después de la instalación

echo.
echo ================================================
echo    Iniciando Ollama...
echo ================================================
echo.

REM Intenta ejecutar ollama desde diferentes ubicaciones
for %%P in (
    "%LOCALAPPDATA%\Programs\Ollama\ollama.exe"
    "%APPDATA%\Ollama\ollama.exe"
    "C:\Program Files\Ollama\ollama.exe"
    "C:\Program Files (x86)\Ollama\ollama.exe"
) do (
    if exist %%P (
        echo Encontrado: %%P
        echo.
        echo Iniciando ollama serve...
        echo.
        %%P serve
        goto :eof
    )
)

echo.
echo ERROR: No se encontro Ollama en las ubicaciones esperadas
echo.
echo Intenta:
echo 1. Reiniciar Windows
echo 2. Descargar manualmente desde https://ollama.ai/download
echo 3. Instalar manualmente
echo.
pause

# 🚀 Stack Permanente: API Optimizada + OLLAMA con ngrok 24/7

Este stack permite tener **API + OLLAMA disponibles permanentemente** con URL pública fija.

---

## 📋 Requisitos Previos

```
✅ Docker Desktop instalado (https://www.docker.com/products/docker-desktop)
✅ ngrok instalado en C:\ngrok\ (https://ngrok.com/download)
✅ Windows PowerShell 5.1+ (incluido en Windows 10/11)
✅ Espacio en disco: ~5GB (para modelos OLLAMA)
```

### Verificar Requisitos

```powershell
# Verificar Docker
docker --version

# Verificar ngrok
C:\ngrok\ngrok.exe --version

# Verificar PowerShell
$PSVersionTable.PSVersion
```

---

## ⚡ Inicio Rápido (30 segundos)

### Opción A: Todo Automático

```batch
# Ejecutar en cmd desde el directorio del proyecto
manager.bat start
```

Esto inicia en paralelo:
- ✅ Docker Compose (API + OLLAMA)
- ✅ ngrok Dual 24/7 (expone ambos)

### Opción B: Manual Paso a Paso

#### Terminal 1: Docker Compose

```powershell
docker-compose up -d

# Verificar que está levantado
docker-compose ps

# Ver logs
docker-compose logs -f
```

#### Terminal 2: ngrok Dual

```powershell
powershell -ExecutionPolicy Bypass -File ngrok_dual_24_7.ps1
```

---

## 📊 Arquitectura

```
┌─────────────────────────────────────────────────────┐
│  Tu Máquina (Windows)                               │
│                                                     │
│  ┌──────────────────────────────────────────────┐  │
│  │  Docker Container 1: OLLAMA                  │  │
│  │  Puertos: 11434 (local) → 11434 (Docker)    │  │
│  └──────────────────────────────────────────────┘  │
│                                                     │
│  ┌──────────────────────────────────────────────┐  │
│  │  Docker Container 2: API Optimizada (Flask) │  │
│  │  Puertos: 5000 (local) → 5000 (Docker)     │  │
│  │  Conecta a OLLAMA via: http://ollama:11434 │  │
│  └──────────────────────────────────────────────┘  │
│                                                     │
│  ┌──────────────────────────────────────────────┐  │
│  │  ngrok Dual 24/7 (PowerShell Script)         │  │
│  │  - Túnel 1: Puerto 5000 → URL pública        │  │
│  │  - Túnel 2: Puerto 11434 → URL pública       │  │
│  └──────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────┘
         ↓                           ↓
      HTTPS (ngrok)           HTTPS (ngrok)
         ↓                           ↓
   https://xxxx.ngrok.io/  https://yyyy.ngrok.io/
```

---

## 🔌 Endpoints Públicos

Una vez iniciado, verás en la terminal de ngrok:

```
╔════════════════════════════════════════════════════════════╗
║           INFORMACIÓN DE TÚNELES NGROK ACTIVOS             ║
╠════════════════════════════════════════════════════════════╣
║ API (puerto 5000):
║   https://abc123.ngrok.io

║ OLLAMA (puerto 11434):
║   https://xyz789.ngrok.io

║ Tiempo activo: 0h 2m 45s
╚════════════════════════════════════════════════════════════╝
```

### Usar la API

```bash
# Health Check
curl https://abc123.ngrok.io/api/health

# Analizar logs
curl -X POST https://abc123.ngrok.io/api/analyze \
  -H "Content-Type: application/json" \
  -d '{"logs":"ERROR: Connection timeout"}'

# Usar OLLAMA directamente
curl https://xyz789.ngrok.io/api/tags
```

---

## 🛠️ Comandos Útiles

### Usando manager.bat

```batch
manager.bat start         # Iniciar todo
manager.bat stop          # Detener todo
manager.bat restart       # Reiniciar todo
manager.bat status        # Ver estado
manager.bat logs          # Ver logs Docker
manager.bat docker        # Iniciar solo Docker
manager.bat ngrok         # Iniciar solo ngrok
```

### Usando Docker

```bash
# Ver estado
docker-compose ps

# Ver logs en tiempo real
docker-compose logs -f

# Ver logs específicos
docker-compose logs log-analyzer-agent
docker-compose logs ollama

# Detener
docker-compose down

# Rebuild (si cambias código)
docker-compose build --no-cache
docker-compose up -d
```

### Usando PowerShell

```powershell
# Iniciar ngrok manualmente
powershell -ExecutionPolicy Bypass -File ngrok_dual_24_7.ps1

# Detener ngrok
Stop-Process -Name ngrok -Force

# Ver procesos ngrok
Get-Process ngrok
```

---

## 📝 Archivos Importantes

| Archivo | Propósito |
|---------|-----------|
| `docker-compose.yml` | Configuración de contenedores |
| `ngrok_dual_24_7.ps1` | Script de monitoreo ngrok 24/7 |
| `START_ALL_24_7.bat` | Launcher automático |
| `manager.bat` | Gestor de comandos |
| `.env.production` | Variables de configuración |
| `log-analyzer-agent/Dockerfile` | Construcción de imagen (usa `api_optimized.py`) |
| `log-analyzer-agent/api_optimized.py` | API principal |

---

## 🔄 Flujo de Trabajo

### 1️⃣ Primera Vez

```powershell
# 1. Verificar requisitos
docker --version
C:\ngrok\ngrok.exe --version

# 2. Iniciar stack
manager.bat start

# 3. Esperar a que ambas terminales estén listas
# Terminal 1: Espera a "log-analyzer-agent | Listening on http://0.0.0.0:5000"
# Terminal 2: Espera a "INFORMACIÓN DE TÚNELES NGROK ACTIVOS"

# 4. Copiar URLs públicas
# API: https://xxx.ngrok.io
# OLLAMA: https://yyy.ngrok.io

# 5. Verificar que funciona
curl https://xxx.ngrok.io/api/health
```

### 2️⃣ Operación Diaria

```powershell
# Las URLs cambian cada vez que reinicia ngrok (sin plan Pro)
# Soluciones:

# Opción A: Dejar siempre corriendo
# - Ejecutar manager.bat start al encender Windows
# - Ir a Inicio > Ejecutar > shell:startup
# - Crear acceso directo a manager.bat

# Opción B: Ngrok Pro ($10/mes)
# - URL permanente
# - Sin cambios cada 8 horas

# Opción C: Monitorear las URLs
# Las URLs se guardan en archivos:
type ngrok_API_url.txt
type ngrok_OLLAMA_url.txt
```

### 3️⃣ Detener

```batch
manager.bat stop
```

---

## ⚠️ Troubleshooting

### Error: Docker no está instalado

```
[ERROR] Docker no está instalado o no está en el PATH
```

**Solución:**
1. Instalar Docker Desktop: https://www.docker.com/products/docker-desktop
2. Reiniciar Windows

### Error: ngrok no encontrado

```
[ERROR] ngrok no encontrado en C:\ngrok\ngrok.exe
```

**Solución:**
1. Descargar ngrok: https://ngrok.com/download
2. Extraer en `C:\ngrok\`
3. Verificar: `C:\ngrok\ngrok.exe --version`

### Puerto 5000 ya en uso

```
ERROR: for log-analyzer-agent  Cannot start service log-analyzer-agent: 
Ports are not available: 5000/tcp
```

**Solución:**
```powershell
# Encontrar qué usa puerto 5000
netstat -ano | findstr :5000

# Detener ese proceso
taskkill /PID <PID> /F

# O cambiar puerto en docker-compose.yml
# Cambiar "5000:5000" a "5001:5000"
```

### OLLAMA tarda mucho en iniciar

```
[WARN] ngrok no conectó después de 30 segundos para OLLAMA
```

**Solución:**
- Aumentar timeout en `ngrok_dual_24_7.ps1`
- Cambiar `$maxRetries = 15` a `$maxRetries = 30`
- Los primeros inicios de OLLAMA toman ~60s

### Verificar qué está fallando

```powershell
# Ver logs detallados
docker-compose logs --follow

# Verificar contenedores
docker ps

# Verificar si los contenedores se restartan
docker-compose ps

# Ver detalles de un contenedor
docker inspect log-analyzer-agent
```

---

## 📈 Monitoreo 24/7

El stack incluye health checks automáticos:

```yaml
# Cada 30 segundos verifica:
# - ¿OLLAMA responde?
# - ¿API responde?
# - ¿ngrok sigue activo?

# Si algo falla, reinicia automáticamente
```

Ver logs de health checks:
```bash
docker-compose logs --follow log-analyzer-agent
```

---

## 🔐 Seguridad

### Ngrok es público pero seguro

✅ **HTTPS automático** - Todas las conexiones están encriptadas  
✅ **Rate limiting** - ngrok limita peticiones  
✅ **Logs** - Todas las conexiones quedan registradas

### Opciones de seguridad adicional

1. **Firewall local** - Solo permite conexiones de IPs específicas
2. **Autenticación** - Añadir API key a los endpoints
3. **Ngrok Pro** - Incluye webhook verification y OAuth

---

## 💡 Tips Avanzados

### Guardar URLs permanentemente

Si tienes **Ngrok Pro**:

```bash
ngrok http 5000 --domain=tu-dominio-pro.ngrok.io
```

### Usar con CI/CD

Integra en pipelines:
```bash
docker-compose -f docker-compose.yml up -d
ngrok http 5000 --authtoken=$NGROK_TOKEN &
```

### Monitorear con webhook

Agregar a `api_optimized.py`:
```python
@app.route('/webhook', methods=['POST'])
def webhook():
    # Recibir eventos de análisis
    return jsonify({"status": "received"})
```

Luego exponer: `ngrok http 5000`

---

## 📞 Soporte

Archivos de configuración:
- `docker-compose.yml` - Servicios Docker
- `.env.production` - Variables de entorno
- `ngrok_dual_24_7.ps1` - Monitoreo ngrok

Logs útiles:
```bash
# Logs completos
docker-compose logs -f

# Solo errores
docker-compose logs -f | findstr "ERROR"

# De hace 30 minutos
docker-compose logs --since 30m
```

---

## 🎯 Resumen

| Paso | Comando | Tiempo |
|------|---------|--------|
| Verificar Docker | `docker --version` | 10s |
| Verificar ngrok | `C:\ngrok\ngrok.exe --version` | 10s |
| Iniciar stack | `manager.bat start` | 30s |
| Esperar OLLAMA | Automático | ~60s |
| Obtener URLs | Ver terminal ngrok | 10s |
| **Total inicial** | | ~110s (2 min) |

Una vez iniciado, permanece 24/7 sin intervención (excepto reinicio Windows).

---

**¡Listo! Tu API + OLLAMA están ahora permanentemente disponibles en internet.** 🎉

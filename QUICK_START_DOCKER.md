# 🚀 DOCKER - Guía Rápida de Inicio

## ⚡ 3 Pasos para Empezar (Windows)

### 1️⃣ Configurar
```powershell
# Copiar y personalizar configuración
copy .env.example .env

# Editar .env según tu necesidad (modelo OLLAMA, recursos, etc)
```

### 2️⃣ Iniciar
```powershell
# Opción A: Usar el manager (recomendado)
.\docker-manager.ps1 start

# Opción B: Docker Compose directo
docker-compose up -d
```

### 3️⃣ Verificar
```powershell
# Ver estado
.\docker-manager.ps1 status

# Probar API
curl http://localhost:5000/api/health
```

---

## 🔧 Comandos Principales

```powershell
# Iniciar todo
.\docker-manager.ps1 start

# Ver estado en tiempo real
.\docker-manager.ps1 logs log-analyzer-agent

# Detener
.\docker-manager.ps1 stop

# Entrar en el contenedor
.\docker-manager.ps1 shell log-analyzer-agent

# Probar API
.\docker-manager.ps1 test

# Limpiar todo (⚠️ borra datos)
.\docker-manager.ps1 clean
```

---

## 📋 Requisitos

- ✅ **Docker Desktop** instalado ([Descargar](https://www.docker.com/products/docker-desktop))
- ✅ **Hardware**: 8GB RAM mínimo (16GB recomendado)
- ✅ **Disco**: 50GB+ (para modelos OLLAMA)

---

## 📁 Estructura

```
/log-analyzer-agent/
├── api.py           # REST API
├── agent.py         # Core agent
├── skills/          # Módulos especializados
└── Dockerfile       # Imagen Docker optimizada

/docker-compose.yml  # Orquestación de contenedores
/.env.example        # Configuración (copia a .env)
```

---

## 🌐 URLs Disponibles

| Servicio | URL | Descripción |
|----------|-----|-------------|
| **API** | `http://localhost:5000` | REST API del agente |
| **Health Check** | `http://localhost:5000/api/health` | Estado del servicio |
| **OLLAMA** | `http://localhost:11434` | Servidor de modelos |

---

## 🔌 Endpoints del API

```bash
# Health
curl http://localhost:5000/api/health

# Analizar logs
curl -X POST http://localhost:5000/api/analyze \
  -H "Content-Type: application/json" \
  -d '{"logs":"[ERROR] mensaje"}'

# Ver patrones
curl http://localhost:5000/api/patterns

# Chat directo con OLLAMA
curl -X POST http://localhost:5000/api/ollama/chat \
  -H "Content-Type: application/json" \
  -d '{"message":"¿qué es esto?"}'
```

---

## 🛠️ Troubleshooting

### ❌ Puerto 5000 ya en uso
```powershell
# Buscar qué ocupa el puerto
Get-NetTCPConnection -LocalPort 5000

# Cambiar puerto en .env
AGENT_PORT=5001
```

### ❌ Out of Memory
```powershell
# Aumentar memoria en .env
AGENT_MEMORY_LIMIT=4G
OLLAMA_MEMORY_LIMIT=8G

# Reiniciar
.\docker-manager.ps1 stop
.\docker-manager.ps1 start
```

### ❌ OLLAMA no encuentra modelo
```powershell
# Ver modelos disponibles
docker exec ollama ollama list

# Descargar modelo
docker exec ollama ollama pull llama2

# Actualizar .env
OLLAMA_MODEL=llama2
```

---

## 📊 Monitoreo

```powershell
# Ver logs en tiempo real
docker-compose logs -f

# Estadísticas de uso
docker stats

# Inspeccionar contenedor
docker inspect log-analyzer-agent
```

---

## 🔐 Producción

```powershell
# Build optimizado
docker-compose build --no-cache

# Limitar recursos en .env
AGENT_CPU_LIMIT=4
AGENT_MEMORY_LIMIT=4G

# Usar reverse proxy (Nginx/Traefik)
# Habilitar HTTPS
# Monitorear logs
```

---

## 📚 Documentación Completa

👉 Ver [DOCKER_SETUP.md](DOCKER_SETUP.md) para guía detallada

---

## 🎯 Próximos Pasos

1. Copia `.env.example` a `.env`
2. Ejecuta `.\docker-manager.ps1 start`
3. Espera ~30-60 segundos para que OLLAMA inicie
4. Prueba los endpoints: `curl http://localhost:5000/api/health`
5. ¡Listo! Tu agente está disponible

---

**¿Necesitas ayuda?** Ver DOCKER_SETUP.md o ejecuta `.\docker-manager.ps1 help`

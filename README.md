# 🔍 Agente de Análisis de Logs con Mulesoft Omni Gateway

**Integración completa de un agente inteligente de análisis de logs con OLLAMA dentro de Mulesoft**

```
┌─────────────────────────────────────────────────────────┐
│  Cliente HTTP (Postman, curl, etc.)                     │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
        ┌─────────────────────────────┐
        │  Mulesoft Omni Gateway      │
        │  (Puerto 8081)              │
        │                             │
        │  ✓ Health Check             │
        │  ✓ Analyze Logs             │
        │  ✓ Pattern Analysis         │
        │  ✓ Create Incidents         │
        └────────────┬────────────────┘
                     │
                     ▼
        ┌─────────────────────────────┐
        │  Agente Python (Flask)      │
        │  (Puerto 5000)              │
        │                             │
        │  ✓ Log Ingestion            │
        │  ✓ Pattern Matching         │
        │  ✓ Correlation Engine       │
        │  ✓ ServiceNow Integration   │
        └────────────┬────────────────┘
                     │
        ┌────────────┴────────────┐
        │                         │
        ▼                         ▼
    ┌────────────┐          ┌──────────────┐
    │   OLLAMA   │          │  ServiceNow  │
    │  (LLM)     │          │   (ITSM)     │
    │ Port 11434 │          │   Cloud      │
    └────────────┘          └──────────────┘
```

El orquestador también está disponible como entrada independiente en el puerto
5001; clasifica y enruta las solicitudes compatibles al agente de trazas en el
puerto 5000.

---

## 🚀 Inicio Rápido (5 minutos)

### Opción 1: Con Docker Compose (Recomendado)

```bash
# 1. Compilar el gateway Mule
cd log-analyzer-omni-gateway
mvn clean package -DskipTests
cd ..

# 2. Iniciar todos los servicios
docker-compose up -d

# 3. Verificar health
curl http://localhost:5001/api/health
curl http://localhost:8081/api/health
```

### Opción 2: Startup Script

```bash
# Linux / macOS
chmod +x quickstart.sh
./quickstart.sh

# Windows (Git Bash o PowerShell)
bash quickstart.sh
```

### Opción 3: Manual

```bash
# Terminal 1: Iniciar OLLAMA
ollama serve

# Terminal 2: Descargar modelo (si no existe)
ollama pull llama2

# Terminal 3: Instalar dependencias Python y ejecutar agente
cd log-analyzer-agent
pip install -r requeriments.txt
python api.py

# Terminal 4: Compilar y ejecutar Mule Gateway
cd log-analyzer-omni-gateway
mvn clean package
mvn mule:run
```

---

## 📋 Endpoints Disponibles

```bash
# 1. Health Check
curl http://localhost:8081/api/health

# 2. Analizar logs (con IA)
curl -X POST http://localhost:8081/api/analyze \
  -H "Content-Type: application/json" \
  -d '{"logs":"2026-07-31T09:40:01Z [ERROR] Database error"}'

# 3. Análisis rápido de patrones (sin IA)
curl -X POST http://localhost:8081/api/patterns \
  -H "Content-Type: application/json" \
  -d '{"logs":"2026-07-31T09:40:01Z [ERROR] Database error"}'

# 4. Crear incidentes en ServiceNow
curl -X POST http://localhost:8081/api/incidents \
  -H "Content-Type: application/json" \
  -d '{"logs":"...", "logs_source":"prod-k8s"}'
```

---

## 📁 Estructura del Proyecto

```
Agente Trazas OLLAMA/
├── log-analyzer-agent/          # Agente Python con skills
│   ├── api.py                   # API REST (Flask)
│   ├── orchestrator_api.py      # Selección de agente y despacho
│   ├── agent.py                 # Orquestador principal
│   ├── skills/                  # Módulos especializados
│   ├── ollama/                  # Configuración OLLAMA
│   ├── Dockerfile               # Containerización
│   └── requeriments.txt         # Dependencias Python
│
├── log-analyzer-omni-gateway/   # Gateway Mulesoft
│   ├── src/main/mule/
│   │   ├── log-analyzer-omni-gateway.xml   # Flujos principales
│   │   └── global-configs.xml              # Configuración global
│   ├── pom.xml                  # Dependencias Maven
│   └── mule-artifact.json       # Metadatos
│
├── log-analyzer-api/            # Especificación OpenAPI
│   ├── log-analyzer-api.yaml    # Definición de endpoints
│   └── exchange.json            # Metadatos Anypoint Exchange
│
├── docker-compose.yml           # Orquestación de servicios
├── quickstart.sh                # Script de inicio
├── INTEGRATION_GUIDE.md         # Documentación completa
└── README.md                    # Este archivo
```

---

## ✅ Requisitos

| Componente | Versión |
|-----------|---------|
| Python | 3.9+ |
| Java | 17+ |
| Maven | 3.9+ |
| OLLAMA | Latest |
| Mule Runtime | 4.11.6+ |
| Docker | 20.10+ (opcional) |

---

## 🔧 Configuración

### Variables de Entorno

```bash
# Agente Python
export OLLAMA_API_URL=http://localhost:11434
export OLLAMA_MODEL=llama2
export FLASK_PORT=5000

# Orquestador (servicio Docker en puerto 5001)
export ORCHESTRATOR_MODEL=llama2
export TRACE_AGENT_URL=http://localhost:5000

# ServiceNow (opcional)
export SERVICENOW_INSTANCE=dev12345
export SERVICENOW_CLIENT_ID=your_id
export SERVICENOW_CLIENT_SECRET=your_secret
export SERVICENOW_CREATE_INCIDENTS=false
```

### Archivo .env (Opcional)

```bash
cp log-analyzer-agent/.env.example log-analyzer-agent/.env
# Editar con tus valores
```

---

## 📊 Flujos Mule Disponibles

1. **health-check-flow**
   - GET `/api/health`
   - Verifica estado del agente

2. **analyze-logs-flow**
   - POST `/api/analyze`
   - Análisis completo (patrones + IA)
   - ~30-60 segundos (depende del modelo OLLAMA)

3. **analyze-patterns-flow**
   - POST `/api/patterns`
   - Solo análisis de patrones (rápido)
   - <1 segundo

4. **create-incidents-flow**
   - POST `/api/incidents`
   - Crear tickets en ServiceNow automáticamente

---

## 🧪 Testing

### Test rápido de integración

```bash
# Todos los servicios deben responder
curl http://localhost:11434/api/tags          # OLLAMA
curl http://localhost:5000/api/health         # Agente
curl http://localhost:5001/api/health         # Orquestador
curl http://localhost:8081/api/health         # Mule
```

### Enrutar una solicitud mediante el orquestador

El orquestador clasifica la tarea con Ollama y, si corresponde, reenvía la
solicitud al agente de trazas. El agente destino está limitado a
`log-analyzer-agent`; para otras tareas responde `422` sin invocar agentes.

```bash
curl -X POST http://localhost:5001/api/orchestrate \
  -H "Content-Type: application/json" \
  -d '{"task":"Analiza estas trazas", "logs":"2026-09-29T10:00:00Z [ERROR] Database timeout"}'
```

La respuesta incluye `decision` y `agent_result`. Configura `ORCHESTRATOR_MODEL`,
`TRACE_AGENT_URL`, `ORCHESTRATOR_OLLAMA_TIMEOUT` y `TRACE_AGENT_TIMEOUT` en el
entorno Docker Compose cuando necesites cambiar los valores predeterminados.

Para usar Ollama Cloud, configura `OLLAMA_API_URL=https://api.ollama.com`, tu
`OLLAMA_API_KEY` y un modelo Cloud, por ejemplo `OLLAMA_MODEL=llama3.2:1b:cloud`,
en `log-analyzer-agent/.env.production`. El orquestador carga ese archivo al
arrancar; también puedes definir `ORCHESTRATOR_MODEL` y
`ORCHESTRATOR_OLLAMA_API_KEY` para usar valores distintos solo en el orquestador.
Luego recrea el servicio con `docker-compose up -d --build --force-recreate orchestrator`.

### Test de endpoints

```bash
# Test 1: Análisis rápido
curl -X POST http://localhost:8081/api/patterns \
  -H "Content-Type: application/json" \
  -d '{
    "logs":"2026-07-31T09:40:01Z [ERROR] Connection timeout\n2026-07-31T09:40:02Z [ERROR] Connection timeout"
  }' | jq

# Test 2: Análisis con IA (esperar 30-60 seg)
curl -X POST http://localhost:8081/api/analyze \
  -H "Content-Type: application/json" \
  -d '{
    "logs":"2026-07-31T09:40:01Z [ERROR] Database connection failed"
  }' | jq
```

---

## 📝 Documentación Completa

Para documentación detallada, ver:
- **[INTEGRATION_GUIDE.md](INTEGRATION_GUIDE.md)** - Guía completa de integración
- **[log-analyzer-api/log-analyzer-api.yaml](log-analyzer-api/log-analyzer-api.yaml)** - Especificación OpenAPI
- **[Logs](#logs)** - Troubleshooting

---

## 🐛 Troubleshooting

### OLLAMA no responde
```bash
# Verificar que está corriendo
curl http://localhost:11434/api/tags

# Si no responde, iniciar:
ollama serve
```

### Agente Python falla
```bash
# Ver logs
tail -f /tmp/agent.log

# Verificar puerto 5000
netstat -an | grep 5000

# Reiniciar
pkill -f "python api.py"
cd log-analyzer-agent && python api.py
```

### Mule no inicia
```bash
# Ver logs
tail -f $MULE_HOME/logs/mule-app.log

# Verificar puerto 8081
netstat -an | grep 8081

# Compilar de nuevo
cd log-analyzer-omni-gateway
mvn clean package
```

---

## 🚢 Deployment a Producción

### CloudHub 2.0

```bash
cd log-analyzer-omni-gateway
mvn clean package
anypoint-cli runtime-mgr:deploy \
  target/log-analyzer-omni-gateway-1.0.0-SNAPSHOT.jar \
  --target CloudHub
```

### Runtime Fabric

```bash
anypoint-cli runtime-mgr:deploy \
  target/log-analyzer-omni-gateway-1.0.0-SNAPSHOT.jar \
  --target RuntimeFabric \
  --environment production
```

---

## 📊 Monitoreo

### Logs en tiempo real

```bash
# Mule
tail -f $MULE_HOME/logs/mule-app.log

# Agente Python
tail -f /tmp/agent.log

# OLLAMA
tail -f /tmp/ollama.log
```

### Métricas

- **Latencia API**: Medir en cada endpoint
- **CPU/Memoria**: OLLAMA usa bastante GPU
- **Timeout OLLAMA**: Configurar timeout según modelo

---

## 🔐 Seguridad

- [ ] Habilitar SSL/TLS en Mule
- [ ] Configurar autenticación OAuth 2.0
- [ ] Validar JWT tokens
- [ ] Rate limiting en API Manager
- [ ] Enmascarar logs sensibles
- [ ] Encriptar credenciales ServiceNow

---

## 📞 Soporte

Para preguntas o issues:
1. Revisar [INTEGRATION_GUIDE.md](INTEGRATION_GUIDE.md)
2. Verificar logs en `/tmp/`
3. Consultar especificación OpenAPI: [log-analyzer-api.yaml](log-analyzer-api/log-analyzer-api.yaml)

---

## 📄 Licencia

[Tu Licencia Aquí]

---

**¡Listo para analizar logs inteligentemente! 🎉**

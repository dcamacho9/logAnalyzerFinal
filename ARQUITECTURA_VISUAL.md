# Arquitectura de Integración - Diagrama Visual

## 📊 Flujo de Datos Completo

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          CLIENTE HTTP/REST                                   │
│                    (Postman, curl, aplicación)                              │
└────────────────────────────────────┬──────────────────────────────────────────┘
                                     │
                                     ↓ HTTP POST
                    ┌────────────────────────────────┐
                    │   MULESOFT OMNI GATEWAY        │
                    │   (Puerto 8081)                │
                    │                                │
                    │  ┌────────────────────────────┐│
                    │  │  HTTP Listener             ││
                    │  │  Ruta: /api/*              ││
                    │  └─────────┬──────────────────┘│
                    │            │                   │
                    │  ┌─────────▼──────────────────┐│
                    │  │  Router (by endpoint)      ││
                    │  │  - /health                 ││
                    │  │  - /analyze                ││
                    │  │  - /patterns               ││
                    │  │  - /incidents              ││
                    │  └─────────┬──────────────────┘│
                    │            │                   │
                    │  ┌─────────▼──────────────────┐│
                    │  │ DataWeave Transform       ││
                    │  │ (Preparar payload)        ││
                    │  └─────────┬──────────────────┘│
                    │            │                   │
                    │  ┌─────────▼──────────────────┐│
                    │  │ HTTP Request Config       ││
                    │  │ timeout: 30s               ││
                    │  └─────────┬──────────────────┘│
                    └────────────┼───────────────────┘
                                 │
                              ngrok
                                 │
                                 │
                 HTTP GET/POST (JSON)
                                 │
                    ┌────────────▼──────────────────┐
                    │   LOG ANALYZER AGENT          │
                    │   (Python Flask)              │
                    │   (Puerto 5000)               │
                    │                                │
                    │  ┌────────────────────────────┐│
                    │  │  /api/health               ││
                    │  │  → Status agent            ││
                    │  └────────────────────────────┘│
                    │                                │
                    │  ┌────────────────────────────┐│
                    │  │  /api/analyze              ││
                    │  │  ┌─────────────────────┐   ││
                    │  │  │ 1. Fetch logs       │   ││
                    │  │  │ 2. Parse logs       │   ││
                    │  │  │ 3. Pattern match    │   ││
                    │  │  │ 4. Call OLLAMA      │   ││
                    │  │  │ 5. Generate report  │   ││
                    │  │  └─────────┬───────────┘   ││
                    │  └────────────┼─────────────────┤
                    │               │                │
                    │  ┌────────────▼──────────────┐│
                    │  │  /api/patterns            ││
                    │  │  (Sin llamar OLLAMA)     ││
                    │  └────────────────────────────┘│
                    │                                │
                    │  ┌────────────────────────────┐│
                    │  │  /api/incidents            ││
                    │  │  (Create ServiceNow)      ││
                    │  └────────────────────────────┘│
                    │                                │
                    └───────────┬──────────────────────┘
                                │
                    HTTP Request (Async)
                                │
                ┌───────────────▼───────────────────┐
                │      OLLAMA                       │
                │      (Puerto 11434)               │
                │                                    │
                │  ┌──────────────────────────────┐ │
                │  │ LLM Model (llama2)           │ │
                │  │ - Análisis de texto          │ │
                │  │ - Detección de anomalías     │ │
                │  │ - Generación de diagnóstico  │ │
                │  └──────────────────────────────┘ │
                └────────────────────────────────────┘
```

---

## 🏗️ Componentes de Integración

### 1️⃣ CAPA DE ENTRADA (Mulesoft)
```
┌─────────────────────────────────────────────┐
│   HTTP Listener (0.0.0.0:8081)              │
│                                             │
│  • Escucha requests HTTP                   │
│  • Valida método GET/POST/PUT/DELETE       │
│  • Logging de requests                     │
│  • Mapeo de rutas                          │
└─────────────────────────────────────────────┘
```

### 2️⃣ CAPA DE PROCESAMIENTO (Mulesoft)
```
┌─────────────────────────────────────────────┐
│   Flows de Negocio                          │
│                                             │
│  • health-check-flow                       │
│  • analyze-logs-flow                       │
│  • analyze-patterns-flow                   │
│  • create-incidents-flow                   │
│                                             │
│  Transformaciones:                          │
│  • DataWeave (DW 2.0)                      │
│  • Mapping JSON                            │
│  • Error handling                          │
└─────────────────────────────────────────────┘
```

### 3️⃣ CAPA DE INTEGRACIÓN (Mulesoft)
```
┌─────────────────────────────────────────────┐
│   HTTP Requester (localhost:5000)           │
│                                             │
│  • Timeout: 30s                            │
│  • Retry logic (si aplica)                 │
│  • Response validation                     │
│  • Error propagation                       │
└─────────────────────────────────────────────┘
```

### 4️⃣ CAPA DE NEGOCIOS (Python)
```
┌─────────────────────────────────────────────┐
│   Agent Orchestrator (agent.py)             │
│                                             │
│  • Coordina skills                         │
│  • Maneja estado                           │
│  • Prepara datos para OLLAMA               │
└─────────────────────────────────────────────┘
```

### 5️⃣ CAPA DE SKILLS (Python)
```
┌─────────────────────────────────────────────┐
│   Skills Directory                          │
│                                             │
│  • log_ingestion.py                        │
│  • log_pattern_matcher.py                  │
│  • log_correlation_engine.py               │
│  • log_report_generator.py                 │
│  • anomaly_detector.py                     │
│  • servicenow_incident_creator.py          │
│  • servicenow_token_generator.py           │
└─────────────────────────────────────────────┘
```

### 6️⃣ CAPA DE IA (OLLAMA)
```
┌─────────────────────────────────────────────┐
│   OLLAMA LLM Server                         │
│                                             │
│  • Modelo: llama2 (u otro)                 │
│  • Análisis cognitivo                      │
│  • Generación de reportes                  │
│  • Contexto 4K-8K tokens                   │
└─────────────────────────────────────────────┘
```

### 7️⃣ CAPA DE INTEGRACIONES EXTERNAS (Python)
```
┌─────────────────────────────────────────────┐
│   Integraciones Externas                    │
│                                             │
│  • ServiceNow API                          │
│  • Log sources (archivos, streams)         │
│  • Databases                               │
│  • Webhooks                                │
└─────────────────────────────────────────────┘
```

---

## 🔄 Flujo de Análisis Completo

### Paso 1: Cliente envía request
```json
POST http://localhost:8081/api/analyze
{
  "logs": "2026-07-31T09:40:01Z [ERROR] Connection timeout...",
  "limit": 100,
  "only_pattern_analysis": false
}
```

### Paso 2: Mulesoft recibe y valida
```
✓ Validar método: POST
✓ Validar ruta: /analyze
✓ Extraer payload
✓ Logger: "Analyze request received"
```

### Paso 3: Mulesoft transforma datos
```dw
%dw 2.0
output application/json
---
{
  logs: payload.logs default "",
  limit: payload.limit default 100,
  only_pattern_analysis: payload.only_pattern_analysis default false
}
```

### Paso 4: Mulesoft envía a Agente
```
POST http://localhost:5000/api/analyze
Content-Type: application/json
Timeout: 30s

Body: {
  "logs": "2026-07-31T09:40:01Z [ERROR] Connection timeout...",
  "limit": 100,
  "only_pattern_analysis": false
}
```

### Paso 5: Agente procesa (log_ingestion.py)
```python
# 1. Obtener logs
raw_logs = fetch_logs(limit=100)  # O usar payload.logs

# 2. Parsear logs
structured_logs = parse_log_lines(raw_logs)
# Resultado:
# [
#   {
#     "timestamp": "2026-07-31T09:40:01Z",
#     "level": "ERROR",
#     "message": "Connection timeout",
#     "service": "unknown"
#   },
#   ...
# ]
```

### Paso 6: Análisis de patrones (log_pattern_matcher.py)
```python
patterns = run_log_pattern_matcher(structured_logs)
# Resultado:
# {
#   "pattern_summary": [
#     {
#       "pattern": "Connection timeout",
#       "count": 5,
#       "severity": "HIGH"
#     }
#   ],
#   "annotated_events": [...]
# }
```

### Paso 7: Llamar OLLAMA (si only_pattern_analysis=false)
```python
prompt = f"""
Analyze the following logs and patterns:
{patterns['pattern_summary']}

Generate a root-cause diagnostic report (max 500 words).
Include:
- Likely cause
- Severity assessment
- Recommended actions
"""

response = call_ollama(prompt, model="llama2")
diagnostic_report = response['choices'][0]['text']
```

### Paso 8: Generar respuesta
```json
{
  "status": "success",
  "step": "4_complete",
  "annotated_events": [...],
  "pattern_summary": [...],
  "diagnostic_report": "Análisis del OLLAMA...",
  "total_events_processed": 100
}
```

### Paso 9: Mulesoft envía de vuelta
```
HTTP/1.1 200 OK
Content-Type: application/json

{
  "status": "success",
  "step": "4_complete",
  ...
}
```

### Paso 10: Cliente recibe respuesta
```json
{
  "status": "success",
  "annotated_events": [...],
  "pattern_summary": [...],
  "diagnostic_report": "Múltiples timeouts de conexión detectados..."
}
```

---

## ⏱️ Tiempos de Respuesta

| Componente | Tiempo Típico | Máximo |
|------------|---------------|--------|
| HTTP Request Mulesoft | 5-10ms | 100ms |
| Parsing logs | 10-50ms | 500ms |
| Pattern matching | 20-100ms | 1s |
| OLLAMA analysis | 5-20s | 30s |
| ServiceNow integration | 1-5s | 10s |
| **TOTAL (con OLLAMA)** | **6-20s** | **30s** |
| **TOTAL (sin OLLAMA)** | **50-200ms** | **1s** |

---

## 📦 Configuración por Entorno

### DESARROLLO (tu laptop)
```yaml
OLLAMA:
  Host: http://localhost
  Port: 11434
  Timeout: 30s

AGENTE:
  Host: http://localhost
  Port: 5000
  Environment: development
  Logging: DEBUG

MULESOFT:
  Host: 0.0.0.0
  Port: 8081
  Timeout: 30s
  Logging: DEBUG
```

### TESTING (servidor local)
```yaml
OLLAMA:
  Host: http://ollama-server
  Port: 11434
  Timeout: 30s

AGENTE:
  Host: http://agent-server
  Port: 5000
  Environment: staging
  Logging: INFO

MULESOFT:
  Host: 0.0.0.0
  Port: 8081
  Timeout: 30s
  Logging: INFO
```

### PRODUCCIÓN (en runtime fabric)
```yaml
OLLAMA:
  Host: http://ollama.prod.internal
  Port: 11434
  Timeout: 60s
  SSL: true

AGENTE:
  Host: https://agent.prod.domain
  Port: 443
  Environment: production
  Logging: WARN
  Replicas: 3

MULESOFT:
  Host: 0.0.0.0
  Port: 8081
  Timeout: 60s
  Logging: WARN
  Replicas: 2
```

---

## 🐳 Stack Docker

```dockerfile
# Dockerfile Multi-stage
FROM python:3.10 as agent-builder
WORKDIR /app
COPY requeriments.txt .
RUN pip install --no-cache-dir -r requeriments.txt
COPY . .
CMD ["python", "api.py"]

# docker-compose.yml
services:
  ollama:
    image: ollama/ollama:latest
    ports: ["11434:11434"]
    volumes: [ollama_data:/root/.ollama]
    healthcheck: curl http://localhost:11434/api/tags
    
  log-analyzer-agent:
    build: ./log-analyzer-agent
    ports: ["5000:5000"]
    depends_on: [ollama]
    env_file: .env
    healthcheck: curl http://localhost:5000/api/health
    
  omni-gateway:
    build: ./log-analyzer-omni-gateway
    ports: ["8081:8081"]
    depends_on: [log-analyzer-agent]
    environment:
      - AGENT_URL=http://log-analyzer-agent:5000

volumes:
  ollama_data:
networks:
  log-analyzer-net:
```

---

## 📊 Matriz de Responsabilidades

| Componente | Responsable | Mantenimiento |
|-----------|-------------|---------------|
| OLLAMA | DevOps | Modelo, versión, recursos |
| Agente Python | Dev Team | Skills, lógica, APIs |
| Mulesoft Flow | Integration Team | Routing, transformations |
| Variables .env | DevOps | Credenciales, URLs |
| Docker Compose | DevOps | Orquestación |
| Monitoreo | DevOps/SRE | Alertas, métricas |

---

## 🔍 Puntos Críticos de Fallos

```
┌─ OLLAMA no responde
│  └─ Solution: Verificar puerto, modelo, recursos
│
├─ Agente Python crashed
│  └─ Solution: Revisar logs Python, dependencies
│
├─ Mulesoft no conecta con agente
│  └─ Solution: Verificar firewall, host:port
│
├─ Timeout en OLLAMA
│  └─ Solution: Aumentar timeout (30s → 60s)
│
├─ JSON inválido
│  └─ Solution: Validar con jsonlint
│
└─ Puerto en uso
   └─ Solution: netstat -an | findstr :puerto
```

---

## 📞 Verificación Rápida

```powershell
# Test 1: OLLAMA
curl http://localhost:11434/api/tags
# ✓ Retorna modelos

# Test 2: Agente
curl http://localhost:5000/api/health  
# ✓ Retorna status OK

# Test 3: Mulesoft
curl http://localhost:8081/api/health
# ✓ Retorna 200 OK

# Test 4: End-to-end
curl -X POST http://localhost:8081/api/analyze \
  -H "Content-Type: application/json" \
  -d '{"logs":"[ERROR] test","limit":10}'
# ✓ Retorna análisis
```

---

**Versión**: 1.0  
**Última actualización**: 2026-08-31  
**Autor**: Arquitectura de Integración

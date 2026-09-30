# 📊 Arquitectura y Funcionamiento del Agente de Análisis de Trazas

## 🎯 Propósito General

El **Agente de Análisis de Trazas (log-analyzer-agent)** es un sistema inteligente de análisis y diagnóstico de logs que utiliza inteligencia artificial para:

- ✅ Analizar y clasificar eventos de logs
- ✅ Detectar patrones y anomalías
- ✅ Generar diagnósticos inteligentes con IA
- ✅ Correlacionar eventos relacionados
- ✅ Crear incidentes automáticos en ServiceNow
- ✅ Proporcionar recomendaciones de resolución

El agente actúa como intermediario inteligente entre sistemas de logs y herramientas ITSM (IT Service Management), transformando datos brutos en conocimiento accionable.

---

## 🏗️ Arquitectura de Alto Nivel

```
┌──────────────────────────────────────────────────────────┐
│                    CLIENTES                              │
│            (HTTP/REST - Postman, curl, apps)             │
└────────────────────────┬─────────────────────────────────┘
                         │
                         ▼
        ┌────────────────────────────────────┐
        │    MULESOFT OMNI GATEWAY           │
        │    (Puerto 8081)                   │
        │                                    │
        │  • Enrutamiento de requests        │
        │  • Autenticación                   │
        │  • Rate limiting                   │
        │  • Transformación de datos         │
        └────────────┬───────────────────────┘
                     │
                     ▼
        ┌────────────────────────────────────┐
        │   AGENTE DE ANÁLISIS (Python/Flask)│
        │   (Puerto 5000)                    │
        │                                    │
        │   ▪ Orquestación                   │
        │   ▪ Control de flujo               │
        │   ▪ Gestión de skills              │
        └────────────┬───────────────────────┘
                     │
        ┌────────────┴────────────────────┐
        │                                 │
        ▼                                 ▼
  ┌─────────────────┐          ┌──────────────────────┐
  │  OLLAMA (LLM)   │          │  SERVICENOW (ITSM)   │
  │                 │          │                      │
  │ • Modelo LLM    │          │ • API REST           │
  │   (phi, llama)  │          │ • Token Auth         │
  │ • Puerto 11434  │          │ • Cloud              │
  │                 │          │                      │
  │ Análisis IA de  │          │ Creación de          │
  │ logs y síntesis │          │ incidentes y tickets │
  └─────────────────┘          └──────────────────────┘
```

---

## 🔧 Componentes Principales

### 1. **API REST (Flask)**
**Archivo:** `api.py`

**Responsabilidad:** Exponer el agente como servicio web HTTP

**Características:**
- Manejo robusto de payloads grandes (hasta 100MB)
- Soporte para múltiples formatos de entrada
- Gestión de errores con mensajes descriptivos
- CORS habilitado para integración con frontend
- Autenticación y validación de request

**Endpoints principales:**
```
GET  /api/health              → Verificar estado del servicio
POST /api/analyze             → Análisis completo con IA
POST /api/patterns            → Análisis rápido de patrones
POST /api/ollama/chat         → Chat interactivo con modelo IA
POST /api/incidents           → Crear incidentes en ServiceNow
```

### 2. **Orquestador Principal (Agent)**
**Archivo:** `agent.py` / `agent_optimized.py`

**Responsabilidad:** Orquestar el flujo de análisis integrado

**Características:**
- Llamadas a múltiples skills en secuencia
- Limpieza de datos y normalización de texto
- Caché de respuestas para optimizar performance
- Streaming de datos para reducir latencia
- Logging detallado de tiempos de ejecución

**Flujo típico:**
```
1. Recibir logs crudos
2. Parsear y estructurar eventos
3. Ejecutar detección de patrones
4. Ejecutar detección de anomalías
5. Llamar a OLLAMA para análisis IA
6. Generar reporte diagnostico
7. (Opcional) Crear incidente en ServiceNow
```

### 3. **Skills (Habilidades Especializadas)**
Módulos independientes que implementan funcionalidades específicas:

#### **log_ingestion.py**
- Carga de logs desde múltiples fuentes (archivos, URLs, APIs)
- Parsing y estructuración de eventos
- Normalización de formatos (JSON, texto plano, etc.)
- Deduplicación de eventos

#### **log_pattern_matcher.py**
- Detección de patrones frecuentes
- Extracción de secuencias de eventos relacionados
- Generación de firmas de patrones
- Ranking por frecuencia y relevancia

#### **log_correlation_engine.py**
- Correlación temporal de eventos
- Identificación de relaciones causales
- Análisis de dependencias entre servicios
- Construcción de cadenas de eventos

#### **anomaly_detector.py**
- Detección de comportamientos anómalos
- Análisis estadístico de patrones normales
- Alertas de desviaciones significativas
- Machine Learning para predicción de anomalías

#### **log_report_generator.py**
- Síntesis de hallazgos en formato legible
- Generación de resúmenes ejecutivos
- Formateo de recomendaciones
- Exportación en múltiples formatos

#### **servicenow_token_generator.py**
- Autenticación OAuth2 con ServiceNow
- Gestión de tokens de acceso
- Renovación automática de credenciales

#### **servicenow_incident_creator.py**
- Creación automática de incidentes
- Mapeo de eventos de logs a categorías de ServiceNow
- Asignación de prioridades basada en severidad
- Vinculación de logs como adjuntos

---

## 🔄 Flujo de Procesamiento Detallado

### Análisis Completo (Con IA)

```
┌─ REQUEST: POST /api/analyze ─┐
└─────────────────────────────────┘
          │
          ▼
┌──────────────────────────────┐
│ 1. VALIDACIÓN Y PARSEO       │
│    • Validar JSON             │
│    • Extraer logs del request │
│    • Verificar encoding UTF-8 │
└──────────────────────────────┘
          │
          ▼
┌──────────────────────────────┐
│ 2. INGESTION (skill)         │
│    • Normalizar formato      │
│    • Crear eventos           │
│    • Deduplicar              │
└──────────────────────────────┘
          │
          ▼
┌──────────────────────────────┐
│ 3. PATTERN MATCHING (skill)  │
│    • Detectar patrones       │
│    • Extraer eventos clave   │
│    • Generar firmas          │
└──────────────────────────────┘
          │
          ▼
┌──────────────────────────────┐
│ 4. ANOMALY DETECTION (skill) │
│    • Analizar outliers       │
│    • Detectar desviaciones   │
│    • Calcular severidad      │
└──────────────────────────────┘
          │
          ▼
┌──────────────────────────────┐
│ 5. IA ANALYSIS (OLLAMA)      │
│    • Enviar contexto a LLM   │
│    • Obtener diagnóstico     │
│    • Generar recomendaciones │
│    ⏱️ ~2-5 segundos           │
└──────────────────────────────┘
          │
          ▼
┌──────────────────────────────┐
│ 6. REPORT GENERATION (skill) │
│    • Sintetizar hallazgos    │
│    • Formatear respuesta     │
│    • Preparar JSON           │
└──────────────────────────────┘
          │
          ▼
┌──────────────────────────────┐
│ 7. RESPONSE                  │
│    • Retornar JSON al cliente│
│    • Incluir timestamps      │
│    • Status: success/error   │
└──────────────────────────────┘
```

### Análisis Rápido (Solo Patrones, Sin IA)

```
POST /api/patterns
    │
    ├─ Validación
    ├─ Ingestion
    ├─ Pattern Matching ⚡
    │
    └─ Response (instantáneo)
```

---

## 📦 Estructura de Datos

### Request
```json
{
  "logs": "string con logs (requerido)",
  "limit": 100,                    // máximo de eventos a procesar
  "only_pattern_analysis": false,  // true = sin IA
  "source": "prod-k8s",            // identificación del origen
  "severity_threshold": 0.5        // filtrar por severidad
}
```

### Response
```json
{
  "status": "success",
  "step": "nombre del paso actual",
  "timestamp": "2026-09-23T10:30:00Z",
  
  "events_summary": {
    "total": 100,
    "errors": 25,
    "warnings": 35,
    "info": 40
  },
  
  "patterns": [
    {
      "pattern": "Database connection timeout",
      "frequency": 15,
      "severity": "HIGH",
      "first_occurrence": "2026-09-23T10:15:00Z",
      "last_occurrence": "2026-09-23T10:25:00Z"
    }
  ],
  
  "anomalies": [
    {
      "type": "spike_in_errors",
      "severity": "CRITICAL",
      "description": "Incremento anómalo en errores",
      "confidence": 0.95
    }
  ],
  
  "diagnostic_report": "Texto generado por IA con análisis...",
  
  "recommendations": [
    "Revisar configuración de conexión a BD",
    "Verificar logs del servicio de base de datos",
    "Analizar tráfico de red en el periodo"
  ],
  
  "servicenow_incident": {
    "incident_id": "INC0123456",
    "status": "created",
    "priority": "2",
    "url": "https://servicenow.instance.com/..."
  }
}
```

---

## 🤖 Integración con OLLAMA

### Modelos Soportados
- **phi:2.7b** (predeterminado) - Ligero, rápido, bajo consumo
- **llama3.2:1b** - Más potente, análisis más profundos
- **mistral** - Balance calidad/velocidad

### Prompt Strategy
El agente construye prompts estructurados que incluyen:

```
1. CONTEXTO: Descripción del problema
2. DATOS: Logs estructurados y patrones
3. INSTRUCCIÓN: Qué debe analizar la IA
4. FORMATO: Cómo debe presentar la respuesta
```

Ejemplo de prompt:
```
Analiza los siguientes eventos de log y proporciona:
1. Causa raíz probable
2. Servicios impactados
3. Acciones de remediación

LOGS:
[logs formateados aquí]

PATRONES DETECTADOS:
[patrones aquí]

Responde en formato claro y conciso.
```

### Optimizaciones
- **Caché:** Respuestas duplicadas se reutilizan
- **Streaming:** Procesamiento en tiempo real
- **Timeouts:** Control de latencia máxima
- **Fallback:** Si OLLAMA no responde, retorna análisis basado en patrones

---

## ⚙️ Configuración (Variables de Entorno)

```bash
# OLLAMA
OLLAMA_API_URL=http://localhost:11434
OLLAMA_MODEL=phi:2.7b

# SERVICENOW
SERVICENOW_INSTANCE=dev12345.service-now.com
SERVICENOW_CLIENT_ID=xxxxx
SERVICENOW_CLIENT_SECRET=xxxxx
SERVICENOW_USERNAME=admin
SERVICENOW_PASSWORD=xxxxx

# AGENTE
AGENT_PORT=5000
ENABLE_STREAMING=true
CACHE_ENABLED=true
MAX_TIMEOUT_SECONDS=60

# LOGS
MAX_LOG_SIZE_MB=100
LOG_ENCODING=utf-8
```

---

## 📊 Casos de Uso Principales

### 1. **Análisis Postmortem de Incidentes**
- Cargar todos los logs del período del incidente
- Agente identifica secuencia de eventos
- IA genera narrativa de causa raíz
- Recomendaciones para prevención

### 2. **Detección Proactiva de Problemas**
- Monitoreo continuo de logs
- Detección automática de anomalías
- Alertas inmediatas de patrones críticos
- Creación automática de incidentes

### 3. **Optimización de Performance**
- Análisis de logs de aplicación
- Identificación de cuellos de botella
- Correlación de eventos de performance
- Recomendaciones de tuning

### 4. **Troubleshooting de Servicios**
- Ingesta de logs de múltiples servicios
- Correlación entre servicios
- Identificación de dependencias rotas
- Rutas de escalamiento

---

## 🚀 Tecnologías Utilizadas

| Componente | Tecnología | Versión |
|-----------|-----------|---------|
| Lenguaje | Python | 3.8+ |
| Framework Web | Flask | 2.x |
| LLM | OLLAMA | Latest |
| ITSM | ServiceNow | Cloud |
| Contenedor | Docker | Latest |
| Orquestación | Mulesoft | 4.x |
| API Gateway | Omni Gateway | Latest |

---

## 📈 Performance y Escalabilidad

### Latencia Típica
```
Análisis de patrones:    < 100ms
Análisis completo:       2-10 segundos
Con IA (OLLAMA):         2-5 segundos adicionales
```

### Throughput
- **Secuencial:** 1 request por timeout
- **Concurrente:** Escalable con replicas del agente
- **Caché:** Aumenta throughput 10x+ en patrones repetidos

### Limitaciones
- Max payload: 100MB por request
- Max timeout: 60 segundos por análisis
- Max resultados: Configurable (default 100 eventos)

---

## 🔒 Seguridad

### Implementado
✅ Validación de entrada (JSON schema)
✅ Sanitización de texto (caracteres especiales)
✅ Timeouts contra DoS
✅ Rate limiting en gateway
✅ Autenticación OAuth2 con ServiceNow
✅ Encoding UTF-8 robusto
✅ Gestión segura de secretos en .env

### Recomendaciones
🔐 Usar HTTPS en producción
🔐 Implementar API keys en gateway
🔐 Auditoría de acceso a ServiceNow
🔐 Rotación regular de tokens

---

## 📝 Resumen Operacional

| Aspecto | Descripción |
|--------|------------|
| **Objetivo** | Análisis inteligente de logs con IA |
| **Entrada** | Logs en texto o JSON |
| **Salida** | Análisis estructurado + recomendaciones |
| **Tiempo procesamiento** | 2-10 segundos |
| **Integración** | ServiceNow, Mulesoft, OLLAMA |
| **Escalabilidad** | Horizontal (múltiples instancias) |
| **Dependencias** | OLLAMA, Python, Docker (recomendado) |
| **Deployment** | Local, Docker, Cloud (Render, GCP, AWS) |

---

## 🔗 Referencias y Archivos Relacionados

- Guía de inicio: `START_HERE.md`
- Documentación de API: `API_MULTIPLE_FORMATS.md`
- Guía de despliegue Docker: `DOCKER_DEPLOY_GUIDE.md`
- Integración OLLAMA Cloud: `OLLAMA_CLOUD_AUTH_GUIDE.md`
- Guía de integración: Proyecto `log-analyzer-omni-gateway`

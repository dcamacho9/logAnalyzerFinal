# 🚀 QUICK START: ngrok Activo 24/7 en 2 Minutos

> **Elige tu opción y sigue los pasos**

---

## ⚡ OPCIÓN A: La Más Rápida (Solo abrir terminal)

```powershell
# Abre PowerShell y ejecuta:
powershell -ExecutionPolicy Bypass -File ngrok_24_7.ps1

# ✅ ¡Listo! ngrok está activo en esa ventana
# La URL se muestra en pantalla
# Mantén esta ventana abierta
```

**Ventajas:** Rápido, logs en tiempo real  
**Desventajas:** Ventana debe estar abierta  
**URL:** Cambia cada 8 horas ⚠️  

---

## 🛠️ OPCIÓN B: Automático 24/7 (RECOMENDADO)

```powershell
# 1. Abre PowerShell COMO ADMINISTRADOR

# 2. Ejecuta este comando:
powershell -ExecutionPolicy Bypass -File install_ngrok_service.ps1

# 3. Presiona Enter en todas las preguntas
# ✅ ¡Listo! ngrok se inicia automáticamente cada vez que enciendes el PC

# Para verificar después:
Get-Service ngrok-log-analyzer
```

**Ventajas:** Automático, robusto, reintentos automáticos  
**Desventajas:** URL cambia cada 8 horas  
**URL:** Cambia cada 8 horas ⚠️  

---

## 🌐 OPCIÓN C: URL Permanente (Mejor que ngrok)

```powershell
# 1. Abre PowerShell

# 2. Ejecuta:
powershell -ExecutionPolicy Bypass -File cloudflare_tunnel_setup.ps1

# 3. Se abrirá tu navegador para autorizar
# ✅ ¡Listo! ngrok está activo con URL permanente

# Para iniciar manual después:
cloudflared tunnel run log-analyzer-agent
```

**Ventajas:** URL PERMANENTE, gratuito, mejor rendimiento  
**Desventajas:** Setup inicial más largo  
**URL:** Permanente ✅  

---

## 📍 OBTENER URL ACTUAL

Una vez que ngrok está corriendo (cualquier opción):

```powershell
# Obtener URL y copiar al portapapeles:
powershell -ExecutionPolicy Bypass -File ngrok_url_manager.ps1 -Command get

# Ver monitoreo en tiempo real:
powershell -ExecutionPolicy Bypass -File ngrok_url_manager.ps1 -Command monitor

# Actualizar archivo con URL:
powershell -ExecutionPolicy Bypass -File ngrok_url_manager.ps1 -Command update -OutputFile "C:\url.txt"
```

---

## 🧪 PROBAR QUE FUNCIONA

```powershell
# En PowerShell, ejecuta:
$url = (Invoke-WebRequest -Uri 'http://localhost:4040/api/tunnels').Content | ConvertFrom-Json | Select-Object -ExpandProperty tunnels | Select-Object -First 1 | Select-Object -ExpandProperty public_url

Write-Host "✅ URL Pública: $url"

# Prueba acceso:
Invoke-WebRequest -Uri "$url/api/health"
```

---

## 📊 TABLA COMPARATIVA RÁPIDA

| Aspecto | Opción A | Opción B | Opción C |
|---------|----------|----------|----------|
| Velocidad setup | ⚡⚡⚡ 30s | ⚡⚡ 1m | ⚡ 3m |
| Automático 24/7 | ❌ | ✅ | ✅ |
| URL permanente | ❌ | ❌ | ✅ |
| Ventana abierta | ✅ Necesaria | ❌ | ❌ |
| Costo | Gratis | Gratis | Gratis |
| Recomendado para | Testing | Producción | Mejor opción |

---

## 🎯 MI RECOMENDACIÓN

**Si quieres máxima facilidad:** OPCIÓN B (Servicio Windows)  
**Si quieres URL permanente:** OPCIÓN C (CloudFlare Tunnel)  
**Si quieres ver logs:** OPCIÓN A (Monitor en tiempo real)  

---

## ⚠️ PROBLEMAS COMUNES

### ngrok no inicia
```powershell
# Verificar que está instalado:
ngrok --version

# Si no funciona, descarga desde:
# https://ngrok.com/download
```

### "Acceso denegado" en install
```powershell
# Necesitas ser Administrador. Abre PowerShell con clic derecho → "Ejecutar como administrador"
```

### URL no funciona
```powershell
# Espera 30 segundos a que ngrok inicialice
# Luego obtén la URL:
powershell -ExecutionPolicy Bypass -File ngrok_url_manager.ps1 -Command get
```

### Servicio no arranca después de reinicio
```powershell
# Verificar estado:
Get-Service ngrok-log-analyzer

# Iniciar manual:
Start-Service ngrok-log-analyzer

# Reiniciar:
Restart-Service ngrok-log-analyzer
```

---

## 📞 REFERENCIAS COMPLETAS

Para más detalles sobre cada opción, lee:  
→ [NGROK_24_7_GUIDE.md](NGROK_24_7_GUIDE.md)

Para ejemplos de integración con Mulesoft:  
→ [NGROK_24_7_GUIDE.md#integración-con-mulesoft](NGROK_24_7_GUIDE.md)

---

## ✅ SIGUIENTE PASO

1. **Elige una opción arriba**
2. **Copia el comando y ejecuta**
3. **Verifica: `powershell -ExecutionPolicy Bypass -File ngrok_url_manager.ps1 -Command get`**
4. **¡Usa la URL para integrar con Mulesoft!**

---

**¿Necesitas ayuda?** Consulta `NGROK_24_7_GUIDE.md` para troubleshooting detallado.

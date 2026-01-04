# 🔧 Solución: Error "Connection refused" al iniciar sesión

## 🔍 Diagnóstico del Problema

El error **"Connection refused"** ocurre cuando la aplicación Flutter no puede conectarse al backend. Esto suele pasar porque:

1. **El backend no está corriendo** - El servidor NestJS debe estar activo
2. **URL incorrecta** - Si ejecutas en dispositivo físico o emulador, `localhost` no funciona
3. **Firewall bloqueando** - El firewall puede estar bloqueando el puerto 3001

---

## ✅ Solución Paso a Paso

### Paso 1: Verificar que el Backend esté Corriendo

Abre una terminal y ejecuta:

```bash
cd finanzas-api
pnpm run start:dev
```

Deberías ver algo como:
```
🚀 Servidor corriendo en: http://localhost:3001
✨ Documentación Scalar: http://localhost:3001/scalar
```

**Si no está corriendo, inícialo primero.**

---

### Paso 2: Identificar Dónde Ejecutas la App

#### 📱 **Si ejecutas en un DISPOSITIVO FÍSICO o EMULADOR ANDROID:**

Necesitas usar la **IP de tu computadora** en lugar de `localhost`.

**Obtener tu IP (Windows):**
```powershell
ipconfig
```
Busca la línea que dice "Dirección IPv4" (ejemplo: `192.168.1.6`)

**Obtener tu IP (Mac/Linux):**
```bash
ifconfig | grep "inet "
```

**Ejecutar la app con la IP correcta:**
```bash
cd finanzasapp
flutter run --dart-define=API_BASE_URL=http://TU_IP:3001
```

**Ejemplo con la IP 192.168.1.6:**
```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.6:3001
```

#### 💻 **Si ejecutas en WEB o DESKTOP:**

Puedes usar `localhost` directamente:
```bash
cd finanzasapp
flutter run -d chrome  # Para web
# o
flutter run -d windows  # Para Windows desktop
```

#### 📱 **Si ejecutas en EMULADOR ANDROID:**

Para el emulador de Android, usa la IP especial `10.0.2.2`:
```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3001
```

#### 🍎 **Si ejecutas en EMULADOR iOS:**

Puedes usar `localhost`:
```bash
flutter run
```

---

### Paso 3: Verificar el Firewall

Si aún no funciona, verifica que el firewall de Windows no esté bloqueando el puerto 3001:

1. Abre **Windows Defender Firewall**
2. Ve a **Configuración avanzada**
3. Verifica que el puerto 3001 esté permitido para conexiones entrantes

O temporalmente desactiva el firewall para probar (solo para desarrollo).

---

### Paso 4: Verificar la Conexión de Red

Asegúrate de que:
- Tu dispositivo/emulador y tu computadora estén en la **misma red WiFi**
- No uses una VPN que pueda interferir
- El router no tenga restricciones de red local

---

## 🧪 Probar la Conexión

### Opción 1: Desde el navegador
Abre en tu navegador (o en el dispositivo):
```
http://TU_IP:3001/scalar
```
Si ves la documentación del API, el backend está accesible.

### Opción 2: Desde la app Flutter
Después de ejecutar con la IP correcta, intenta iniciar sesión nuevamente.

---

## 📝 Comandos Rápidos

### Tu IP actual (según el sistema):
**Windows:**
```powershell
ipconfig | Select-String "IPv4"
```

**Mac/Linux:**
```bash
ifconfig | grep "inet " | grep -v 127.0.0.1
```

### Ejecutar app con tu IP (reemplaza 192.168.1.6 con tu IP):
```bash
cd finanzasapp
flutter run --dart-define=API_BASE_URL=http://192.168.1.6:3001
```

---

## 🎯 Resumen

1. ✅ **Backend corriendo** en `http://localhost:3001`
2. ✅ **Obtener tu IP** con `ipconfig` (Windows) o `ifconfig` (Mac/Linux)
3. ✅ **Ejecutar app** con: `flutter run --dart-define=API_BASE_URL=http://TU_IP:3001`
4. ✅ **Verificar firewall** si aún no funciona

---

## 💡 Tip: Crear un Script para Facilitar

Puedes crear un archivo `run_app.bat` (Windows) o `run_app.sh` (Mac/Linux) para automatizar esto:

**Windows (run_app.bat):**
```batch
@echo off
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /c:"IPv4"') do set IP=%%a
set IP=%IP:~1%
echo Ejecutando app con IP: %IP%
cd finanzasapp
flutter run --dart-define=API_BASE_URL=http://%IP%:3001
```

**Mac/Linux (run_app.sh):**
```bash
#!/bin/bash
IP=$(ifconfig | grep "inet " | grep -v 127.0.0.1 | awk '{print $2}' | head -1)
echo "Ejecutando app con IP: $IP"
cd finanzasapp
flutter run --dart-define=API_BASE_URL=http://$IP:3001
```

---

## ❓ ¿Aún no funciona?

Si después de seguir estos pasos aún tienes problemas:

1. Verifica que el backend esté realmente corriendo (abre http://localhost:3001/scalar en tu navegador)
2. Verifica que la IP sea correcta y que tu dispositivo esté en la misma red
3. Prueba desactivar temporalmente el firewall
4. Revisa los logs del backend para ver si llegan las peticiones


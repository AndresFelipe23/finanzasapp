# 🚀 Guía de Ejecución del Proyecto Finanzas

Este proyecto consta de dos partes principales:
1. **Backend API** (NestJS) - `finanzas-api/`
2. **Aplicación Flutter** - `finanzasapp/`

---

## 📋 Requisitos Previos

### Para el Backend:
- [Node.js](https://nodejs.org/) (versión 18 o superior)
- [pnpm](https://pnpm.io/) - Gestor de paquetes
- [SQL Server](https://www.microsoft.com/sql-server) - Base de datos

### Para la App Flutter:
- [Flutter SDK](https://flutter.dev/docs/get-started/install) (versión 3.9.2 o superior)
- Android Studio / Xcode (para desarrollo móvil)
- Un dispositivo físico o emulador

---

## 🔧 Configuración del Backend (finanzas-api)

### 1. Instalar dependencias

```bash
cd finanzas-api
pnpm install
```

Si no tienes `pnpm` instalado:
```bash
npm install -g pnpm
```

### 2. Configurar la Base de Datos

1. **Crear la base de datos SQL Server:**
   - Ejecuta el script `Database/database-schema.sql` en tu servidor SQL Server
   - O crea manualmente la base de datos `FinanzasApiApp`

2. **Configurar variables de entorno:**
   - Copia el archivo `.env.example` a `.env`:
   ```bash
   cp .env.example .env
   ```
   
   - Edita el archivo `.env` con tus credenciales:
   ```env
   DB_HOST=localhost
   DB_PORT=1433
   DB_USERNAME=sa
   DB_PASSWORD=tu_contraseña
   DB_DATABASE=FinanzasApiApp
   DB_SYNCHRONIZE=false
   DB_LOGGING=true
   JWT_SECRET=tu_clave_secreta_super_segura_aqui
   PORT=3001
   ```

### 3. Ejecutar el servidor

**Modo desarrollo (con recarga automática):**
```bash
pnpm run start:dev
```

**Modo producción:**
```bash
pnpm run build
pnpm run start:prod
```

**Modo normal:**
```bash
pnpm run start
```

El servidor estará disponible en:
- **API:** http://localhost:3001/api
- **Documentación Scalar:** http://localhost:3001/scalar
- **Documentación Swagger:** http://localhost:3001/api/docs

---

## 📱 Configuración de la App Flutter (finanzasapp)

### 1. Instalar dependencias

```bash
cd finanzasapp
flutter pub get
```

### 2. Configurar la URL del API

Asegúrate de que la app esté configurada para apuntar al backend. Revisa el archivo de configuración de la API (probablemente en `lib/core/` o similar) y verifica que la URL base sea:
```
http://localhost:3001/api
```

**Nota:** Si ejecutas en un dispositivo físico, usa la IP de tu computadora en lugar de `localhost`:
```
http://192.168.1.X:3001/api
```

### 3. Ejecutar la aplicación

**Verificar dispositivos disponibles:**
```bash
flutter devices
```

**Ejecutar en modo desarrollo:**
```bash
flutter run
```

**Ejecutar en un dispositivo específico:**
```bash
flutter run -d <device-id>
```

**Ejecutar en modo release:**
```bash
flutter run --release
```

---

## 🎯 Orden de Ejecución Recomendado

1. **Primero:** Inicia el backend (finanzas-api)
   ```bash
   cd finanzas-api
   pnpm run start:dev
   ```

2. **Segundo:** Verifica que el backend esté corriendo accediendo a:
   - http://localhost:3001/scalar

3. **Tercero:** Inicia la app Flutter
   ```bash
   cd finanzasapp
   flutter run
   ```

---

## 🐛 Solución de Problemas

### Backend no se conecta a la base de datos
- Verifica que SQL Server esté corriendo
- Revisa las credenciales en el archivo `.env`
- Asegúrate de que la base de datos `FinanzasApiApp` exista
- Verifica que el puerto 1433 esté abierto

### La app Flutter no se conecta al backend
- Verifica que el backend esté corriendo en el puerto 3001
- Si usas un dispositivo físico, cambia `localhost` por la IP de tu computadora
- Revisa la configuración de CORS en el backend (ya está habilitada para desarrollo)

### Error al instalar dependencias
- Para el backend: `pnpm install --force`
- Para Flutter: `flutter clean && flutter pub get`

---

## 📚 Comandos Útiles

### Backend:
```bash
# Desarrollo con watch
pnpm run start:dev

# Compilar
pnpm run build

# Ejecutar tests
pnpm run test

# Linting
pnpm run lint
```

### Flutter:
```bash
# Limpiar build
flutter clean

# Obtener dependencias
flutter pub get

# Analizar código
flutter analyze

# Ejecutar tests
flutter test
```

---

## 🔗 Enlaces Útiles

- **Documentación NestJS:** https://docs.nestjs.com
- **Documentación Flutter:** https://docs.flutter.dev
- **API Documentation:** http://localhost:3001/scalar (cuando el backend esté corriendo)


# Financially 💰

Aplicación móvil de gestión financiera personal desarrollada con Flutter y NestJS. Permite a los usuarios controlar sus ingresos, gastos, cuentas, transacciones y metas financieras de manera sencilla e intuitiva.

## 📱 Características

### Funcionalidades Principales

- **Gestión de Cuentas**: Crea y administra múltiples cuentas (bancarias, efectivo, tarjetas, etc.)
- **Transacciones**: Registra ingresos y gastos con categorías personalizadas
- **Monedas**: Soporte para múltiples monedas de países de habla hispana
- **Metas Financieras**: Establece y rastrea metas de ahorro
- **Préstamos**: Gestiona préstamos y pagos
- **Presupuestos**: Crea y controla presupuestos mensuales
- **Categorías Personalizadas**: Crea tus propias categorías de ingresos y gastos
- **Dashboard**: Vista resumida de tu situación financiera
- **Perfil de Usuario**: Personaliza tu información y moneda predeterminada

### Tecnologías

- **Frontend**: Flutter (Dart)
- **Backend**: NestJS (TypeScript)
- **Base de Datos**: SQL Server
- **Autenticación**: JWT (JSON Web Tokens)
- **Estado**: Riverpod
- **Almacenamiento Seguro**: Flutter Secure Storage

## 🚀 Instalación y Configuración

### Requisitos Previos

- Flutter SDK (3.9.2 o superior)
- Dart SDK
- Node.js y npm/pnpm
- SQL Server
- Android Studio / Xcode (para desarrollo móvil)

### Configuración del Backend

1. Navega a la carpeta del backend:
```bash
cd finanzas-api
```

2. Instala las dependencias:
```bash
pnpm install
```

3. Configura las variables de entorno creando un archivo `.env`:
```env
DB_HOST=localhost
DB_PORT=1433
DB_USERNAME=tu_usuario
DB_PASSWORD=tu_contraseña
DB_DATABASE=FinanzasApiApp
JWT_SECRET=tu_clave_secreta_jwt
BCRYPT_ROUNDS=10
```

4. Ejecuta las migraciones de la base de datos (ver `Database/database-schema.sql`)

5. Inicia el servidor:
```bash
pnpm run start:dev
```

El backend estará disponible en `http://localhost:3001`

### Configuración de la App Flutter

1. Navega a la carpeta de la app:
```bash
cd finanzasapp
```

2. Instala las dependencias:
```bash
flutter pub get
```

3. Configura la URL del API:

#### Para Desarrollo Local:
```bash
flutter run --dart-define=API_BASE_URL=http://localhost:3001/api
```

#### Para Dispositivo Físico Android:
```bash
# Obtén tu IP local (ej: 192.168.1.6)
flutter run --dart-define=API_BASE_URL=http://TU_IP:3001/api
```

#### Para Emulador Android:
```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3001/api
```

#### Para Producción:
```bash
flutter run --dart-define=API_BASE_URL=https://gestiondinero.site/api
```

## 🔐 Configuración de Firma para Release

### 1. Generar Keystore

Ejecuta el siguiente comando para generar tu keystore:

```bash
keytool -genkey -v -keystore android/keystore/financially-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias financially
```

**Importante**: Guarda las contraseñas y el alias de forma segura. Necesitarás:
- Store password
- Key password
- Key alias: `financially`

### 2. Configurar key.properties

Edita el archivo `android/key.properties` y completa con tus contraseñas:

```properties
storePassword=TU_STORE_PASSWORD
keyPassword=TU_KEY_PASSWORD
keyAlias=financially
storeFile=../keystore/financially-release.jks
```

### 3. Compilar APK/AAB para Release

```bash
# APK
flutter build apk --release --dart-define=API_BASE_URL=https://gestiondinero.site/api

# AAB (recomendado para Play Store)
flutter build appbundle --release --dart-define=API_BASE_URL=https://gestiondinero.site/api
```

El archivo generado estará en:
- APK: `build/app/outputs/flutter-apk/app-release.apk`
- AAB: `build/app/outputs/bundle/release/app-release.aab`

## 📦 Estructura del Proyecto

```
Finanzas/
├── finanzas-api/              # Backend NestJS
│   ├── src/
│   │   ├── auth/              # Autenticación
│   │   ├── cuentas/           # Gestión de cuentas
│   │   ├── transacciones/     # Transacciones
│   │   ├── categorias/        # Categorías
│   │   ├── metas/             # Metas financieras
│   │   ├── prestamos/         # Préstamos
│   │   ├── presupuestos/      # Presupuestos
│   │   └── common/            # Utilidades comunes
│   └── Database/              # Scripts SQL
│
└── finanzasapp/               # App Flutter
    ├── lib/
    │   ├── core/              # Configuración, modelos, API
    │   └── features/          # Pantallas y funcionalidades
    └── android/               # Configuración Android
```

## 🌍 Monedas Soportadas

La aplicación soporta las siguientes monedas de países de habla hispana:

- **COP** - Peso Colombiano (Colombia)
- **ARS** - Peso Argentino (Argentina)
- **CLP** - Peso Chileno (Chile)
- **PEN** - Sol Peruano (Perú)
- **BOB** - Boliviano (Bolivia)
- **PYG** - Guaraní (Paraguay)
- **UYU** - Peso Uruguayo (Uruguay)
- **VES** - Bolívar Soberano (Venezuela)
- **MXN** - Peso Mexicano (México)
- **GTQ** - Quetzal (Guatemala)
- **HNL** - Lempira (Honduras)
- **NIO** - Córdoba (Nicaragua)
- **CRC** - Colón (Costa Rica)
- **PAB** - Balboa (Panamá)
- **DOP** - Peso Dominicano (República Dominicana)
- **CUP** - Peso Cubano (Cuba)
- **USD** - Dólar Estadounidense (Ecuador, El Salvador, Panamá)
- **EUR** - Euro (España)

## 🔒 Seguridad

- Autenticación mediante JWT
- Almacenamiento seguro de tokens
- Validación de datos en frontend y backend
- HTTPS obligatorio en producción
- Protección contra inyección SQL mediante stored procedures

## 📝 Variables de Entorno

### Backend (.env)

```env
DB_HOST=localhost
DB_PORT=1433
DB_USERNAME=usuario
DB_PASSWORD=contraseña
DB_DATABASE=FinanzasApiApp
JWT_SECRET=clave_secreta_jwt
BCRYPT_ROUNDS=10
```

### Frontend (dart-define)

```bash
--dart-define=API_BASE_URL=https://api.example.com/api
```

## 🧪 Testing

### Backend
```bash
cd finanzas-api
pnpm run test
```

### Frontend
```bash
cd finanzasapp
flutter test
```

## 📱 Build para Producción

### Android

1. Configura el keystore (ver sección de Firma)
2. Compila el AAB:
```bash
flutter build appbundle --release --dart-define=API_BASE_URL=https://gestiondinero.site/api
```

3. Sube el archivo `app-release.aab` a Google Play Console

### iOS (futuro)

```bash
flutter build ios --release --dart-define=API_BASE_URL=https://gestiondinero.site/api
```

## 🐛 Troubleshooting

### Error de conexión al backend

- Verifica que el backend esté corriendo
- Confirma que la URL del API sea correcta
- Para dispositivos físicos, usa la IP de tu computadora, no `localhost`
- Verifica que el firewall permita conexiones en el puerto 3001

### Error de autenticación

- Verifica que el token JWT no haya expirado
- Confirma que `JWT_SECRET` sea el mismo en backend y frontend
- Revisa los logs del backend para más detalles

### Problemas con la base de datos

- Verifica que SQL Server esté corriendo
- Confirma las credenciales en el archivo `.env`
- Ejecuta los scripts SQL en `Database/` en orden

## 📄 Licencia

Este proyecto es propiedad de AFESDEV.

## 👨‍💻 Desarrollador

**AFESDEV**
- Email: afesdev2025@gmail.com
- Desarrollado con Flutter y NestJS

## 🔗 Enlaces Útiles

- [Documentación de Flutter](https://docs.flutter.dev/)
- [Documentación de NestJS](https://docs.nestjs.com/)
- [Google Play Console](https://play.google.com/console)

## 📞 Soporte

Para soporte técnico, contacta a: afesdev2025@gmail.com

---

**Versión**: 1.0.0  
**Última actualización**: Enero 2025

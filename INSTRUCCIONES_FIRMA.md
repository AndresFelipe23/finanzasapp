# Instrucciones para Configurar la Firma de la Aplicación

## Paso 1: Generar el Keystore

### Opción A: Usar el Script Automático (Recomendado para Windows)

Navega a la carpeta `android` y ejecuta el script PowerShell:

```powershell
cd android
.\generate-keystore.ps1
```

El script buscará automáticamente `keytool` en tu sistema y te guiará paso a paso.

### Opción B: Comando Manual

Si tienes Java JDK instalado y en tu PATH, ejecuta:

```bash
keytool -genkey -v -keystore android/keystore/financially-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias financially
```

### Opción C: Si no tienes Java instalado

1. **Instalar Java JDK:**
   - Descarga desde: https://adoptium.net/ (recomendado)
   - O instala Android Studio que incluye Java

2. **O usar Android Studio:**
   - Abre Android Studio
   - Ve a `Build > Generate Signed Bundle / APK`
   - Selecciona `Android App Bundle`
   - Crea un nuevo keystore desde ahí
   - Guarda el keystore en `android/keystore/financially-release.jks`

Te pedirá la siguiente información:
- **Contraseña del keystore**: Elige una contraseña segura y guárdala
- **Contraseña de la clave**: Puede ser la misma o diferente, también guárdala
- **Nombre y apellidos**: Tu nombre o el de tu organización
- **Unidad organizativa**: (opcional)
- **Organización**: AFESDEV
- **Ciudad o localidad**: Tu ciudad
- **Estado o provincia**: Tu estado/provincia
- **Código de país**: Código de 2 letras (ej: GT, MX, CO)

**IMPORTANTE**: 
- ⚠️ **NO PIERDAS** el archivo `financially-release.jks`
- ⚠️ **NO OLVIDES** las contraseñas
- ⚠️ Si pierdes el keystore o las contraseñas, **NO PODRÁS** actualizar la app en Play Store

## Paso 2: Configurar key.properties

Edita el archivo `android/key.properties` y completa con tus contraseñas reales:

```properties
storePassword=TU_STORE_PASSWORD_AQUI
keyPassword=TU_KEY_PASSWORD_AQUI
keyAlias=financially
storeFile=../keystore/financially-release.jks
```

## Paso 3: Verificar que el archivo existe

Asegúrate de que el archivo `android/keystore/financially-release.jks` existe.

## Paso 4: Compilar para Release

Una vez configurado, puedes compilar:

```bash
# Para APK
flutter build apk --release --dart-define=API_BASE_URL=https://gestiondinero.site/api

# Para AAB (recomendado para Play Store)
flutter build appbundle --release --dart-define=API_BASE_URL=https://gestiondinero.site/api
```

## Seguridad

- **NO** subas `key.properties` ni `financially-release.jks` a Git
- Ambos archivos están en `.gitignore`
- Guarda una copia de seguridad del keystore en un lugar seguro
- Considera usar un gestor de contraseñas para las contraseñas

## Notas

- El keystore es válido por 10,000 días (aproximadamente 27 años)
- Puedes usar el mismo keystore para todas las versiones futuras de la app
- Si necesitas cambiar el keystore en el futuro, los usuarios tendrán que desinstalar y reinstalar la app


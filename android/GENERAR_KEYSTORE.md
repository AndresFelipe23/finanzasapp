# Generar Keystore - Guía Rápida

## ✅ keytool encontrado

El script encontró `keytool` en tu sistema:
```
C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe
```

## 📝 Pasos para generar el keystore

### Opción 1: Ejecutar el script (Recomendado)

1. Abre PowerShell en la carpeta `android`:
```powershell
cd finanzasapp\android
```

2. Ejecuta el script:
```powershell
.\generate-keystore.ps1
```

3. Cuando te pida las contraseñas:
   - **Contraseña del almacén (store password)**: Mínimo 6 caracteres
   - **Contraseña de la clave (key password)**: Mínimo 6 caracteres (puede ser la misma)
   - **Nombre y apellidos**: Tu nombre o el de tu organización
   - **Unidad organizativa**: (opcional, presiona Enter)
   - **Organización**: AFESDEV
   - **Ciudad o localidad**: Tu ciudad
   - **Estado o provincia**: Tu estado/provincia
   - **Código de país**: Código de 2 letras (ej: GT, MX, CO, ES)

### Opción 2: Comando manual

Ejecuta este comando en PowerShell:

```powershell
& "C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe" -genkey -v -keystore .\keystore\financially-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias financially
```

**IMPORTANTE**: 
- Las contraseñas deben tener **mínimo 6 caracteres**
- Guarda las contraseñas en un lugar seguro
- Necesitarás estas contraseñas para compilar en release

## 🔐 Después de generar el keystore

1. Edita el archivo `android/key.properties` y completa con tus contraseñas:
```properties
storePassword=TU_STORE_PASSWORD_AQUI
keyPassword=TU_KEY_PASSWORD_AQUI
keyAlias=financially
storeFile=../keystore/financially-release.jks
```

2. ¡Listo! Ya puedes compilar para release.

## ⚠️ Recordatorios importantes

- **NO** subas `key.properties` ni el archivo `.jks` a Git
- Haz una copia de seguridad del keystore en un lugar seguro
- Si pierdes el keystore o las contraseñas, NO podrás actualizar la app en Play Store


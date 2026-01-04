# Script para generar el keystore de Financially
# Este script busca keytool automaticamente y genera el keystore

Write-Host "Buscando keytool..." -ForegroundColor Cyan

# Rutas comunes donde puede estar keytool
$possiblePaths = @(
    "$env:JAVA_HOME\bin\keytool.exe",
    "C:\Program Files\Java\*\bin\keytool.exe",
    "C:\Program Files (x86)\Java\*\bin\keytool.exe",
    "$env:LOCALAPPDATA\Android\Sdk\jre\bin\keytool.exe",
    "$env:ProgramFiles\Android\Android Studio\jbr\bin\keytool.exe",
    "$env:ProgramFiles\Android\Android Studio\jre\bin\keytool.exe",
    "$env:LOCALAPPDATA\Android\AndroidStudio*\jbr\bin\keytool.exe"
)

$keytoolPath = $null

# Buscar keytool en las rutas comunes
foreach ($path in $possiblePaths) {
    try {
        $resolved = Resolve-Path $path -ErrorAction SilentlyContinue
        if ($resolved) {
            $keytoolPath = $resolved[0].Path
            break
        }
    } catch {
        # Continuar buscando
    }
}

# Si no se encontro, buscar en todo el sistema (mas lento)
if (-not $keytoolPath) {
    Write-Host "Buscando keytool en el sistema..." -ForegroundColor Yellow
    $keytoolPath = Get-Command keytool -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source
}

if (-not $keytoolPath) {
    Write-Host "No se encontro keytool en el sistema." -ForegroundColor Red
    Write-Host ""
    Write-Host "Para instalar Java JDK:" -ForegroundColor Yellow
    Write-Host "1. Descarga Java JDK desde: https://adoptium.net/" -ForegroundColor White
    Write-Host "2. O instala Android Studio que incluye Java" -ForegroundColor White
    Write-Host ""
    Write-Host "Alternativamente, puedes usar Android Studio:" -ForegroundColor Yellow
    Write-Host "1. Abre Android Studio" -ForegroundColor White
    Write-Host "2. Ve a Build > Generate Signed Bundle / APK" -ForegroundColor White
    Write-Host "3. Crea un nuevo keystore desde ahi" -ForegroundColor White
    exit 1
}

Write-Host "keytool encontrado en: $keytoolPath" -ForegroundColor Green
Write-Host ""

# Crear directorio keystore si no existe
$keystoreDir = Join-Path $PSScriptRoot "keystore"
if (-not (Test-Path $keystoreDir)) {
    New-Item -ItemType Directory -Path $keystoreDir | Out-Null
    Write-Host "Directorio keystore creado" -ForegroundColor Green
}

$keystorePath = Join-Path $keystoreDir "financially-release.jks"

# Verificar si el keystore ya existe
if (Test-Path $keystorePath) {
    Write-Host "El keystore ya existe en: $keystorePath" -ForegroundColor Yellow
    $overwrite = Read-Host "Deseas sobrescribirlo? (s/N)"
    if ($overwrite -ne "s" -and $overwrite -ne "S") {
        Write-Host "Operacion cancelada." -ForegroundColor Yellow
        exit 0
    }
}

Write-Host "Generando keystore..." -ForegroundColor Cyan
Write-Host ""
Write-Host "Te pedira la siguiente informacion:" -ForegroundColor Yellow
Write-Host "- Contrasena del keystore (MINIMO 6 CARACTERES - guardala bien)" -ForegroundColor White
Write-Host "- Contrasena de la clave (MINIMO 6 CARACTERES - puede ser la misma)" -ForegroundColor White
Write-Host "- Informacion personal (nombre, organizacion, etc.)" -ForegroundColor White
Write-Host ""
Write-Host "IMPORTANTE: Las contrasenas deben tener al menos 6 caracteres" -ForegroundColor Red
Write-Host ""

# Ejecutar keytool
& $keytoolPath -genkey -v -keystore $keystorePath -keyalg RSA -keysize 2048 -validity 10000 -alias financially

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "Keystore generado exitosamente!" -ForegroundColor Green
    Write-Host "Ubicacion: $keystorePath" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "IMPORTANTE:" -ForegroundColor Yellow
    Write-Host "1. Guarda las contrasenas en un lugar seguro" -ForegroundColor White
    Write-Host "2. Haz una copia de seguridad del archivo .jks" -ForegroundColor White
    Write-Host "3. Edita android/key.properties con tus contrasenas" -ForegroundColor White
} else {
    Write-Host ""
    Write-Host "Error al generar el keystore" -ForegroundColor Red
    exit 1
}

@echo off
echo ========================================
echo   Ejecutando App Flutter con IP Local
echo ========================================
echo.

REM Obtener la IP local
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /c:"IPv4"') do set IP=%%a
set IP=%IP:~1%

echo Tu IP local es: %IP%
echo.
echo Ejecutando app con URL: http://%IP%:3001
echo.
echo IMPORTANTE: Asegurate de que el backend este corriendo!
echo Presiona cualquier tecla para continuar...
pause >nul

cd /d "%~dp0"
flutter run --dart-define=API_BASE_URL=http://%IP%:3001


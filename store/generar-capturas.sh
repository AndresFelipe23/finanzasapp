#!/usr/bin/env bash
# Genera las capturas de Play Store (1080 × 1920) a partir de capturas/N.png
# usando fuentes/captura.html. Uso: bash generar-capturas.sh
cd "$(dirname "$0")"
E="/c/Program Files (x86)/Microsoft/Edge/Application/msedge.exe"
W=$(cygpath -w "$PWD"); U=$(cygpath -m "$PWD")
for f in capturas/[0-9].png; do
  n=$(basename "$f" .png)
  "$E" --headless=new --disable-gpu --hide-scrollbars --force-device-scale-factor=1 \
    --allow-file-access-from-files --virtual-time-budget=6000 --window-size=1080,1920 \
    --screenshot="$W\captura-$n-1080x1920.png" "file:///$U/fuentes/captura.html?n=$n" 2>/dev/null
  echo "captura-$n-1080x1920.png"
done

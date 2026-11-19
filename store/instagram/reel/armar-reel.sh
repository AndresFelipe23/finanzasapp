#!/usr/bin/env bash
# Arma el reel de Instagram (1080 × 1920, 30 fps, con música) a partir de los
# clips del video de Play (../../video/clips) y las piezas de
# ../fuentes/reel.html. Uso: bash armar-reel.sh → financially-reel.mp4
set -e
cd "$(dirname "$0")"
F="$LOCALAPPDATA/Microsoft/WinGet/Links/ffmpeg.exe"
P="$LOCALAPPDATA/Microsoft/WinGet/Links/ffprobe.exe"
E="/c/Program Files (x86)/Microsoft/Edge/Application/msedge.exe"
calc() { awk "BEGIN { printf \"%.2f\", $1 }"; }
CLIPS=../../video/clips
MUSICA="../../video/Sigma Slide - The Soundlings.mp3"

# Hueco de la pantalla (igual que en reel.html)
X=240; Y=620; W=600; H=1279
# La grabación es de 1220 × 2712: se quita la barra de estado (112 px)
RECORTE="crop=1220:2600:0:112"

# Piezas (fondos, marco y máscara) desde el HTML
WD=$(cygpath -w "$PWD"); U=$(cygpath -m "$PWD/../fuentes")
foto() { # nombre consulta ancho alto [fondo transparente]
  "$E" --headless=new --disable-gpu --hide-scrollbars --force-device-scale-factor=1 $5 \
    --virtual-time-budget=6000 --window-size=$3,$4 --screenshot="$(cygpath -w "$PWD/piezas/$1.png")" \
    "file:///$U/reel.html?$2" 2>/dev/null >/dev/null
}
for n in 1 2 3 4 5 gancho fin; do foto "fondo-$n" "n=$n" 1080 1920; done
foto bisel "bisel=1" 1080 1920 --default-background-color=00000000
foto mascara "mascara=1" $W $H

# escena  clip  inicio  duración  velocidad  filtro extra (sobre la pantalla escalada)
ESCENAS=(
  "1 clip2 4  16  2   null"
  "2 clip3 14 4   1   null"
  "3 clip4 3  4   1   null"
  "4 clip5 10 4   1   null"
  # Clip 7: tapa los íconos de otras apps del dock hasta que abre la hoja
  "5 clip7 4  4   1   drawbox=x=0:y=1060:w=$W:h=$((H-1060)):color=0x0E1A3A:t=fill:enable='lt(t\,2.6)'"
)

lista=tmp/lista.txt; : > "$lista"
tarjeta() { # nombre duración
  "$F" -v error -y -loop 1 -t "$2" -i "piezas/fondo-$1.png" \
    -vf "fps=30,format=yuv420p,fade=in:st=0:d=0.25,fade=out:st=$(calc "$2 - 0.25"):d=0.25" \
    -video_track_timescale 15360 -c:v libx264 -crf 18 -pix_fmt yuv420p "tmp/$1.mp4"
  echo "file '$1.mp4'" >> "$lista"
}

tarjeta gancho 2.2
for e in "${ESCENAS[@]}"; do
  read -r n clip ini dur vel extra <<< "$e"
  final=$(calc "$dur / $vel")
  "$F" -v error -y -ss "$ini" -t "$dur" -i "$CLIPS/$clip.mp4" \
    -loop 1 -i "piezas/fondo-$n.png" -loop 1 -i piezas/bisel.png -loop 1 -i piezas/mascara.png \
    -filter_complex "[0:v]setpts=(PTS-STARTPTS)/$vel,fps=30,$RECORTE,scale=$W:$H,$extra,format=rgba[p];\
[3:v]format=gray,scale=$W:$H[m];[p][m]alphamerge[pantalla];\
[1:v][pantalla]overlay=$X:$Y:shortest=1[a];[a][2:v]overlay=0:0:shortest=1,format=yuv420p,\
fade=in:st=0:d=0.2,fade=out:st=$(calc "$final - 0.2"):d=0.2[v]" \
    -map "[v]" -t "$final" -r 30 -video_track_timescale 15360 -c:v libx264 -crf 18 -pix_fmt yuv420p "tmp/escena$n.mp4"
  echo "file 'escena$n.mp4'" >> "$lista"
done
tarjeta fin 3

"$F" -v error -y -f concat -safe 0 -i "$lista" -c:v libx264 -crf 18 -pix_fmt yuv420p -r 30 tmp/sin-audio.mp4

# Música: recortada al largo del reel, entrada y salida suaves, -14 LUFS
D=$("$P" -v error -show_entries format=duration -of csv=p=0 tmp/sin-audio.mp4)
"$F" -v error -y -i tmp/sin-audio.mp4 -i "$MUSICA" -map 0:v -map 1:a -c:v copy \
  -af "atrim=0:$D,asetpts=PTS-STARTPTS,afade=t=in:d=0.5,afade=t=out:st=$(calc "$D - 2"):d=2,loudnorm=I=-14:TP=-2:LRA=11,alimiter=limit=0.84:level=false" \
  -ar 48000 -c:a aac -b:a 192k -shortest -movflags +faststart financially-reel.mp4
echo "Listo: financially-reel.mp4 ($D s)"

#!/usr/bin/env bash
# Arma el video de Play Store (1920 × 1080, 30 fps) a partir de los clips
# grabados con adb (clips/clipN.mp4) y las piezas de fuentes/escena.html
# (piezas/fondo-N.png y piezas/bisel.png). Uso: bash armar-video.sh
# Resultado: financially-video.mp4
set -e
cd "$(dirname "$0")"
F="$LOCALAPPDATA/Microsoft/WinGet/Links/ffmpeg.exe"
mkdir -p tmp
calc() { awk "BEGIN { printf \"%.2f\", $1 }"; }

# Hueco de la pantalla en el marco (igual que en escena.html)
X=1180; Y=92; W=420; H=896
# Las esquinas del video se redondean con piezas/mascara.png (radio 44)
# La grabación es de 1220 × 2712: se quita la barra de estado (112 px)
RECORTE="crop=1220:2600:0:112"

# escena  clip  inicio  duración  velocidad  filtro extra (sobre la pantalla ya escalada)
ESCENAS=(
  "1 clip1 10 7   1   null"
  "2 clip2 4  18  1.6 null"
  "3 clip3 13 6   1   null"
  "4 clip4 3  6   1   null"
  "5 clip5 4  12  1.5 null"
  "6 clip6 14 8   1   null"
  # Clip 7: tapa los íconos de otras apps del dock hasta que abre la hoja
  "7 clip7 4  6   1   drawbox=x=0:y=730:w=$W:h=$((H-730)):color=0x0E1A3A:t=fill:enable='lt(t\,2.6)'"
)

lista=tmp/lista.txt
: > "$lista"

tarjeta() { # nombre duración
  "$F" -v error -y -loop 1 -t "$2" -i "piezas/fondo-$1.png" \
    -vf "fps=30,format=yuv420p,fade=in:st=0:d=0.4,fade=out:st=$(calc "$2 - 0.4"):d=0.4" \
    -video_track_timescale 15360 -c:v libx264 -crf 18 -pix_fmt yuv420p "tmp/$1.mp4"
  echo "file '$1.mp4'" >> "$lista"
}

tarjeta intro 3
for e in "${ESCENAS[@]}"; do
  read -r n clip ini dur vel extra <<< "$e"
  final=$(calc "$dur / $vel")
  "$F" -v error -y -ss "$ini" -t "$dur" -i "clips/$clip.mp4" \
    -loop 1 -i "piezas/fondo-$n.png" -loop 1 -i piezas/bisel.png -loop 1 -i piezas/mascara.png \
    -filter_complex "[0:v]setpts=(PTS-STARTPTS)/$vel,fps=30,$RECORTE,scale=$W:$H,$extra,format=rgba[p];\
[3:v]format=gray,scale=$W:$H[m];[p][m]alphamerge[pantalla];\
[1:v][pantalla]overlay=$X:$Y:shortest=1[a];[a][2:v]overlay=0:0:shortest=1,format=yuv420p,\
fade=in:st=0:d=0.3,fade=out:st=$(calc "$final - 0.3"):d=0.3[v]" \
    -map "[v]" -t "$final" -r 30 -video_track_timescale 15360 -c:v libx264 -crf 18 -pix_fmt yuv420p "tmp/escena$n.mp4"
  echo "file 'escena$n.mp4'" >> "$lista"
  echo "escena $n: $final s"
done
tarjeta fin 3.5

# Se recodifica al unir: la portada y el cierre salen de imágenes con otra
# base de tiempo y con -c copy dejaban cuadros negros
"$F" -v error -y -f concat -safe 0 -i "$lista" -c:v libx264 -crf 18 -pix_fmt yuv420p -r 30 -movflags +faststart financially-video.mp4
echo "Listo: financially-video.mp4"

# Música: Sigma Slide (The Soundlings). Recortada al largo del video, con
# entrada de 1 s, salida de 2,5 s, volumen a -14 LUFS (YouTube) y limitador
MUSICA="Sigma Slide - The Soundlings.mp3"
if [ -f "$MUSICA" ]; then
  P="$LOCALAPPDATA/Microsoft/WinGet/Links/ffprobe.exe"
  D=$("$P" -v error -show_entries format=duration -of csv=p=0 financially-video.mp4)
  "$F" -v error -y -i financially-video.mp4 -i "$MUSICA" -map 0:v -map 1:a -c:v copy \
    -af "atrim=0:$D,asetpts=PTS-STARTPTS,afade=t=in:d=1,afade=t=out:st=$(calc "$D - 2.5"):d=2.5,loudnorm=I=-14:TP=-2:LRA=11,alimiter=limit=0.84:level=false" \
    -ar 48000 -c:a aac -b:a 192k -shortest -movflags +faststart financially-video-final.mp4
  echo "Con música: financially-video-final.mp4"
fi

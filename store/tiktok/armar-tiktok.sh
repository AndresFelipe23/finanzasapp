#!/usr/bin/env bash
# Arma los 3 videos de TikTok (1080 × 1920, 30 fps) con los clips del video de
# Play (../video/clips) y las piezas de fuentes/tiktok.html. Cada video sale
# con música (Sigma Slide) y sin música, para ponerle un sonido de TikTok.
# Uso: bash armar-tiktok.sh → tiktok-N.mp4 y tiktok-N-sin-musica.mp4
set -e
cd "$(dirname "$0")"
F="$LOCALAPPDATA/Microsoft/WinGet/Links/ffmpeg.exe"
P="$LOCALAPPDATA/Microsoft/WinGet/Links/ffprobe.exe"
E="/c/Program Files (x86)/Microsoft/Edge/Application/msedge.exe"
calc() { awk "BEGIN { printf \"%.2f\", $1 }"; }
CLIPS=../video/clips
MUSICA="../video/Sigma Slide - The Soundlings.mp3"
mkdir -p piezas tmp

# Hueco de la pantalla (igual que en tiktok.html)
X=250; Y=600; W=540; H=1151
RECORTE="crop=1220:2600:0:112"   # sin la barra de estado del teléfono

U=$(cygpath -m "$PWD/fuentes")
foto() { # nombre consulta ancho alto [fondo transparente]
  "$E" --headless=new --disable-gpu --hide-scrollbars --force-device-scale-factor=1 $5 \
    --virtual-time-budget=6000 --window-size=$3,$4 --screenshot="$(cygpath -w "$PWD/piezas/$1.png")" \
    "file:///$U/tiktok.html?$2" 2>/dev/null >/dev/null
}
for t in sola toques pov avisa ahorro creditos widget fin portada; do foto "$t" "t=$t" 1080 1920; done
foto bisel "bisel=1" 1080 1920 --default-background-color=00000000
foto mascara "mascara=1" $W $H
cp piezas/portada.png carrusel-0-portada.png

escena() { # salida texto clip inicio duración velocidad [filtro extra]
  local out=$1 txt=$2 clip=$3 ini=$4 dur=$5 vel=$6 extra=${7:-null}
  local final; final=$(calc "$dur / $vel")
  "$F" -v error -y -ss "$ini" -t "$dur" -i "$CLIPS/$clip.mp4" \
    -loop 1 -i "piezas/$txt.png" -loop 1 -i piezas/bisel.png -loop 1 -i piezas/mascara.png \
    -filter_complex "[0:v]setpts=(PTS-STARTPTS)/$vel,fps=30,$RECORTE,scale=$W:$H,$extra,format=rgba[p];\
[3:v]format=gray,scale=$W:$H[m];[p][m]alphamerge[pantalla];\
[1:v][pantalla]overlay=$X:$Y:shortest=1[a];[a][2:v]overlay=0:0:shortest=1,format=yuv420p[v]" \
    -map "[v]" -t "$final" -r 30 -video_track_timescale 15360 -c:v libx264 -crf 18 -pix_fmt yuv420p "tmp/$out.mp4"
  echo "file '$out.mp4'" >> "$LISTA"
}
cierre() { # salida
  "$F" -v error -y -loop 1 -t 2.2 -i piezas/fin.png -vf "fps=30,format=yuv420p,fade=in:st=0:d=0.25" \
    -video_track_timescale 15360 -c:v libx264 -crf 18 -pix_fmt yuv420p "tmp/$1.mp4"
  echo "file '$1.mp4'" >> "$LISTA"
}
unir() { # número
  "$F" -v error -y -f concat -safe 0 -i "$LISTA" -c:v libx264 -crf 18 -pix_fmt yuv420p -r 30 \
    -movflags +faststart "tiktok-$1-sin-musica.mp4"
  local d; d=$("$P" -v error -show_entries format=duration -of csv=p=0 "tiktok-$1-sin-musica.mp4")
  "$F" -v error -y -i "tiktok-$1-sin-musica.mp4" -i "$MUSICA" -map 0:v -map 1:a -c:v copy \
    -af "atrim=0:$d,asetpts=PTS-STARTPTS,afade=t=in:d=0.3,afade=t=out:st=$(calc "$d - 1.5"):d=1.5,loudnorm=I=-14:TP=-2:LRA=11,alimiter=limit=0.84:level=false" \
    -ar 48000 -c:a aac -b:a 192k -shortest -movflags +faststart "tiktok-$1.mp4"
  echo "tiktok-$1: $d s"
}

# Video 1 · "Esta app anota mis gastos sola"
LISTA=tmp/l1.txt; : > "$LISTA"
escena v1a sola   clip3 13 6  1
escena v1b toques clip2 4  16 2
cierre v1c; unir 1

# Video 2 · "POV: por fin sabes en qué se va tu plata"
LISTA=tmp/l2.txt; : > "$LISTA"
escena v2a pov   clip1 10 7 1
escena v2b avisa clip4 3  5 1
cierre v2c; unir 2

# Video 3 · "Así ahorro sin pensarlo"
LISTA=tmp/l3.txt; : > "$LISTA"
escena v3a ahorro   clip5 4  12 1.5
escena v3b creditos clip6 14 6  1
# Clip 7: tapa los íconos de otras apps del dock hasta que abre la hoja
escena v3c widget   clip7 4  4  1 "drawbox=x=0:y=990:w=$W:h=$((H-990)):color=0x0E1A3A:t=fill:enable='lt(t\,2.6)'"
cierre v3d; unir 3

rm -rf tmp

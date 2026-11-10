#!/bin/bash
cd /private/tmp/claude-501/ad3
S=($(cat starts.txt))
INP=""; FC=""; MIX=""
for i in 0 1 2 3 4 5 6 7; do
  n=$((i+1))
  INP="$INP -i $HOME/Downloads/$n.mp3"
  FC="$FC[$i:a]aresample=44100,aformat=channel_layouts=stereo,adelay=${S[$i]}|${S[$i]}[a$i];"
  MIX="$MIX[a$i]"
done
ffmpeg -loglevel error -y $INP -filter_complex "${FC}${MIX}amix=inputs=8:normalize=0,apad,atrim=0:31.5,loudnorm=I=-16:TP=-1.5:LRA=7[o]" -map "[o]" -c:a aac -b:a 160k audio.m4a || exit 1
ffmpeg -loglevel error -y -i video_mute.mp4 -i audio.m4a -c:v copy -c:a copy -shortest -movflags +faststart promo_dialogo.mp4 || exit 1
ffprobe -v error -show_entries stream=codec_name,pix_fmt,width,height,duration -of csv=p=0 promo_dialogo.mp4
ffmpeg -v error -i promo_dialogo.mp4 -f null - && echo DECODE_OK
ffmpeg -hide_banner -i audio.m4a -af volumedetect -f null - 2>&1 | grep -E "mean_volume|max_volume"

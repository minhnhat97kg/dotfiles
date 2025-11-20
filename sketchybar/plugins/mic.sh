#!/bin/bash
# Microphone plugin
INPUT_VOL=$(osascript -e 'input volume of (get volume settings)')
# macOS does not expose input mute directly via get volume settings; treat very low volume as muted
if [ "$INPUT_VOL" -le 5 ]; then
  ICON="󰍭"; LABEL="Muted"
else
  ICON="󰍬"; LABEL="${INPUT_VOL}%"
fi
sketchybar --set $NAME icon="$ICON" label="$LABEL"

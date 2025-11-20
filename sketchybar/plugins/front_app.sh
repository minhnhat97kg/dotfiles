#!/bin/bash
# Front app plugin
# Use provided $INFO (fast) or fallback if empty
APP="$INFO"
if [ -z "$APP" ]; then
  APP=$(lsappinfo front | awk -F '"' '/"name"/ {print $4; exit}')
fi
# Icon mapping (add more as needed)
case "$APP" in
  "Firefox"|"Google Chrome"|"Safari") ICON="󰖟" ;; # browser
  "Alacritty"|"iTerm2"|"Terminal") ICON="󰆍" ;; # terminal
  "Code"|"Visual Studio Code") ICON="󰨞" ;; # vscode
  "Finder") ICON="󰀶" ;;
  "Music"|"Spotify") ICON="󰝚" ;;
  *) ICON="󰘔" ;; # generic app icon
esac
[ -z "$NAME" ] && NAME=front_app
sketchybar --set $NAME icon="$ICON" label="$APP"
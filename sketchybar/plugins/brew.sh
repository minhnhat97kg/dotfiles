#!/bin/bash
# Brew updates plugin
if ! command -v brew >/dev/null 2>&1; then
  sketchybar --set $NAME icon=󰛦 label="N/A"
  exit 0
fi
COUNT=$(brew outdated --quiet | wc -l | tr -d ' ')
sketchybar --set $NAME label="$COUNT" tooltip="${COUNT} outdated formulae"

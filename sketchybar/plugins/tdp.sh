#!/bin/bash
# TDP plugin (CPU package power)
# Uses powermetrics (requires sudo; consider NOPASSWD for performance) fallback to ioreg
# Cache last value for fast updates
STATE_FILE="/tmp/sketchybar_tdp"
NOW=$(date +%s)
VALUE=""
# Try powermetrics (no deprecated sampler flag)
if command -v powermetrics >/dev/null 2>&1; then
  VALUE=$(sudo powermetrics -n1 2>/dev/null | awk -F':' '/CPU Power/ {gsub(/W| /, "", $2); print $2; exit}')
  if [ -z "$VALUE" ]; then
    VALUE=$(powermetrics -n1 2>/dev/null | awk -F':' '/CPU Power/ {gsub(/W| /, "", $2); print $2; exit}')
  fi
fi
# Fallback via pmset thermlog
if [ -z "$VALUE" ]; then
  VALUE=$(pmset -g thermlog 2>/dev/null | awk -F'=' '/CPU Power/ {gsub(/W| /, "", $2); print $2; exit}')
fi
# Remove incorrect adapter watt fallback (was always 60W)
# Final fallback to blank
[ -z "$VALUE" ] && VALUE="?"
LABEL="${VALUE}W"
sketchybar --set $NAME label="$LABEL" icon=󰈐 tooltip="CPU Package Power"

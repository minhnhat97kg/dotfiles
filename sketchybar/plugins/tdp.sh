#!/bin/bash
# TDP plugin (CPU package power)
# Uses powermetrics (requires sudo; consider NOPASSWD for performance) fallback to ioreg
# Cache last value for fast updates
STATE_FILE="/tmp/sketchybar_tdp"
NOW=$(date +%s)
VALUE=""
# Try powermetrics (fast sample)
if command -v powermetrics >/dev/null 2>&1; then
  # Use a short sample duration
  VALUE=$(sudo powermetrics --samplers smc -n1 2>/dev/null | awk -F':' '/CPU Power/ {gsub(/W| /, "", $2); print $2; exit}')
fi
# Fallback: estimate via ioreg (may be empty on some Macs)
if [ -z "$VALUE" ]; then
  VALUE=$(ioreg -r -n AppleSmartBattery 2>/dev/null | sed -n 's/.*"Watts"=\([0-9]*\).*/\1/p' | head -n1)
fi
# Final fallback to blank
[ -z "$VALUE" ] && VALUE="?"
LABEL="${VALUE}W"
sketchybar --set $NAME label="$LABEL" icon=󰈐 tooltip="CPU Package Power"

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
# Attempt powermetrics without password if sudo fails earlier
if [ -z "$VALUE" ]; then
  if sudo -n true 2>/dev/null; then
    VALUE=$(sudo powermetrics --samplers smc -n1 2>/dev/null | awk -F':' '/CPU Power/ {gsub(/W| /, "", $2); print $2; exit}')
  else
    VALUE=$(powermetrics --samplers smc -n1 2>/dev/null | awk -F':' '/CPU Power/ {gsub(/W| /, "", $2); print $2; exit}')
  fi
fi
# Remove incorrect adapter watt fallback (was always 60W)
# Final fallback to blank
[ -z "$VALUE" ] && VALUE="?"
LABEL="${VALUE}W"
sketchybar --set $NAME label="$LABEL" icon=󰈐 tooltip="CPU Package Power"

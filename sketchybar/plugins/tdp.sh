#!/bin/bash
# TDP plugin (CPU package power)
# Uses powermetrics (requires sudo; consider NOPASSWD for performance) fallback to ioreg
# Cache last value for fast updates
STATE_FILE="/tmp/sketchybar_tdp"
NOW=$(date +%s)
VALUE=""
# Power reading attempts
if command -v powermetrics >/dev/null 2>&1; then
  # Try sudo (silent) then non-sudo; handle different output formats
  RAW=$(sudo -n powermetrics -n1 2>/dev/null || powermetrics -n1 2>/dev/null)
  VALUE=$(echo "$RAW" | sed -n 's/.*CPU Power[:= ]\{1,3\}\([0-9.]*\) *W.*/\1/p' | head -n1)
fi
# Fallback: pmset thermlog last line containing CPU Power
if [ -z "$VALUE" ]; then
  VALUE=$(pmset -g thermlog 2>/dev/null | grep -i 'CPU Power' | tail -n1 | sed -n 's/.*CPU Power = \([0-9.]*\)W.*/\1/p')
fi
# Use last cached value if current retrieval failed
if [ -z "$VALUE" ] && [ -f "$STATE_FILE" ]; then
  VALUE=$(cat "$STATE_FILE")
fi
# Cache current value if valid numeric
if echo "$VALUE" | grep -Eq '^[0-9]+(\.[0-9]+)?$'; then
  echo "$VALUE" > "$STATE_FILE"
fi
# Remove incorrect adapter watt fallback (was always 60W)
# Final fallback to blank
[ -z "$VALUE" ] && VALUE="?"
LABEL="${VALUE}W"
sketchybar --set $NAME label="$LABEL" icon=󰈐 tooltip="CPU Package Power"

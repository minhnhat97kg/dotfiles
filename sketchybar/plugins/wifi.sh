#!/bin/bash
# WiFi plugin
INFO=$(/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport -I 2>/dev/null)
SSID=$(echo "$INFO" | awk -F': ' '/ SSID/ {print $2}')
RSSI=$(echo "$INFO" | awk -F': ' '/ agrCtlRSSI/ {print $2}')
ICON="󰤮" # default disconnected
if [ -z "$SSID" ]; then
  LABEL="Offline"
else
  # RSSI is negative; closer to 0 is better
  if [ "$RSSI" -ge -50 ]; then ICON="󰤨"; elif [ "$RSSI" -ge -60 ]; then ICON="󰤥"; elif [ "$RSSI" -ge -70 ]; then ICON="󰤢"; else ICON="󰤯"; fi
  LABEL="$SSID"
fi
sketchybar --set $NAME icon="$ICON" label="$LABEL"

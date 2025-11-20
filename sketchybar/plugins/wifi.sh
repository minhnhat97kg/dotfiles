#!/bin/bash
# WiFi plugin (robust detection)
HWPORT_WIFI=$(networksetup -listallhardwareports 2>/dev/null | awk '/Wi-Fi/{getline; print $2}')
[ -n "$HWPORT_WIFI" ] && INTERFACE="$HWPORT_WIFI" || INTERFACE="en0"
POWER_LINE=$(networksetup -getairportpower "$INTERFACE" 2>/dev/null)
[[ $POWER_LINE == *"On"* ]] && POWER=On || POWER=Off
# Attempt primary SSID methods
RAW=$(networksetup -getairportnetwork "$INTERFACE" 2>/dev/null)
if echo "$RAW" | grep -qi 'not associated'; then SSID=""; else SSID=$(echo "$RAW" | sed 's/^Current Wi-Fi Network: //'); fi
# Fallback: parse SSID from ioreg if still empty
IOREG=$(ioreg -r -n AirPort_BrcmNIC 2>/dev/null)
[ -z "$IOREG" ] && IOREG=$(ioreg -r -n AirPortPCI 2>/dev/null)
if [ -z "$SSID" ]; then
  # Fallback via awk split on quotes to avoid locale issues
  SSID=$(ioreg -l | awk -F'"' '/IO80211SSID/ {print $4; exit}')
fi
RSSI=$(echo "$IOREG" | awk -F'= ' '/CtlRSSI/ {print $2; exit}')
TXRATE=$(echo "$IOREG" | awk -F'= ' '/lastTxRate/ {print $2; exit}')
CHANNEL=$(echo "$IOREG" | awk -F'= ' '/Channel/ {print $2; exit}')
ICON="󰖪"; LABEL="Offline"
if [ "$POWER" = "On" ] && [ -n "$SSID" ]; then
  if [ -n "$RSSI" ]; then
    if [ "$RSSI" -ge -50 ]; then ICON="󰤨"; elif [ "$RSSI" -ge -60 ]; then ICON="󰤥"; elif [ "$RSSI" -ge -70 ]; then ICON="󰤢"; else ICON="󰤯"; fi
  else
    ICON="󰤥"
  fi
  if [ -n "$TXRATE" ]; then LABEL="${SSID} ${TXRATE}Mbps"; else LABEL="${SSID}"; fi
fi
sketchybar --set $NAME icon="$ICON" label="$LABEL" tooltip="If:${INTERFACE} Pwr:${POWER} Ch:${CHANNEL:-?} RSSI:${RSSI:-?} Tx:${TXRATE:-?}"


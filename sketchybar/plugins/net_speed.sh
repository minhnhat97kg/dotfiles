#!/bin/bash
# Network speed plugin (simple)
INTERFACE=$(route get default 2>/dev/null | awk '/interface: / {print $2}')
[ -z "$INTERFACE" ] && INTERFACE=en0
RX_BYTES=$(netstat -bI "$INTERFACE" | awk 'NR==2 {print $7}')
TX_BYTES=$(netstat -bI "$INTERFACE" | awk 'NR==2 {print $10}')
STATE_FILE="/tmp/sketchybar_${INTERFACE}_net"
NOW=$(date +%s)
if [ -f "$STATE_FILE" ]; then
  read LAST_TIME LAST_RX LAST_TX < "$STATE_FILE"
  DT=$((NOW-LAST_TIME))
  if [ $DT -gt 0 ]; then
    DRX=$((RX_BYTES-LAST_RX))
    DTX=$((TX_BYTES-LAST_TX))
    DOWN=$(echo "$DRX $DT" | awk '{printf "%.1f", ($1/1024)/$2}')
    UP=$(echo "$DTX $DT" | awk '{printf "%.1f", ($1/1024)/$2}')
    sketchybar --set $NAME label="D:${DOWN} U:${UP} KB/s"
  fi
fi
echo "$NOW $RX_BYTES $TX_BYTES" > "$STATE_FILE"

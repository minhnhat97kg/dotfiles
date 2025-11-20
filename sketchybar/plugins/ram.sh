#!/bin/bash
# RAM plugin
# Reliable memory usage using memory_pressure (fallback to vm_stat)
if command -v memory_pressure >/dev/null 2>&1; then
  USED=$(memory_pressure | awk '/System-wide memory free percentage:/ {print 100 - $5}')
  TOTAL_BYTES=$(sysctl -n hw.memsize)
  # Approximate used bytes from percentage
  USED_BYTES=$(echo "$USED $TOTAL_BYTES" | awk '{printf "%d", ($1/100)*$2}')
  USED_GB=$(echo "$USED_BYTES" | awk '{printf "%.1f", $1/1024/1024/1024}')
  TOTAL_GB=$(echo "$TOTAL_BYTES" | awk '{printf "%.0f", $1/1024/1024/1024}')
  sketchybar --set $NAME label="${USED_GB}G/${TOTAL_GB}G (${USED}%)"
  exit 0
fi
PAGE_SIZE=$(vm_stat | awk '/page size of/ {print $8}')
get_pages() { vm_stat | awk -v key="$1" '$0 ~ key {gsub(".","",$3); print $3}'; }
ACTIVE=$(get_pages "Pages active")
INACTIVE=$(get_pages "Pages inactive")
WIRED=$(get_pages "Pages wired down")
PURGEABLE=$(get_pages "Pages purgeable")
TOTAL_BYTES=$(sysctl -n hw.memsize)
USED_PAGES=$((ACTIVE+INACTIVE+WIRED-PURGEABLE))
USED_BYTES=$((USED_PAGES*PAGE_SIZE))
USED_GB=$(echo "$USED_BYTES" | awk '{printf "%.1f", $1/1024/1024/1024}')
TOTAL_GB=$(echo "$TOTAL_BYTES" | awk '{printf "%.0f", $1/1024/1024/1024}')
PERCENT=$(echo "$USED_BYTES $TOTAL_BYTES" | awk '{printf "%.0f", ($1/$2)*100}')
sketchybar --set $NAME label="${USED_GB}G/${TOTAL_GB}G (${PERCENT}%)"
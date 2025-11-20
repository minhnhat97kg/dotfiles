#!/bin/bash
# RAM plugin
# Calculates RAM usage and sets label
PAGE_SIZE=$(vm_stat | awk '/page size of/ {print $8}')
get_pages() { vm_stat | awk -v key="$1" '$0 ~ key {gsub(".","",$3); print $3}'; }
FREE=$(get_pages "Pages free")
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
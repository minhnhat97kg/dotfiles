#!/usr/bin/env bash
# Show monitor info (connector, name, position, size, scale, mode) for every
# active output in one notification, to identify which physical monitor is
# which connector (Mod+Shift+M). Kept mawk-compatible (Ubuntu's default awk).
set -euo pipefail

# One tab-separated record per output: connector, name, pos, size, scale, mode.
records=$(niri msg outputs | awk '
  function flush() {
    if (conn != "")
      printf "%s\t%s\t%s\t%s\t%s\t%s\n", conn, name, pos, size, scale, mode
  }
  /^Output / {
    flush()
    line = $0
    sub(/^Output "/, "", line)          # NAME" (CONNECTOR)
    q = index(line, "\" (")
    name = substr(line, 1, q - 1)
    rest = substr(line, q + 3)          # CONNECTOR)
    sub(/\)[ \t]*$/, "", rest)
    conn = rest
    mode = ""; pos = ""; size = ""; scale = ""
    next
  }
  /Current mode:/     { sub(/^[ \t]*Current mode: /, "");     mode  = $0 }
  /Logical position:/ { sub(/^[ \t]*Logical position: /, ""); pos   = $0 }
  /Logical size:/     { sub(/^[ \t]*Logical size: /, "");     size  = $0 }
  /Scale:/            { sub(/^[ \t]*Scale: /, "");            scale = $0 }
  END { flush() }
')

if [ -z "$records" ]; then
  notify-send -a "niri" -t 5000 "Monitors" "No outputs found"
  exit 0
fi

body=""
while IFS=$'\t' read -r conn name pos size scale mode; do
  # An output that is off has no logical position.
  [ -z "$conn" ] || [ -z "$pos" ] && continue
  body+=$(printf '<b>%s</b>  %s\npos %s  ·  size %s  ·  scale %s  ·  %s' \
                 "$conn" "$name" "$pos" "$size" "$scale" "$mode")$'\n\n'
done <<< "$records"

if [ -z "$body" ]; then
  notify-send -a "niri" -t 5000 "Monitors" "No active outputs to label"
else
  notify-send -a "niri" -t 10000 "Monitors" "${body%$'\n\n'}"
fi

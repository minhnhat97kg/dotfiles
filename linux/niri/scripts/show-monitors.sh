#!/usr/bin/env bash
# Show monitor info on EVERY connected display: one notification per output,
# each pinned to its own screen so you can identify which physical monitor is
# which connector.
#
# HOW THE PINNING WORKS (and why it changed): mako could route a single
# notification to a specific output with `[category=mon-<conn>] output=<conn>`
# criteria, so this script just tagged each card and mako placed it. swaync has
# no per-notification routing — only ONE global preferred output — so instead we
# walk the outputs, repointing that global setting before each card:
#
#   swaync-client --change-noti-monitor <conn>  →  notify-send  →  next
#
# and then restore it. `swaync-client -R` is the documented reset ("resets on
# config reload" per swaync-client --help), and since config.json leaves
# notification-window-preferred-output unset, reloading returns swaync to
# following the focused output.
#
# The cost of doing it this way: the preferred output is global for the ~1s this
# loop runs, so a notification arriving from some other app mid-loop can land on
# the wrong screen. That is an acceptable trade for a manually-triggered
# diagnostic (Mod+Shift+M) and it is why the loop is kept as short as possible.
#
# Kept mawk-compatible (Ubuntu's default awk), so no gawk-only features.
set -euo pipefail

# Restore the configured monitor no matter how we leave — including Ctrl+C or a
# failed notify-send partway through the loop.
restore() { swaync-client -R >/dev/null 2>&1 || true; }
trap restore EXIT

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

shown=0
while IFS=$'\t' read -r conn name pos size scale mode; do
  [ -z "$conn" ] && continue

  # An output that is off has no logical position, so there is no screen to draw
  # on — naming it would just dump every card onto whatever is still lit.
  if [ -z "$pos" ]; then
    continue
  fi

  # If swaync cannot find the connector, skip rather than dropping this card
  # onto the previous monitor and claiming it is a different display.
  if ! swaync-client --change-noti-monitor "$conn" >/dev/null 2>&1; then
    continue
  fi

  body=$(printf '<b>%s</b>\n%s\npos %s  ·  size %s  ·  scale %s\n%s' \
                "$conn" "$name" "$pos" "$size" "$scale" "$mode")
  notify-send -a "niri" -t 8000 "This display: $conn" "$body"
  shown=$((shown + 1))

  # notify-send returns as soon as the DBus call is made; swaync builds the
  # popup asynchronously. Without this pause the next --change-noti-monitor can
  # win the race and the card appears on the following screen instead.
  sleep 0.3
done <<< "$records"

if [ "$shown" -eq 0 ]; then
  notify-send -a "niri" -t 5000 "Monitors" "No active outputs to label"
fi

#!/usr/bin/env bash
# Notification readout, fed by swaync's push feed rather than a poll.
#
# `swaync-client -swb` emits one JSON line per change (count, dnd, panel open),
# so this module has NO interval — it is the only genuinely event-driven module
# on the bar. Everything else here wakes on a timer.
#
#   [·]   idle, nothing waiting        [-]   do-not-disturb, nothing waiting
#   [3]   3 notifications waiting      [-3]  do-not-disturb, 3 waiting
#
# swaync's own text is the bare count, which would render "[0]" at rest — the
# bar's resting state is meant to be quiet, hence "·". Framing is drawn with
# characters to match [*] / [≡] / [10:44] / [X]; colour never carries the state
# (see #custom-notification in style.css).
#
# The upstream waybar example pipes -swb straight into waybar. Going through jq
# costs nothing here because it runs per event, not per tick, and it keeps the
# bracket convention in one place instead of spreading it across format strings.
set -euo pipefail

# .class arrives as either a string ("notification") or an array
# (["notification", "cc-open"]) — passed through untouched so waybar gets both.
exec swaync-client -swb | jq --unbuffered -c '
  (.alt | startswith("dnd")) as $dnd |
  ((.text | tonumber) > 0) as $pending |
  {
    # "·" is the idle placeholder, but a lone "-" already reads as "muted and
    # empty" — "[-·]" was just noise.
    text: ("[" + (if $dnd then "-" else "" end)
               + (if $pending then .text elif $dnd then "" else "·" end) + "]"),
    alt: .alt,
    class: .class,
    tooltip: ((if .tooltip == "" then "No notifications" else .tooltip end)
              + (if $dnd then "\nDo not disturb is on" else "" end)
              + "\n\nClick: open center   Right-click: toggle DND")
  }
'

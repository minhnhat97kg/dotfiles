#!/usr/bin/env bash
# Shows the active window's title for the output this waybar instance lives on.
set -euo pipefail

output="${1:-${WAYBAR_OUTPUT_NAME:-}}"

ws_json="$(niri msg -j workspaces)"
win_json="$(niri msg -j windows)"

jq -c -n --arg output "$output" --argjson ws "$ws_json" --argjson wins "$win_json" '
  ($ws | map(select(($output == "" or .output == $output) and .is_active == true)) | first) as $w |
  ($w.active_window_id) as $wid |
  ($wins | map(select(.id == $wid)) | first) as $win |
  if $win == null then
    { text: "", tooltip: "" }
  else
    ($win.title // $win.app_id // "") as $t |
    {
      text: (if ($t | length) > 60 then ($t[0:60] + "…") else $t end),
      tooltip: $t,
      class: (if $win.is_focused then "niri-window focused" else "niri-window" end)
    }
  end
'

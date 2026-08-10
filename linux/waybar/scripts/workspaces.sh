#!/usr/bin/env bash
# Renders niri workspaces for the output this waybar instance lives on.
set -euo pipefail

output="${1:-${WAYBAR_OUTPUT_NAME:-}}"

niri msg -j workspaces | jq -c --arg output "$output" '
  [ .[] | select($output == "" or .output == $output) ] | sort_by(.idx) |
  {
    text: (map(
      if .is_focused then "<span foreground=\"#89b4fa\">\(.idx)</span>"
      elif .is_active then "<span foreground=\"#cdd6f4\">\(.idx)</span>"
      else "<span foreground=\"#585b70\">\(.idx)</span>" end
    ) | join(" ")),
    tooltip: "Scroll to switch workspace",
    class: "niri-workspaces"
  }
'

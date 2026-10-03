#!/usr/bin/env bash
# Renders niri workspaces for the output this waybar instance lives on.
#
# Laid out in a row. The focused index gets an accent-blue pill, padded with a
# space either side so it reads as a deliberate solid block rather than a
# rendering artefact (Pango cannot pad a span, so the padding has to be actual
# spaces).
set -euo pipefail

output="${1:-${WAYBAR_OUTPUT_NAME:-}}"

niri msg -j workspaces | jq -c --arg output "$output" '
  [ .[] | select($output == "" or .output == $output) ] | sort_by(.idx) |
  {
    text: (map(
      if .is_focused then "<span background=\"#0a84ff\" foreground=\"#ffffff\"> \(.idx) </span>"
      elif .is_active then "<span foreground=\"#f5f5f7\">\(.idx)</span>"
      else "<span foreground=\"#636366\">\(.idx)</span>" end
    ) | join(" ")),
    tooltip: "Scroll to switch workspace",
    class: "niri-workspaces"
  }
'

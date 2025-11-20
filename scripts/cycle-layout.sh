#!/usr/bin/env bash
# Cycle Yabai space layouts (forward/backward/current)
# Supported base layouts: bsp, stack, float
# Usage: cycle-layout.sh forward|backward|current
set -euo pipefail
layouts=(bsp stack float)
current_layout() { yabai -m query --spaces --space | jq -r ".type"; }
notify() { osascript -e "display notification \"$1\" with title \"Yabai\"" >/dev/null; }
case "${1:-}" in
  forward)
    cur=$(current_layout)
    for i in "${!layouts[@]}"; do
      if [[ "${layouts[$i]}" == "$cur" ]]; then
        next_index=$(( (i+1) % ${#layouts[@]} ))
        next=${layouts[$next_index]}
        yabai -m space --layout "$next"
        notify "Layout: $next"
        exit 0
      fi
    done
    ;;
  backward)
    cur=$(current_layout)
    for i in "${!layouts[@]}"; do
      if [[ "${layouts[$i]}" == "$cur" ]]; then
        prev_index=$(( (i-1 + ${#layouts[@]}) % ${#layouts[@]} ))
        prev=${layouts[$prev_index]}
        yabai -m space --layout "$prev"
        notify "Layout: $prev"
        exit 0
      fi
    done
    ;;
  current)
    cur=$(current_layout)
    notify "Layout: $cur"
    ;;
  *)
    echo "Usage: $0 {forward|backward|current}" >&2
    exit 1
    ;;
 esac

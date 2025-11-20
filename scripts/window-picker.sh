#!/usr/bin/env bash
set -euo pipefail

# Build list: id|app|title for non-empty titles
windows=$(yabai -m query --windows | jq -r '.[] | select(.title != "") | (.id|tostring) +  "|" + (.space|tostring) + "|" + .app + "|" + .title')
if [ -z "${windows}" ]; then
  osascript -e 'display notification "No windows" with title "Yabai"'
  exit 0
fi

sel=$(printf '%s\n' "$windows" | fzf --prompt 'Window > ' --reverse --height 100% | cut -d'|' -f1)
if [ -n "${sel:-}" ]; then
  if ! yabai -m window --focus "$sel"; then
    osascript -e "display notification \"Failed to focus $sel\" with title \"Yabai\""
  fi
else
  osascript -e 'display notification "No selection" with title "Yabai"'
fi

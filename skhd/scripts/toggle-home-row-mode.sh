#!/usr/bin/env bash
CONFIG="$HOME/Documents/projects/dotfiles/skhd/skhdrc"
STATE_FILE="$HOME/Documents/projects/dotfiles/skhd/.home_row_enabled"
# Toggle Home Row Mode by commenting/uncommenting bindings within marker block
if [ -f "$STATE_FILE" ]; then
  # Disable mode: comment active binding lines inside block
  sed -i '' '/# BEGIN HOME_ROW_BINDINGS/,/# END HOME_ROW_BINDINGS/ s/^[^#]/# &/' "$CONFIG"
  rm -f "$STATE_FILE"
  osascript -e 'display notification "Home Row mode OFF" with title "skhd"' >/dev/null 2>&1 || true
else
  # Enable mode: uncomment lines that look like bindings
  sed -i '' '/# BEGIN HOME_ROW_BINDINGS/,/# END HOME_ROW_BINDINGS/ s/^# \(.*:.*\)$/\1/' "$CONFIG"
  touch "$STATE_FILE"
  osascript -e 'display notification "Home Row mode ON" with title "skhd"' >/dev/null 2>&1 || true
fi
skhd -r

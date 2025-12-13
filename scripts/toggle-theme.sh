#!/usr/bin/env bash
set -euo pipefail

# Gruvbox color definitions
DARK_BG="#1d2021"
DARK_FG="#ebdbb2"
DARK_SELECTION_BG="#504945"
DARK_CURSOR_TEXT="#1d2021"

LIGHT_BG="#f9f5d7"
LIGHT_FG="#282828"
LIGHT_SELECTION_BG="#d5c4a1"
LIGHT_CURSOR_TEXT="#f9f5d7"

# Config file paths
KITTY_CONF="$HOME/Documents/projects/dotfiles/kitty/kitty.conf"
NVIM_INIT="$HOME/Documents/projects/dotfiles/nvim/init.lua"
STATE_FILE="$HOME/.config/dotfiles/.theme_state"

# Detect current theme
if [ -f "$STATE_FILE" ]; then
  CURRENT_THEME=$(cat "$STATE_FILE")
else
  # Default to dark if no state file
  CURRENT_THEME="dark"
fi

# Toggle theme
if [ "$CURRENT_THEME" = "dark" ]; then
  NEW_THEME="light"
  NEW_BG="$LIGHT_BG"
  NEW_FG="$LIGHT_FG"
  NEW_SELECTION_BG="$LIGHT_SELECTION_BG"
  NEW_CURSOR_TEXT="$LIGHT_CURSOR_TEXT"
  THEME_NAME="Light Hard Contrast"
else
  NEW_THEME="dark"
  NEW_BG="$DARK_BG"
  NEW_FG="$DARK_FG"
  NEW_SELECTION_BG="$DARK_SELECTION_BG"
  NEW_CURSOR_TEXT="$DARK_CURSOR_TEXT"
  THEME_NAME="Dark Hard Contrast"
fi

echo "Switching to Gruvbox $THEME_NAME..."

# Update Kitty config
sed -i '' "s/^# Gruvbox .* color theme/# Gruvbox $THEME_NAME color theme/" "$KITTY_CONF"
sed -i '' "s/^foreground #.*/foreground $NEW_FG/" "$KITTY_CONF"
sed -i '' "s/^background #.*/background $NEW_BG/" "$KITTY_CONF"
sed -i '' "s/^cursor #.*/cursor $NEW_FG/" "$KITTY_CONF"
sed -i '' "s/^cursor_text_color #.*/cursor_text_color $NEW_CURSOR_TEXT/" "$KITTY_CONF"
sed -i '' "s/^selection_foreground #.*/selection_foreground $NEW_FG/" "$KITTY_CONF"
sed -i '' "s/^selection_background #.*/selection_background $NEW_SELECTION_BG/" "$KITTY_CONF"

# Update Neovim config
sed -i '' "s/vim.o.background = \".*\"/vim.o.background = \"$NEW_THEME\"/" "$NVIM_INIT"

# Save new theme state
mkdir -p "$(dirname "$STATE_FILE")"
echo "$NEW_THEME" > "$STATE_FILE"

# Reload Kitty
if command -v kitty &> /dev/null; then
  kitty @ load-config 2>/dev/null || true
fi

# Notify user about Neovim
echo "✓ Theme switched to $NEW_THEME mode"
echo "✓ Kitty config reloaded"
echo "ℹ  Restart Neovim or run :source ~/.config/nvim/init.lua to apply changes"

# Send notification (macOS)
if command -v osascript &> /dev/null; then
  osascript -e "display notification \"Switched to $THEME_NAME\" with title \"Theme Toggle\""
fi

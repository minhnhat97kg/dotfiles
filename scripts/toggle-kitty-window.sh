#!/bin/bash
# Toggle a named kitty floating window
# Usage: toggle-kitty-window.sh <window-title> [command]
# Requires yabai, jq, and kitty with the remote control enabled.

set -euo pipefail

WINDOW_TITLE="$1"
COMMAND="${2:-}"
# Default geometry for a new window
# Note: Don't use --toggle float, just set geometry (float is handled by yabai rules)
GEOMETRY_OPTS="--resize abs:900:600 --move abs:520:140"

# --- Launch Function ---
launch_kitty() {
    local title="$1" cmd="$2"

    # Decide between remote control or direct launch
    if kitty @ ls >/dev/null 2>&1; then
        # If remote control is available, launch in the background (&)
        # This uses the running kitty instance to create a new window
        if [[ -n "$cmd" ]]; then
            kitty @ launch --type os-window --title "$title" --cwd=current zsh -c "$cmd; exec zsh" &
        else
            kitty @ launch --type os-window --title "$title" --cwd=current &
        fi
    else
        # Direct launch. This is the critical block for initial launch.
        if [[ -n "$cmd" ]]; then
            # Launch kitty with command using zsh, then keep shell open
            kitty --title "$title" zsh -c "$cmd; exec zsh" &
        else
            kitty --title "$title" &
        fi
    fi
}

# --- Main Logic ---

# 1. Query for existing window ID
wid=$(yabai -m query --windows | jq -r ".[] | select(.app==\"kitty\" and .title==\"$WINDOW_TITLE\") | .id" | head -n1)
focused_wid=$(yabai -m query --windows --window | jq -r '.id' 2>/dev/null || echo "")

if [ -n "$wid" ]; then
    # Window exists
    if [ "$wid" = "$focused_wid" ]; then
        # Focused: close the window; avoid killing processes so clipse stays alive
        yabai -m window "$wid" --close 2>/dev/null || true
        sleep 0.2
    else
        # Exists but not focused: focus it
        yabai -m window --focus "$wid"
    fi
else
    # Window doesn't exist: clean up any orphans and create new
    pkill -f "kitty.*--title $WINDOW_TITLE" 2>/dev/null || true
    sleep 0.1
    
    # 2. Prepare Command
    launch_cmd=""
    if [ -n "$COMMAND" ]; then
        launch_cmd="$COMMAND"
    fi

    # 3. Launch Kitty
    # The script execution will pause here until the kitty window is registered.
    launch_kitty "$WINDOW_TITLE" "$launch_cmd"
    
    # 4. Wait for window and configure
    # A short sleep to ensure the window is fully available to yabai.
    sleep 0.8
    
    # Get the ID of the new window by title (avoid 'next' to prevent yabai errors)
    wid=$(yabai -m query --windows 2>/dev/null | jq -r ".[] | select(.app==\"kitty\" and .title==\"$WINDOW_TITLE\") | .id" | head -n1)

    if [ -n "$wid" ]; then
        # Apply floating geometry and focus
        yabai -m window "$wid" $GEOMETRY_OPTS 2>/dev/null || true
        yabai -m window --focus "$wid"
    fi
fi

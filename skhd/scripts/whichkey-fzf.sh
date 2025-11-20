#!/usr/bin/env bash

# ====================================================================
# WhichKey-style FZF Keybinding Picker for SKHD/Yabai
# ====================================================================

SKHDRC="${HOME}/Documents/projects/dotfiles/skhd/skhdrc"

# Parse skhdrc and create a searchable list
bindings=$(awk '
BEGIN {
    section = ""
    prev_comment = ""
}

# Capture section headers
/^# ====/ { next }
/^# [A-Z]/ {
    gsub(/^# /, "", $0)
    section = $0
    next
}

# Capture standalone comments (potential descriptions)
/^# [^=]/ && !/^# -/ {
    prev_comment = $0
    gsub(/^# /, "", prev_comment)
    next
}

# Capture keybindings
/^[a-z].*:.*/ {
    # Skip the show-keybindings binding to avoid recursion
    if ($0 ~ /show-keybindings\.sh/) next
    if ($0 ~ /whichkey-fzf\.sh/) next

    # Get the keybinding and command
    split($0, parts, " : ")
    key = parts[1]
    command = parts[2]

    # Clean up key format for display
    display_key = key
    gsub(/ctrl \+ alt \+ shift/, "⌃⌥⇧", display_key)
    gsub(/alt \+ shift/, "⌥⇧", display_key)
    gsub(/ctrl \+ alt/, "⌃⌥", display_key)
    gsub(/alt/, "⌥", display_key)
    gsub(/ctrl/, "⌃", display_key)
    gsub(/shift/, "⇧", display_key)
    gsub(/cmd/, "⌘", display_key)
    gsub(/ \+ /, "", display_key)
    gsub(/ - /, " ", display_key)
    gsub(/return/, "↩", display_key)
    gsub(/space/, "␣", display_key)
    gsub(/0x2B/, ",", display_key)
    gsub(/0x2C/, "/", display_key)
    gsub(/0x2F/, ".", display_key)

    # Get description from inline comment or previous comment
    desc = ""
    if (match($0, /# .*/)) {
        desc = substr($0, RSTART+2)
        gsub(/\(mod[12] \+ .*\)/, "", desc)
        gsub(/^[ \t]+|[ \t]+$/, "", desc)
    } else if (prev_comment != "") {
        desc = prev_comment
    }

    # Default description if none found
    if (desc == "") {
        if (command ~ /yabai.*--layout/) desc = "Change layout"
        else if (command ~ /yabai.*--focus/) desc = "Focus window/space"
        else if (command ~ /yabai.*--swap/) desc = "Swap windows"
        else if (command ~ /yabai.*--space/) desc = "Move to space"
        else if (command ~ /yabai.*--display/) desc = "Move to display"
        else if (command ~ /yabai.*--ratio/) desc = "Resize window"
        else if (command ~ /yabai.*--balance/) desc = "Balance windows"
        else if (command ~ /yabai.*--toggle/) desc = "Toggle option"
        else if (command ~ /yabai.*--create/) desc = "Create space"
        else if (command ~ /yabai.*--destroy/) desc = "Destroy space"
        else desc = "Execute command"
    }

    # Format: [SECTION] description | key | command
    printf "[%s] %s|%s|%s\n", section, desc, display_key, command

    prev_comment = ""
}

# Clear previous comment for other lines
!/^# / && !/^[a-z].*:/ { prev_comment = "" }
' "$SKHDRC")

# Use fzf to select a binding
selected=$(echo "$bindings" | fzf \
    --ansi \
    --height=100% \
    --border=rounded \
    --prompt="⌨️  Keybindings > " \
    --header="Select a keybinding to execute (ESC to cancel)" \
    --preview='echo {}' \
    --preview-window=hidden \
    --delimiter="|" \
    --with-nth=1,2 \
    --bind='ctrl-/:toggle-preview' \
    --color='fg:#cdd6f4,bg:#1e1e2e,hl:#f38ba8' \
    --color='fg+:#cdd6f4,bg+:#313244,hl+:#f38ba8' \
    --color='info:#cba6f7,prompt:#cba6f7,pointer:#f5e0dc' \
    --color='marker:#f5e0dc,spinner:#f5e0dc,header:#f38ba8')

# Execute the selected command
if [ -n "$selected" ]; then
    command=$(echo "$selected" | cut -d'|' -f3)
    # Execute the command
    eval "$command"
fi

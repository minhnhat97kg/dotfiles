#!/usr/bin/env bash

# ====================================================================
# Show All Keybindings in macOS Dialog
# ====================================================================

SKHDRC="${HOME}/Documents/projects/dotfiles/skhd/skhdrc"
TMUXCONF="${HOME}/.config/tmux/tmux.conf"

# Parse skhdrc and format keybindings
skhd_bindings=$(awk '
BEGIN { section = "" }

# Capture section headers
/^# ====/ { next }
/^# [A-Z]/ {
    gsub(/^# /, "", $0)
    section = $0
    next
}

# Capture keybindings with comments
/^[a-z].*:.*/ {
    # Get the keybinding part
    split($0, parts, " : ")
    key = parts[1]

    # Clean up key format
    gsub(/ctrl \+ alt \+ shift/, "⌃⌥⇧", key)
    gsub(/alt \+ shift/, "⌥⇧", key)
    gsub(/ctrl \+ alt/, "⌃⌥", key)
    gsub(/alt/, "⌥", key)
    gsub(/ctrl/, "⌃", key)
    gsub(/shift/, "⇧", key)
    gsub(/cmd/, "⌘", key)
    gsub(/ \+ /, "", key)
    gsub(/ - /, " ", key)
    gsub(/return/, "↩", key)
    gsub(/space/, "␣", key)
    gsub(/left/, "←", key)
    gsub(/right/, "→", key)
    gsub(/up/, "↑", key)
    gsub(/down/, "↓", key)

    # Get description from comment on same line or previous line
    desc = ""
    if (match($0, /# .*/)) {
        desc = substr($0, RSTART+2)
        gsub(/\(mod[12] \+ .*\)/, "", desc)
        gsub(/^[ \t]+|[ \t]+$/, "", desc)
    }

    if (desc != "" && section != prev_section) {
        printf "\n━━ %s ━━\n", section
        prev_section = section
    }

    if (desc != "") {
        printf "%-20s %s\n", key, desc
    }
}
' "$SKHDRC")

# Parse tmux config for custom bindings
tmux_custom=$(awk '
/^bind/ {
    line = $0
    key = ""

    # Extract key based on bind type
    if (line ~ /bind-key -T copy-mode-vi/) {
        n = split(line, parts, " ")
        key = "prefix + " parts[4] " (copy)"
    } else if (line ~ /bind -n/) {
        n = split(line, parts, " ")
        key = parts[3]
    } else if (line ~ /^bind /) {
        n = split(line, parts, " ")
        key = "prefix + " parts[2]
    } else {
        next
    }

    # Get description from command
    desc = ""
    if (line ~ /new-window/) desc = "New window"
    else if (line ~ /split-window -h/) desc = "Split horizontal"
    else if (line ~ /split-window -v/) desc = "Split vertical"
    else if (line ~ /select-pane -L/) desc = "Select pane left"
    else if (line ~ /select-pane -D/) desc = "Select pane down"
    else if (line ~ /select-pane -U/) desc = "Select pane up"
    else if (line ~ /select-pane -R/) desc = "Select pane right"
    else if (line ~ /begin-selection/) desc = "Begin selection"

    # Format key
    gsub(/C-/, "⌃", key)

    if (desc != "" && key != "") {
        printf "%-20s %s\n", key, desc
    }
}
' "$TMUXCONF")

# Common tmux defaults
tmux_defaults="
━━ TMUX DEFAULTS ━━
prefix + c          New window
prefix + n          Next window
prefix + p          Previous window
prefix + 0-9        Select window
prefix + w          List windows
prefix + &          Kill window
prefix + %          Split vertical
prefix + \"          Split horizontal
prefix + o          Next pane
prefix + ;          Last pane
prefix + x          Kill pane
prefix + z          Toggle zoom
prefix + [          Copy mode
prefix + ]          Paste
prefix + d          Detach
prefix + ?          List keys
prefix + :          Command prompt"

# Combine all keybindings
all_bindings="━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        YABAI/SKHD
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
$skhd_bindings

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        TMUX (prefix = ⌃b)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

━━ CUSTOM BINDINGS ━━
$tmux_custom
$tmux_defaults"

# Escape special characters for AppleScript
escaped_bindings=$(echo "$all_bindings" | sed 's/\\/\\\\/g; s/"/\\"/g')

# Display in macOS dialog
osascript <<EOF
set theText to "$escaped_bindings"
display dialog theText with title "Keybindings Cheatsheet" buttons {"OK"} default button "OK"
EOF

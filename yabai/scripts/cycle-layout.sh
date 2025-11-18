#!/usr/bin/env bash

# ====================================================================
# Yabai Extended Layout Cycling Script
# ====================================================================
# Cycles through: bsp → vertical → horizontal → master-stack → stack → float
#
# Usage:
#   cycle-layout.sh forward   - Cycle to next layout
#   cycle-layout.sh backward  - Cycle to previous layout
#   cycle-layout.sh current   - Show current layout
#   cycle-layout.sh set NAME  - Set specific layout
# ====================================================================

LAYOUT_FILE="/tmp/yabai-layout-$(yabai -m query --spaces --space | jq -r '.index')"
LAYOUTS=("bsp" "vertical" "horizontal" "master-stack" "stack" "float")

# Get current layout from file or detect from yabai
get_current_layout() {
    if [[ -f "$LAYOUT_FILE" ]]; then
        cat "$LAYOUT_FILE"
    else
        # Fallback to yabai's native type
        yabai -m query --spaces --space | jq -r '.type'
    fi
}

# Get layout index
get_layout_index() {
    local layout="$1"
    for i in "${!LAYOUTS[@]}"; do
        if [[ "${LAYOUTS[$i]}" == "$layout" ]]; then
            echo "$i"
            return
        fi
    done
    echo "0"  # Default to bsp
}

# Apply layout configuration
apply_layout() {
    local layout="$1"

    case "$layout" in
        "bsp")
            yabai -m space --layout bsp
            yabai -m config split_type auto
            yabai -m config split_ratio 0.50
            ;;
        "vertical")
            yabai -m space --layout bsp
            yabai -m config split_type horizontal
            yabai -m config split_ratio 0.50
            yabai -m space --balance
            ;;
        "horizontal")
            yabai -m space --layout bsp
            yabai -m config split_type vertical
            yabai -m config split_ratio 0.50
            yabai -m space --balance
            ;;
        "master-stack")
            yabai -m space --layout bsp
            yabai -m config split_type auto
            yabai -m config split_ratio 0.65
            ;;
        "stack")
            yabai -m space --layout stack
            yabai -m config split_type auto
            yabai -m config split_ratio 0.50
            ;;
        "float")
            yabai -m space --layout float
            yabai -m config split_type auto
            yabai -m config split_ratio 0.50
            ;;
    esac

    # Save current layout
    echo "$layout" > "$LAYOUT_FILE"

    # Show notification
    osascript -e "display notification \"$layout\" with title \"Layout\""
}

# Main logic
case "$1" in
    "forward")
        current=$(get_current_layout)
        index=$(get_layout_index "$current")
        next_index=$(( (index + 1) % ${#LAYOUTS[@]} ))
        apply_layout "${LAYOUTS[$next_index]}"
        ;;
    "backward")
        current=$(get_current_layout)
        index=$(get_layout_index "$current")
        prev_index=$(( (index - 1 + ${#LAYOUTS[@]}) % ${#LAYOUTS[@]} ))
        apply_layout "${LAYOUTS[$prev_index]}"
        ;;
    "current")
        current=$(get_current_layout)
        osascript -e "display notification \"$current\" with title \"Current Layout\""
        echo "$current"
        ;;
    "set")
        if [[ -n "$2" ]]; then
            apply_layout "$2"
        else
            echo "Usage: $0 set <layout_name>"
            echo "Available: ${LAYOUTS[*]}"
            exit 1
        fi
        ;;
    *)
        echo "Usage: $0 {forward|backward|current|set <layout>}"
        echo "Available layouts: ${LAYOUTS[*]}"
        exit 1
        ;;
esac

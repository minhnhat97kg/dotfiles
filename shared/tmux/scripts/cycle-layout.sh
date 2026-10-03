#!/usr/bin/env bash
# The tmux layouts, in cycle order. Single source of truth for both bindings:
#   prefix+Space  cycle-layout.sh <window>          → next layout after the current one
#   prefix+L      cycle-layout.sh <window> <mode>   → that layout (menu in tmux.conf)
# <window> is the binding's #{window_id}: a bare `tmux` call from run-shell
# would act on whichever window tmux considers current, not necessarily this one.
# The chosen name is kept in @layout_name, which the status bar shows.
set -euo pipefail

# mode|tmux layout|name
LAYOUTS=(
    "stack|main-horizontal|Main top"
    "stack-bottom|main-horizontal-mirrored|Main bottom"
    "main-left|main-vertical|Main left"
    "main-right|main-vertical-mirrored|Main right"
    "list|even-vertical|Rows"
    "columns|even-horizontal|Columns"
    "grid|tiled|Grid"
)

win=$1
want=${2:-}
if [ -z "$want" ]; then
    curr=$(tmux show-window-option -t "$win" -v @layout_mode 2>/dev/null || true)
    want=${LAYOUTS[0]%%|*}
    for i in "${!LAYOUTS[@]}"; do
        if [ "${LAYOUTS[i]%%|*}" = "$curr" ]; then
            next=${LAYOUTS[(i + 1) % ${#LAYOUTS[@]}]}
            want=${next%%|*}
        fi
    done
fi

for entry in "${LAYOUTS[@]}"; do
    IFS='|' read -r mode layout name <<<"$entry"
    [ "$mode" = "$want" ] || continue
    tmux select-layout -t "$win" "$layout"
    tmux set-window-option -t "$win" @layout_mode "$mode"
    tmux set-window-option -t "$win" @layout_name "$name"
    tmux display-message -d 1500 "󰕰 Layout: $name"
    exit 0
done
tmux display-message "Unknown layout: $want"
exit 1

#!/usr/bin/env bash
# Toggle a floating scratch terminal (Mod+Return) for quick one-off commands.
#
# niri has no scratchpad, so "hidden" means parked on the trailing empty
# workspace -- niri creates and reaps those dynamically, so nothing extra
# lingers in the workspace cycle once the window is pulled back. Showing it
# moves it to the active workspace, resizes it, centers it, and focuses it.
set -euo pipefail

APP_ID=quickterm
SIZE=60%

win_id() {
    niri msg -j windows | jq -r --arg a "$APP_ID" 'first(.[] | select(.app_id == $a) | .id) // empty'
}

# A window-rule can make the window floating, but its default-column-width is
# ignored for floating windows (measured: the window came up 952 wide on a 1920
# output, i.e. the tiling default), so the size is applied here instead.
shape() {
    niri msg action set-window-width --id "$1" "$SIZE"
    niri msg action set-window-height --id "$1" "$SIZE"
    niri msg action center-window --id "$1"
}

id=$(win_id)

# Not running yet -> start it, then shape it once the window shows up.
if [ -z "$id" ]; then
    kitty --class="$APP_ID" >/dev/null 2>&1 &
    disown
    for _ in $(seq 40); do
        id=$(win_id)
        [ -n "$id" ] && break
        sleep 0.1
    done
    [ -n "$id" ] && shape "$id"
    exit 0
fi

win=$(niri msg -j windows | jq -c --arg a "$APP_ID" 'first(.[] | select(.app_id == $a))')
win_ws=$(jq -r '.workspace_id' <<<"$win")
focused=$(jq -r '.is_focused' <<<"$win")

read -r cur_ws_id cur_idx output <<<"$(niri msg -j workspaces \
    | jq -r '.[] | select(.is_focused) | "\(.id) \(.idx) \(.output)"')"

if [ "$win_ws" = "$cur_ws_id" ] && [ "$focused" = "true" ]; then
    # Visible and focused -> park it out of sight.
    last=$(niri msg -j workspaces | jq --arg o "$output" '[.[] | select(.output == $o)] | length')
    # Standing on the trailing workspace already? Park one past it instead.
    [ "$cur_idx" = "$last" ] && last=$((last + 1))
    niri msg action move-window-to-workspace --window-id "$id" --focus false "$last"
else
    # Hidden, or sitting on another workspace -> bring it here.
    niri msg action move-window-to-workspace --window-id "$id" --focus false "$cur_idx"
    shape "$id"
    niri msg action focus-window --id "$id"
fi

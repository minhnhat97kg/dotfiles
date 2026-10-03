#!/usr/bin/env bash
# Fuzzy window switcher: list all niri windows and jump to the chosen one by
# title/app-id via fuzzel. Bound to Mod+Tab in niri.
set -euo pipefail

sel="$(
  niri msg --json windows \
    | jq -r '.[] | "\(.id)\t\(.app_id // "?"): \(.title // "(untitled)")"' \
    | fuzzel --dmenu --with-nth 2 --prompt 'Window: '
)"
[ -z "$sel" ] && exit 0

id="${sel%%$'\t'*}"
niri msg action focus-window --id "$id"

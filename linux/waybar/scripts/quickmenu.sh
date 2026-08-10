#!/usr/bin/env bash
# Small quick-launch menu -- replaces the eww bar's hamburger flyout.
set -euo pipefail

choice="$(printf 'Files\nTerminal' | fuzzel --dmenu --prompt 'Menu: ')"

case "$choice" in
    Files)    xdg-open ~ ;;
    Terminal) kitty ;;
esac

#!/usr/bin/env bash
# Power menu via fuzzel dmenu -- replaces the eww bar's hover powermenu.
set -euo pipefail

choices="Lock\nSuspend\nLogout\nReboot\nShutdown"
choice="$(printf '%b' "$choices" | fuzzel --dmenu --prompt 'Power: ')"

case "$choice" in
    # Route through logind so swayidle's `lock` handler fires (single owner of
    # the swaylock invocation) rather than spawning swaylock directly here.
    Lock)     loginctl lock-session ;;
    Suspend)  systemctl suspend ;;
    Logout)   niri msg action quit ;;
    Reboot)   systemctl reboot ;;
    Shutdown) systemctl poweroff ;;
esac

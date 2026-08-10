#!/usr/bin/env bash
# Cycles through tmux layouts: Stack (auto-expand) -> List -> Grid -> Columns -> (repeat)
# Bound to prefix+Space in tmux.conf.
set -euo pipefail

STACK_HEIGHT="80%"
curr=$(tmux show-window-option -v @layout_mode 2>/dev/null || true)

case "$curr" in
    stack)
        tmux set-hook -u -g pane-focus-in
        tmux set-window-option @layout_mode 'list'
        tmux select-layout even-vertical
        tmux display-message ' Layout: List'
        ;;
    list)
        tmux set-window-option @layout_mode 'grid'
        tmux select-layout tiled
        tmux display-message ' Layout: Grid'
        ;;
    grid)
        tmux set-window-option @layout_mode 'columns'
        tmux select-layout even-horizontal
        tmux display-message ' Layout: Columns'
        ;;
    *)
        tmux set-window-option @layout_mode 'stack'
        tmux select-layout main-horizontal
        tmux set-window-option main-pane-height "$STACK_HEIGHT"
        tmux set-hook -g pane-focus-in "resize-pane -y $STACK_HEIGHT"
        tmux display-message ' Layout: Stack (auto-expand ON)'
        ;;
esac

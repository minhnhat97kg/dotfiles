#!/usr/bin/env bash
# Background session auto-save timer for tmux.
#
# Replaces tmux-continuum's status-bar-driven save: continuum appends
# "#(continuum_save.sh)" to status-right, which makes tmux fork the script (and,
# inside it, tmux itself 2-3 times) on every status redraw — i.e. roughly once
# per keystroke. That fork storm is what makes the server stall under load.
#
# This runs detached for the life of the tmux server, sleeping in the
# background and only waking up to call resurrect's save script. tmux-continuum
# is still loaded for its auto-restore-on-start behaviour; its save timer is
# neutralised by re-asserting status-right after the plugins load.
#
# Usage: autosave.sh [interval-minutes] [save-script-path]

set -uo pipefail

interval=${1:-15}
save_script=${2:-$HOME/.config/tmux/plugins/tmux-resurrect/scripts/save.sh}

case "$interval" in
    ''|*[!0-9]*) exit 0 ;;   # disable if not a positive integer
esac
(( interval > 0 )) || exit 0
[ -x "$save_script" ] || exit 0

# Single instance per tmux server. $TMUX is "socket,pid,session"; key the lock
# on the server pid so a config reload (which re-runs this) is a no-op.
server_pid=${TMUX#*,}
server_pid=${server_pid%%,*}
lock="${TMPDIR:-/tmp}/tmux-autosave-${server_pid}.pid"

if [ -f "$lock" ] && kill -0 "$(cat "$lock" 2>/dev/null)" 2>/dev/null; then
    exit 0
fi
printf '%s\n' "$$" > "$lock"
trap 'rm -f "$lock"' EXIT INT TERM

seconds=$(( interval * 60 ))
while sleep "$seconds"; do
    # Stop if the tmux server is gone.
    tmux list-sessions >/dev/null 2>&1 || break
    "$save_script" quiet >/dev/null 2>&1 || true
done

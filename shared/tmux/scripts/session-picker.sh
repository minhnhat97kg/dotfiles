#!/usr/bin/env bash
# Session chooser shown on a fresh `tmux` connect.
#
# The zsh `tmux` wrapper in modules/home/shell.nix calls this for a bare
# `tmux` (or `tmux attach`) outside a client, so a new connect offers the
# existing sessions plus a "new session" entry instead of always spawning a
# fresh session. With no server running — or no fzf — it just starts one.
#
#   enter    attach to the highlighted session
#   ctrl-n   create a new session (name prompt; blank = tmux auto-name)
#   ctrl-x   kill the highlighted session (asks for confirmation)
#   esc      cancel and return to the shell

set -euo pipefail

# ── Nothing to choose from: no server, or fzf unavailable ────────────────────
tmux list-sessions >/dev/null 2>&1 || exec tmux new-session
command -v fzf >/dev/null 2>&1 || exec tmux new-session

# Nerd-font glyphs, built at runtime so this file stays plain ASCII.
NEW_ICON=$(printf '\uf055')      # nf-fa-plus_circle
SESSION_ICON=$(printf '\uf489')  # nf-fa-terminal
POINTER=$(printf '\uf054')       # nf-fa-chevron_right
NEW_KEY='__new__'

# fzf palette (Kanagawa Wave), hardcoded because fzf reads no tmux options.
FZF_COLOURS='bg:#1F1F28,fg:#DCD7BA,hl:#7E9CD8,fg+:#DCD7BA,bg+:#2D4F67,hl+:#E6C384'
FZF_COLOURS+=',info:#727169,prompt:#7E9CD8,pointer:#E6C384,marker:#98BB6C'
FZF_COLOURS+=',spinner:#7E9CD8,header:#727169,border:#54546D,label:#7E9CD8,query:#DCD7BA'

# Most recently active session first, so the one you used last sits on top.
list_sessions() {
    tmux list-sessions -F $'#{session_activity}\t#{session_name}' 2>/dev/null \
        | sort -rn | cut -f2- || true
}

# Each fzf line is "<session name>\t<display text>": --with-nth shows only the
# second field, while the selection keeps the name for attaching/killing.
build_list() {
    printf '%s\t  %s  New session\n' "$NEW_KEY" "$NEW_ICON"
    local name=''
    while IFS= read -r name; do
        [ -n "$name" ] && printf '%s\t  %s  %s\n' "$name" "$SESSION_ICON" "$name"
    done < <(list_sessions)
}

new_session() {
    local name=''
    printf '  New session name (blank = auto): ' >&2
    IFS= read -r name || true
    if [ -z "$name" ]; then
        exec tmux new-session
    elif tmux has-session -t "=$name" 2>/dev/null; then
        exec tmux attach -t "=$name"
    else
        exec tmux new-session -s "$name"
    fi
}

kill_session() {
    local name=$1 ans=''
    if [ -z "$name" ] || [ "$name" = "$NEW_KEY" ]; then
        return 0
    fi
    printf '  Kill session "%s"? [y/N] ' "$name" >&2
    IFS= read -r ans || true
    case "$ans" in
        [yY]*) tmux kill-session -t "=$name" 2>/dev/null || true ;;
    esac
    return 0
}

while true; do
    if ! out=$(build_list | fzf --height 40% --reverse --no-sort --border rounded \
                    --prompt "  $SESSION_ICON tmux $POINTER " \
                    --pointer "$POINTER" \
                    --header '  enter attach | ctrl-n new | ctrl-x kill | esc cancel' \
                    --color "$FZF_COLOURS" \
                    --delimiter $'\t' --with-nth 2 \
                    --expect ctrl-n,ctrl-x); then
        exit 0   # esc / ctrl-c
    fi

    key=${out%%$'\n'*}
    line=${out#*$'\n'}
    value=${line%%$'\t'*}

    case "$key" in
        ctrl-n) new_session ;;
        ctrl-x) kill_session "$value"; continue ;;
    esac

    [ "$value" = "$NEW_KEY" ] && new_session
    [ -n "$value" ] && exec tmux attach -t "=$value"
    exit 0
done

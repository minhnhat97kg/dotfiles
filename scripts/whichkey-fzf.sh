#!/usr/bin/env bash

# ====================================================================
# WhichKey-style FZF Keybinding Picker for SKHD/Yabai
# ====================================================================

# Helper functions for executing NVIM and TMUX entries
execute_nvim_key() {
  local key="$1"
  if [ -n "$NVIM_LISTEN_ADDRESS" ] && command -v nvim >/dev/null 2>&1; then
    nvim --server "$NVIM_LISTEN_ADDRESS" --remote-send "$key"
  elif command -v nvr >/dev/null 2>&1; then
    nvr --remote-send "$key"
  else
    echo "[whichkey-fzf] No running nvim remote server (NVIM_LISTEN_ADDRESS or nvr)." >&2
  fi
}

execute_tmux_key() {
  local key="$1"
  if command -v tmux >/dev/null 2>&1 && tmux has-session 2>/dev/null; then
    tmux send-keys "$key"
  else
    echo "[whichkey-fzf] No active tmux session." >&2
  fi
}

SKHDRC="${HOME}/Documents/projects/dotfiles/skhd/skhdrc"

# Parse skhdrc and create a searchable list
bindings=$(awk '
BEGIN {
    section = ""
    prev_comment = ""
}

# Capture section headers
/^# ====/ { next }
/^# [A-Z]/ {
    gsub(/^# /, "", $0)
    section = $0
    next
}

# Capture standalone comments (potential descriptions)
/^# [^=]/ && !/^# -/ {
    prev_comment = $0
    gsub(/^# /, "", prev_comment)
    next
}

# Capture keybindings
/^[a-z].*:.*/ {
    # Skip the show-keybindings binding to avoid recursion
    if ($0 ~ /show-keybindings\.sh/) next
    if ($0 ~ /whichkey-fzf\.sh/) next

    # Get the keybinding and command
    split($0, parts, " : ")
    key = parts[1]
    command = parts[2]

    # Clean up key format for display
    display_key = key
    gsub(/ctrl \+ alt \+ shift/, "⌃⌥⇧", display_key)
    gsub(/alt \+ shift/, "⌥⇧", display_key)
    gsub(/ctrl \+ alt/, "⌃⌥", display_key)
    gsub(/alt/, "⌥", display_key)
    gsub(/ctrl/, "⌃", display_key)
    gsub(/shift/, "⇧", display_key)
    gsub(/cmd/, "⌘", display_key)
    gsub(/ \+ /, "", display_key)
    gsub(/ - /, " ", display_key)
    gsub(/return/, "↩", display_key)
    gsub(/space/, "␣", display_key)
    gsub(/0x2B/, ",", display_key)
    gsub(/0x2C/, "/", display_key)
    gsub(/0x2F/, ".", display_key)

    # Get description from inline comment or previous comment
    desc = ""
    if (match($0, /# .*/)) {
        desc = substr($0, RSTART+2)
        gsub(/\(mod[12] \+ .*\)/, "", desc)
        gsub(/^[ \t]+|[ \t]+$/, "", desc)
    } else if (prev_comment != "") {
        desc = prev_comment
    }

    # Default description if none found
    if (desc == "") {
        if (command ~ /yabai.*--layout/) desc = "Change layout"
        else if (command ~ /yabai.*--focus/) desc = "Focus window/space"
        else if (command ~ /yabai.*--swap/) desc = "Swap windows"
        else if (command ~ /yabai.*--space/) desc = "Move to space"
        else if (command ~ /yabai.*--display/) desc = "Move to display"
        else if (command ~ /yabai.*--ratio/) desc = "Resize window"
        else if (command ~ /yabai.*--balance/) desc = "Balance windows"
        else if (command ~ /yabai.*--toggle/) desc = "Toggle option"
        else if (command ~ /yabai.*--create/) desc = "Create space"
        else if (command ~ /yabai.*--destroy/) desc = "Destroy space"
        else desc = "Execute command"
    }

    # Format: [SECTION] description | key | command
    printf "[%s] %s|%s|%s\n", section, desc, display_key, command

    prev_comment = ""
}

# Clear previous comment for other lines
!/^# / && !/^[a-z].*:/ { prev_comment = "" }
' "$SKHDRC")

# Use fzf to select a binding
# Integrate NVIM and TMUX keymaps
# Collect NVIM keymaps for multiple modes via headless nvim
if command -v nvim >/dev/null 2>&1; then
  nvim_kms=$(nvim --headless -u "$HOME/.config/nvim/init.lua" -c 'lua local modes={"n","v","x","s","o","i","t","c"}; for _,md in ipairs(modes) do for _,m in ipairs(vim.api.nvim_get_keymap(md)) do local d=m.desc or ("NVIM "..md.." mapping"); d=d:gsub("|"," "); local display=m.lhs:gsub("<leader>","␣"):gsub("<C%-(%a)>","⌃%1"):gsub("<Esc>","⎋"):gsub("<Tab>","⇥"); print(string.format("[NVIM-%s] %s|%s|NVIM:%s", md, d, display, m.lhs)) end end' +qa 2>/dev/null)
  if [ -n "$nvim_kms" ]; then
    bindings+=$'\n'"$nvim_kms"
  else
    echo "[whichkey-fzf] No NVIM keymaps found or failed to retrieve." >&2
  fi
fi
# Collect tmux keymaps via tmux list-keys (covers all tables)
if command -v tmux >/dev/null 2>&1; then
  tmux_kms=$(tmux list-keys 2>/dev/null | awk '
    /^bind-key/ {
      no_prefix="prefix"; table="root"; key=""; cmd="";
      for (i=2; i<=NF; i++) {
        if ($i == "-n") { no_prefix="no-prefix"; continue }
        if ($i == "-T") { table=$(i+1); i++; continue }
        if ($i ~ /^-/) { continue }
        if (key == "") { key=$i; continue }
        cmd = (cmd " " $i)
      }
      sub(/^ /, "", cmd)
      desc=cmd
      if (cmd ~ /select-pane -L/) desc="Focus pane Left";
      else if (cmd ~ /select-pane -R/) desc="Focus pane Right";
      else if (cmd ~ /select-pane -U/) desc="Focus pane Up";
      else if (cmd ~ /select-pane -D/) desc="Focus pane Down";
      else if (cmd ~ /split-window -h/) desc="Horizontal split";
      else if (cmd ~ /split-window -v/) desc="Vertical split";
      else if (cmd ~ /new-window/) desc="New window";
      else if (cmd ~ /send-prefix/) desc="Send prefix";
      else if (cmd ~ /copy-mode/) desc="Enter copy mode";
      gsub(/\|/, " ", desc)
      printf("[TMUX] %s (%s %s)|%s|TMUX:%s\n", desc, table, no_prefix, key, key)
    }
  ' | sed -E 's/C-([A-Za-z])/⌃\1/g')
  if [ -n "$tmux_kms" ]; then
    bindings+=$'\n'"$tmux_kms"
  else 
    echo "[whichkey-fzf] No TMUX keymaps found or failed to retrieve." >&2
  fi
fi

echo "$bindings" | sort -u > whichkey_bindings.txt
selected=$(echo "$bindings" | fzf \
    --ansi \
    --height=100% \
    --border=rounded \
    --prompt="⌨️  Keybindings > " \
    --header="Select a keybinding to execute (ESC to cancel)" \
    --preview='echo {}' \
    --preview-window=hidden \
    --delimiter="|" \
    --with-nth=1,2 \
    --bind='ctrl-/:toggle-preview' \
    --color='fg:#cdd6f4,bg:#1e1e2e,hl:#f38ba8' \
    --color='fg+:#cdd6f4,bg+:#313244,hl+:#f38ba8' \
    --color='info:#cba6f7,prompt:#cba6f7,pointer:#f5e0dc' \
    --color='marker:#f5e0dc,spinner:#f5e0dc,header:#f38ba8')

# Execute the selected command
if [ -n "$selected" ]; then
    command=$(echo "$selected" | cut -d'|' -f3)
    if [[ $command == NVIM:* ]]; then
        exec_key="${command#NVIM:}"
        execute_nvim_key "$exec_key"
    elif [[ $command == TMUX:* ]]; then
        exec_key="${command#TMUX:}"
        execute_tmux_key "$exec_key"
    elif [[ $command == TMUXP:* ]]; then
        exec_key="${command#TMUXP:}"
        # Send tmux prefix (default C-b) then key
        tmux send-keys C-b "$exec_key"
    else
        eval "$command"
    fi
fi

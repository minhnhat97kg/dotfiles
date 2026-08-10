#!/usr/bin/env bash
# Snapshot of the zsh init content that used to live in modules/home/shell.nix's
# programs.zsh.initContent + shellAliases, before .zshrc was taken out of
# Home Manager's management. Source this from your hand-maintained ~/.zshrc
# if you still want this behavior:
#
#   source ~/.scripts/shell-init.sh
#
# Not auto-sourced by anything — .zshrc is no longer written by Nix, so this
# file won't take effect unless you explicitly source it yourself.

export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export GOPATH=$HOME/go
export PATH=$PATH:$GOROOT/bin:$GOPATH/bin
export NPM_CONFIG_PREFIX="$HOME/.npm-global"
export PATH="$HOME/.npm-global/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
ALIASES_SCRIPT="$HOME/.config/dotfiles/scripts/load-aliases.sh"
export AWS_REGION=ap-southeast-1
if [ -f "$ALIASES_SCRIPT" ]; then
  eval "$($ALIASES_SCRIPT)"
fi
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
export XDG_CONFIG_HOME="$HOME/.config"
export PATH="$HOME/.scripts:$PATH"

# opencode (optional — only if installed)
[ -d "$HOME/.opencode/bin" ] && export PATH="$HOME/.opencode/bin:$PATH"
alias claude-api="CLAUDE_CONFIG_DIR=~/.claude-api claude"

alias ll="ls -l"
alias e="nvim"
alias lg="lazygit"
alias eink="DISPLAY_MODE=eink nvim"

# oh-my-zsh (theme: robbyrussell) was previously enabled via
# programs.zsh.oh-my-zsh in shell.nix — that framework install is separate
# from this snippet. If you want it back, install oh-my-zsh yourself
# (https://ohmyz.sh) and set ZSH_THEME="robbyrussell" in its config.

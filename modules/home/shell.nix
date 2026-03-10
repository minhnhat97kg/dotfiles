{ lib, ... }:
{
  programs.zsh = {
    enable = true;
    initContent = lib.mkOrder 550 ''
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
    '';
    shellAliases = {
      ll = "ls -l";
      e = "nvim";
      lg = "lazygit";

      # SSH password management aliases
      sshp = "ssh-with-password";
      sshp-add = "ssh-password-add";
      sshp-list = "ssh-password-list";
      sshp-tunnel = "ssh-tunnel";
    };
    oh-my-zsh = {
      enable = true;
      theme = "robbyrussell";
    };
  };
}

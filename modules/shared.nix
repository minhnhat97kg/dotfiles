{ pkgs, lib, sharedPackages, ... }:
{
  home.stateVersion = "24.05";
  nixpkgs.config.allowUnfree = true;
  home.packages = sharedPackages pkgs;
  programs = {
    neovim = { enable = true; defaultEditor = true; };
    tmux = {
      enable = true;
      keyMode = "vi";
      mouse = true;
      plugins = with pkgs.tmuxPlugins; [
        better-mouse-mode
        yank
        {
          plugin = catppuccin;
          extraConfig = ''
            set -g default-terminal "tmux-256color"
            set-option -ga terminal-overrides ",xterm-256color:Tc"
            set -g @catppuccin_flavor "mocha"
            set -g @catppuccin_window_status_style "rounded"
            set -g @catppuccin_window_default_text "#{b:pane_current_path}"
            set -g @catppuccin_window_current_text "#{b:pane_current_path}"
          '';
        }
      ];
      extraConfig = ''
        set -sg escape-time 0
        setw -g mode-keys vi
        bind-key -T copy-mode-vi v send-keys -X begin-selection
        bind c new-window -c "#{pane_current_path}"
        bind | split-window -h -c "#{pane_current_path}"
        bind - split-window -v -c "#{pane_current_path}"
        set -g pane-border-style "fg=#313244"
        set -g pane-active-border-style "fg=#89b4fa,bold"
        set -g window-style "fg=#585b70,bg=#181825"
        set -g window-active-style "fg=#cdd6f4,bg=#1e1e2e"
        is_vim="ps -o state= -o comm= -t '#{pane_tty}' | grep -iqE '^[^TXZ ]+ +(\\S+\\/)?g?(view|n?vim?x?)(diff)?$'"
        bind -n C-h run "($is_vim && tmux send-keys C-h) || tmux select-pane -L"
        bind -n C-j run "($is_vim && tmux send-keys C-j) || tmux select-pane -D"
        bind -n C-k run "($is_vim && tmux send-keys C-k) || tmux select-pane -U"
        bind -n C-l run "($is_vim && tmux send-keys C-l) || tmux select-pane -R"
      '';
    };
    zsh = {
      enable = true;
      initContent = lib.mkOrder 550 ''
        export GOPATH=$HOME/go
        export PATH=$PATH:$GOROOT/bin:$GOPATH/bin
        export NPM_CONFIG_PREFIX="$HOME/.npm-global"
        export PATH="$HOME/.npm-global/bin:$PATH"
        export PATH="$HOME/.local/bin:$PATH"
        ALIASES_SCRIPT="$HOME/.config/dotfiles/scripts/load-aliases.sh"
        if [ -f "$ALIASES_SCRIPT" ]; then
          eval "$($ALIASES_SCRIPT)"
        fi
      '';
      shellAliases = {
        ll = "ls -l";
        e = "nvim";
        lg = "lazygit";
      };
      oh-my-zsh = { enable = true; theme = "robbyrussell"; };
    };
    lazygit = {
      enable = true;
      enableZshIntegration = false;  # Disable lg() function, use simple alias instead
    };
    direnv.enable = true;
  };
  home.file.".config/nvim/" = { source = ../nvim; recursive = true; };
  programs.git = {
    enable = true;
    includes = [
      { path = "~/.config/git/gitconfig"; }
      { condition = "gitdir:~/work/**"; path = "~/.config/git/work.gitconfig"; }
      { condition = "gitdir:~/projects/**"; path = "~/.config/git/minhnhat97kg.gitconfig"; }
    ];
  };
  home.file.".scripts/" = { source = ../scripts; recursive = true; executable = true; };
  home.file.".config/git/gitconfig".source = ../git/gitconfig;
  home.file.".config/git/minhnhat97kg.gitconfig".source = ../git/minhnhat97kg.gitconfig;
  home.file.".gitignore_global".source = ../git/gitignore_global;
  home.file.".config/dotfiles/scripts/load-aliases.sh" = { source = ../scripts/load-aliases.sh; executable = true; };
}

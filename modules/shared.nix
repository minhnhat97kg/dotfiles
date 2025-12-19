{ pkgs, lib, sharedPackages, ... }:
{
  home.stateVersion = "24.11";
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
        resurrect
      ];
      extraConfig = ''
        # Terminal and color support
        set -g default-terminal "tmux-256color"
        set-option -ga terminal-overrides ",xterm-256color:Tc"

        # Remove all background colors (transparent background)
        set -g status-style bg=default
        set -g pane-border-style fg=default
        set -g pane-active-border-style fg=default
        set -g window-style bg=default
        set -g window-active-style bg=default

        # Allow passthrough for image rendering (Kitty graphics protocol)
        set -g allow-passthrough on

        set -sg escape-time 0
        setw -g mode-keys vi
        bind-key -T copy-mode-vi v send-keys -X begin-selection
        bind c new-window -c "#{pane_current_path}"
        bind | split-window -h -c "#{pane_current_path}"
        bind - split-window -v -c "#{pane_current_path}"
        is_vim="ps -o state= -o comm= -t '#{pane_tty}' | grep -iqE '^[^TXZ ]+ +(\\S+\\/)?g?(view|n?vim?x?)(diff)?$'"
        bind -n C-h run "($is_vim && tmux send-keys C-h) || tmux select-pane -L"
        bind -n C-j run "($is_vim && tmux send-keys C-j) || tmux select-pane -D"
        bind -n C-k run "($is_vim && tmux send-keys C-k) || tmux select-pane -U"
        bind -n C-l run "($is_vim && tmux send-keys C-l) || tmux select-pane -R"

        # Pane resizing with prefix+hjkl
        bind h resize-pane -L 5
        bind j resize-pane -D 5
        bind k resize-pane -U 5
        bind l resize-pane -R 5

        # Window navigation moved to Alt+,/.
        bind -n M-, previous-window
        bind -n M-. next-window

        # Alt+number to jump to window directly
        bind -n M-1 select-window -t 1
        bind -n M-2 select-window -t 2
        bind -n M-3 select-window -t 3
        bind -n M-4 select-window -t 4
        bind -n M-5 select-window -t 5
        bind -n M-6 select-window -t 6
        bind -n M-7 select-window -t 7
        bind -n M-8 select-window -t 8
        bind -n M-9 select-window -t 9

        # Reload tmux config (prefix + r)
        bind r source-file ~/.config/tmux/tmux.conf \; display-message "Config reloaded!"
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
        [ -f ~/.fzf.zsh ]  && source ~/.fzf.zsh
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
      oh-my-zsh = { enable = true; theme = "robbyrussell"; };
    };
    lazygit = {
      enable = true;
      enableZshIntegration = false;  # Disable lg() function, use simple alias instead
    };
    direnv.enable = true;
  };
  home.file.".config/nvim/" = { source = ../nvim; recursive = true; };
  # Kitty config - use onChange to preserve user-generated theme files
  home.file.".config/kitty/kitty.conf" = {
    source = ../kitty/kitty.conf;
    # Don't replace the entire directory so kitten-generated theme files persist
  };
  programs.git = {
    enable = true;
    includes = [
      { path = "~/.config/git/gitconfig"; }
      { condition = "gitdir:~/buuuk/**"; path = "~/.config/git/buuuk.gitconfig"; }
      { condition = "gitdir:~/Documents/work/company/buuuk/**"; path = "~/.config/git/buuuk.gitconfig"; }
      { condition = "gitdir:~/work/**"; path = "~/.config/git/work.gitconfig"; }
      { condition = "gitdir:~/projects/**"; path = "~/.config/git/minhnhat97kg.gitconfig"; }
    ];
  };
  home.file.".scripts/" = { source = ../scripts; recursive = true; executable = true; force = true; };
  home.file.".config/git/gitconfig".source = ../git/gitconfig;
  home.file.".config/git/minhnhat97kg.gitconfig".source = ../git/minhnhat97kg.gitconfig;
  home.file.".config/git/work.gitconfig" = lib.mkIf (builtins.pathExists ../git/work.gitconfig) {
    source = ../git/work.gitconfig; force = true;
  };
  home.file.".config/git/buuuk.gitconfig" = lib.mkIf (builtins.pathExists ../git/buuuk.gitconfig) {
    source = ../git/buuuk.gitconfig;
  };
  home.file.".gitignore_global" = { source = ../git/gitignore_global; force = true; };
  home.file.".config/dotfiles/scripts/load-aliases.sh" = { source = ../scripts/load-aliases.sh; executable = true; };
  home.file.".fzf.zsh".source = ../fzf/fzf.zsh;

  # SSH password management scripts - available in PATH
  home.file.".local/bin/ssh-with-password" = { source = ../scripts/ssh-with-password.sh; executable = true; force = true; };
  home.file.".local/bin/ssh-password-add" = { source = ../scripts/ssh-password-add.sh; executable = true; force = true; };
  home.file.".local/bin/ssh-password-list" = { source = ../scripts/ssh-password-list.sh; executable = true; force = true; };
  home.file.".local/bin/ssh-tunnel" = { source = ../scripts/ssh-tunnel.sh; executable = true; force = true; };

  # Clipboard manager wrapper - available in PATH
  home.file.".local/bin/clipse-wrapper" = { source = ../scripts/clipse-wrapper.sh; executable = true; force = true; };

  # Theme toggle - available in PATH
  home.file.".local/bin/toggle-theme" = { source = ../scripts/toggle-theme.sh; executable = true; force = true; };

}

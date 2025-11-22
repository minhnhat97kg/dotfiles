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

        # Pane resizing with Alt+hjkl (no prefix needed)
        bind -n M-h resize-pane -L 5
        bind -n M-j resize-pane -D 5
        bind -n M-k resize-pane -U 5
        bind -n M-l resize-pane -R 5

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
  home.file.".config/git/work.gitconfig".source = ../git/work.gitconfig;
  home.file.".gitignore_global".source = ../git/gitignore_global;
  home.file.".config/dotfiles/scripts/load-aliases.sh" = { source = ../scripts/load-aliases.sh; executable = true; };
  home.file.".fzf.zsh".source = ../fzf/fzf.zsh;

  # SSH password management scripts - available in PATH
  home.file.".local/bin/ssh-with-password" = { source = ../scripts/ssh-with-password.sh; executable = true; force = true; };
  home.file.".local/bin/ssh-password-add" = { source = ../scripts/ssh-password-add.sh; executable = true; force = true; };
  home.file.".local/bin/ssh-password-list" = { source = ../scripts/ssh-password-list.sh; executable = true; force = true; };
  home.file.".local/bin/ssh-tunnel" = { source = ../scripts/ssh-tunnel.sh; executable = true; force = true; };
  home.file."Applications/Qutebrowser Profile.app" = {
    source = pkgs.runCommand "Qutebrowser-Profile-app" { } ''
      mkdir -p $out/Contents/MacOS $out/Contents/Resources
      cat > $out/Contents/Info.plist <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleExecutable</key><string>qutebrowser-profile-wrapper</string>
  <key>CFBundleIdentifier</key><string>org.nixos.qutebrowser.profile</string>
  <key>CFBundleName</key><string>Qutebrowser Profile</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleVersion</key><string>1.0</string>
</dict></plist>
PLIST
      cat > $out/Contents/MacOS/qutebrowser-profile-wrapper <<'WRAP'
#!/usr/bin/env bash
exec "$HOME/.local/bin/qb-profile" default "$@"
WRAP
      chmod +x $out/Contents/MacOS/qutebrowser-profile-wrapper
    '';
    recursive = true;
  };
}

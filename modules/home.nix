{
  inputs,
  pkgs,
  username,
  pkgs-unstable,
  ...
}:

{
  #
  nixpkgs = {
    overlays = [
      (self: super: {
        neoVim = super.neovim.overrideAttrs (oldAttrs: {
          src = super.fetchFromGitHub {
            owner = "neovim";
            repo = "neovim";
            rev = "v0.11.2";
            sha256 = "e14c092d91f81ec5f1d533baae2b20730e93316eb4aafec0d2d00f0e0193d39e";
          };
        });
      })
    ];
  };

  home.username = username;
  home.homeDirectory = "/Users/${username}";
  home.stateVersion = "22.05";
  home.packages = (
    with pkgs;
    [
      # neovim
      go
      fzf
      yabai
      skhd
      git

      # rust
      cargo
      rustc
      rustfmt
      clippy

      rust-analyzer
      fx # json viewer
      harlequin # database gui
    ]
  );
  # ++ (with pkgs-unstable; [
  #   neovim
  # ]);

  home.file = {
    # "~/.tmux.conf".source = ../tmux/tmux.conf;
    ".config/zellij/config.kdl".source = ../zellij/config.kdl;
    # ".config/skhd/skhdrc".source = ../skhdc/skhdrc;
    ".config/yabai/yabairc".source = ../yabai/yabairc;
  };

  home.file.".config/nvim/" = {
    source = ../nvim;
    recursive = true;
  };

  programs = {
    neovim = {
      enable = true;
      # extraLuaConfig = builtins.readFile ../nvim/init.lua;
      # package = inputs.neovim-nightly.packages.${pkgs.system}.default;
      # package = inputs.neovim-nightly.packages.${pkgs.system}.default;
    };

    tmux = {
      enable = true;
      keyMode = "vi";
      plugins = with pkgs; [
        tmuxPlugins.better-mouse-mode
        tmuxPlugins.yank
        {
          plugin = tmuxPlugins.catppuccin;
          extraConfig = ''
            set -g default-terminal "tmux-256color"
            set-option -ga terminal-overrides ",xterm-256color:Tc"

            set -g mouse on
            set -g @catppuccin_flavor "mocha"
            set -g @catppuccin_window_status_style "rounded"
            set -g @catppuccin_flavour 'frappe'
            set -g @catppuccin_window_tabs_enabled on
            set -g @catppuccin_date_time "%H:%M"
            set -g status-right-length 100
            set -g status-left-length 100
            set -g status-left ""
            set -g status-right "#{E:@catppuccin_status_application}"
            set -agF status-right "#{E:@catppuccin_status_cpu}"
            set -ag status-right "#{E:@catppuccin_status_session}"
            set -ag status-right "#{E:@catppuccin_status_uptime}"
            set -agF status-right "#{E:@catppuccin_status_battery}"

          '';
        }
      ];
      extraConfig = ''
        set -g mouse on
        set -sg escape-time 0
        setw -g mode-keys vi

        bind-key -T copy-mode-vi v send-keys -X begin-selection

        bind c new-window -c "#{pane_current_path}"

        bind-key -n C-M-h resize-pane -L 2
        bind-key -n C-M-j resize-pane -D 2
        bind-key -n C-M-k resize-pane -U 2
        bind-key -n C-M-l resize-pane -R 2

        bind -n M-h previous-window
        bind -n M-l next-window

        bind | split-window -h -c "#{pane_current_path}"
        bind - split-window -v -c "#{pane_current_path}"

            bind-key h swap-window -t -1\; select-window -t -1
            bind-key l swap-window -t +1\; select-window -t +1

            is_vim="ps -o state= -o comm= -t '#{pane_tty}' | grep -iqE '^[^TXZ ]+ +(\\S+\\/)?g?(view|n?vim?x?)(diff)?$'"
            is_fzf="ps -o state= -o comm= -t '#{pane_tty}' | grep -iqE '^[^TXZ ]+ +(\\S+\\/)?fzf$'"
            bind -n C-h run "($is_vim && tmux send-keys C-h) || \
                                      tmux select-pane -L"
            bind -n C-j run "($is_vim && tmux send-keys C-j)  || \
                                     ($is_fzf && tmux send-keys C-j) || \
                                     tmux select-pane -D"
            bind -n C-k run "($is_vim && tmux send-keys C-k) || \
                                      ($is_fzf && tmux send-keys C-k)  || \
                                      tmux select-pane -U"
            bind -n C-l run  "($is_vim && tmux send-keys C-l) || \
                                      tmux select-pane -R"

            tmux_version='$(tmux -V | sed -En "s/^tmux ([0-9]+(.[0-9]+)?).*/\1/p")'
            if-shell -b '[ "$(echo "$tmux_version < 3.0" | bc)" = 1 ]' \
                "bind-key -n 'C-\\' if-shell \"$is_vim\" 'send-keys C-\\'  'select-pane -l'"
            if-shell -b '[ "$(echo "$tmux_version >= 3.0" | bc)" = 1 ]' \
                "bind-key -n 'C-\\' if-shell \"$is_vim\" 'send-keys C-\\\\'  'select-pane -l'"

            bind-key -T copy-mode-vi C-h select-pane -L
            bind-key -T copy-mode-vi C-j select-pane -D
            bind-key -T copy-mode-vi C-k select-pane -U
            bind-key -T copy-mode-vi C-l select-pane -R
            bind-key -T copy-mode-vi C-\\ select-pane -l

            set -g focus-events on

      '';

    };

    zsh = {
      enable = true;
      initExtra = ''
        export PATH="$HOME/.jenv/bin:$PATH"
        export GOPATH=$HOME/go
        export PATH=$PATH:$GOROOT/bin:$GOPATH/bin
        source $HOME/.local/bin/env 
        export PATH="$HOME/.jenv/bin:$PATH"
      '';

      shellAliases = {
        ll = "ls -l";
        lg = "lazygit";
        e = "nvim";
        dev = "aws-vault exec buuuk-dev --";
        sit = "aws-vault exec jpas-sit-admin --";
        uat = "aws-vault exec jpas-uat-admin --";
      };

      oh-my-zsh = {
        enable = true;
        plugins = [ ];
        theme = "robbyrussell";
      };
    };

    lazygit = {
      enable = true;
    };

    zellij = {
      enable = true;
    };
    direnv = {
      enable = true;
    };

    # alacritty = {
    #   enable = true;
    #   # settings = builtins.readFile ../alacritty/alacritty.toml;
    # };
  };

}
#

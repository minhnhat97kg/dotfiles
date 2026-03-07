{ pkgs, ... }:
{
  programs.tmux = {
    enable = true;
    keyMode = "vi";
    mouse = true;
    plugins = with pkgs.tmuxPlugins; [
      better-mouse-mode
      yank
      resurrect
      {
        plugin = continuum;
        extraConfig = ''
          set -g @continuum-restore 'on'
          set -g @continuum-save-interval '10'
        '';
      }
    ];
    extraConfig = ''
      # Terminal and color support
      set -g default-terminal "tmux-256color"
      set-option -ga terminal-overrides ",xterm-256color:Tc"

      # Allow passthrough for image rendering (Kitty graphics protocol)
      set -g allow-passthrough on

      # ── Catppuccin Mocha palette ─────────────────────────────────────────
      # base=#1e1e2e  surface0=#313244  overlay1=#7f849c
      # lavender=#b4befe  blue=#89b4fa  mauve=#cba6f7
      # text=#cdd6f4  subtext1=#bac2de

      # Pane borders: inactive dim, active lavender highlight
      set -g pane-border-style "fg=#313244"
      set -g pane-active-border-style "fg=#b4befe,bold"

      # Active pane dim effect (transparent bg preserved on active)
      set -g window-style "bg=default,fg=#bac2de"
      set -g window-active-style "bg=default,fg=#cdd6f4"

      # ── Status bar ───────────────────────────────────────────────────────
      set -g status-style "bg=default,fg=#7f849c"
      set -g status-position bottom
      set -g status-interval 5

      # Left: empty
      set -g status-left ""

      # Center: window list with truncated name (max 10 chars, abc...xyz style)
      # #{window_name} > 10 chars => show first 3 + "..." + last 4
      set -g status-justify centre
      set -g window-status-format         "#[fg=#585b70] #I:#{?#{>:#{window_name_len},10},#{=3:window_name}...#{=-4:window_name},#{window_name}} "
      set -g window-status-current-format "#[fg=#cba6f7,bold,reverse] #I:#{?#{>:#{window_name_len},10},#{=3:window_name}...#{=-4:window_name},#{window_name}} "

      # Right: compact datetime  22:49 26-02
      set -g status-right "#[fg=#7f849c]%H:%M %d-%m"
      set -g status-right-length 12

      set -sg escape-time 0
      setw -g mode-keys vi
      bind-key -T copy-mode-vi v send-keys -X begin-selection
      bind c new-window -c "#{pane_current_path}"
      bind | split-window -h -c "#{pane_current_path}"
      bind - split-window -v -c "#{pane_current_path}"
      bind -n C-h run "ps -o state= -o comm= -t '#{pane_tty}' | grep -iqE '^[^TXZ ]+ +(\\S+\\/)?g?(view|n?vim?x?)(diff)?$' && tmux send-keys C-h || tmux select-pane -L"
      bind -n C-j run "ps -o state= -o comm= -t '#{pane_tty}' | grep -iqE '^[^TXZ ]+ +(\\S+\\/)?g?(view|n?vim?x?)(diff)?$' && tmux send-keys C-j || tmux select-pane -D"
      bind -n C-k run "ps -o state= -o comm= -t '#{pane_tty}' | grep -iqE '^[^TXZ ]+ +(\\S+\\/)?g?(view|n?vim?x?)(diff)?$' && tmux send-keys C-k || tmux select-pane -U"
      bind -n C-l run "ps -o state= -o comm= -t '#{pane_tty}' | grep -iqE '^[^TXZ ]+ +(\\S+\\/)?g?(view|n?vim?x?)(diff)?$' && tmux send-keys C-l || tmux select-pane -R"

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

  programs.zellij = {
    enable = true;
    settings = {
      theme = "catppuccin-mocha";
      pane_frames = false;
      default_layout = "compact";
      simplified_ui = true;
      # Điều hướng pane giống tmux (Ctrl-h/j/k/l)
      keybinds = {
        move = {
          "bind \"Ctrl h\"" = { MoveFocus = "Left"; };
          "bind \"Ctrl j\"" = { MoveFocus = "Down"; };
          "bind \"Ctrl k\"" = { MoveFocus = "Up"; };
          "bind \"Ctrl l\"" = { MoveFocus = "Right"; };
        };
      };
    };
  };
}

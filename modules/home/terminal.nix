{ pkgs, ... }:
{
  # kitty's config lives in modules/home/kitty.nix.

  programs.alacritty = {
    enable = true;
    # Config only: the package is a Homebrew cask on macOS, and the Nix build
    # hits the same EGL crash as kitty on non-NixOS Linux.
    package = null;
    settings = {
      font = {
        normal = { family = "JetBrainsMono Nerd Font"; style = "Regular"; };
        bold = { family = "JetBrainsMono Nerd Font"; style = "Bold"; };
        italic = { family = "JetBrainsMono Nerd Font"; style = "Italic"; };
        bold_italic = { family = "JetBrainsMono Nerd Font"; style = "Bold Italic"; };
        size = 13.0;
      };
      window = {
        option_as_alt = "Both";
        padding = { x = 12; y = 12; };
        opacity = 1.0;
      };
      scrolling.history = 10000;
      cursor = {
        style = { shape = "Block"; blinking = "On"; };
        blink_interval = 750;
      };
      env.TERM = "xterm-256color";
    };
  };

  # tmux: use the real config verbatim (symlinked from the repo) instead of
  # programs.tmux's config-generation, which would wrap/alter it.
  home.packages = [ pkgs.tmux ];

  home.file.".config/tmux" = {
    source = ../../shared/tmux;
    recursive = true;
  };
}

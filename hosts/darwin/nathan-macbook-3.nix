# Host-specific configuration for Nathan-Macbook-3
# Receives: username, sharedPackages, darwinPackages via extraSpecialArgs
{ pkgs, lib, username, sharedPackages, darwinPackages, ... }:
{
  # Host identity
  networking.hostName = "Nathan-Macbook-3";
  networking.computerName = "Nathan-Macbook-3";

  # yabai — bsp tiling window manager. Basic tiling/focus/resize works out of
  # the box; the scripting addition (better space handling, some window rules)
  # needs SIP partially disabled — a manual, security-relevant step this repo
  # deliberately does NOT automate:
  #   1. Reboot into Recovery Mode (hold power button on Apple Silicon)
  #   2. Terminal: csrutil enable --without debug --without fs
  #   3. Reboot, then: sudo yabai --install-sa && sudo yabai --load-sa
  # Without that, everything below still works except a few edge cases
  # (moving windows across spaces without focusing them first, etc).
  services.yabai = {
    enable = true;
    package = pkgs.yabai;
    config = {
      layout = "bsp";
      window_placement = "second_child";
      window_gap = 8;
      top_padding = 8;
      bottom_padding = 8;
      left_padding = 8;
      right_padding = 8;
      mouse_follows_focus = "off";
      focus_follows_mouse = "off";
    };
    extraConfig = ''
      yabai -m rule --add app="System Settings" manage=off
      yabai -m rule --add app="Finder" manage=off
    '';
  };

  services.skhd = {
    enable = true;
    skhdConfig = ''
      # Focus window
      alt - h : yabai -m window --focus west
      alt - j : yabai -m window --focus south
      alt - k : yabai -m window --focus north
      alt - l : yabai -m window --focus east

      # Move window
      shift + alt - h : yabai -m window --swap west
      shift + alt - j : yabai -m window --swap south
      shift + alt - k : yabai -m window --swap north
      shift + alt - l : yabai -m window --swap east

      # Resize window — pair opposite edges per direction (github.com/asmvik/yabai/issues/200)
      # so growing one side and shrinking the other happens in a single keypress
      ctrl + alt - h : yabai -m window --resize left:-40:0; yabai -m window --resize right:-40:0
      ctrl + alt - l : yabai -m window --resize right:40:0; yabai -m window --resize left:40:0
      ctrl + alt - j : yabai -m window --resize bottom:0:40; yabai -m window --resize top:0:40
      ctrl + alt - k : yabai -m window --resize top:0:-40; yabai -m window --resize bottom:0:-40

      # Float / fullscreen
      shift + alt - space : yabai -m window --toggle float --grid 4:4:1:1:2:2
      alt - f : yabai -m window --toggle zoom-fullscreen

      # Switch space
      alt - 1 : yabai -m space --focus 1
      alt - 2 : yabai -m space --focus 2
      alt - 3 : yabai -m space --focus 3
      alt - 4 : yabai -m space --focus 4

      # Move window to space
      shift + alt - 1 : yabai -m window --space 1
      shift + alt - 2 : yabai -m window --space 2
      shift + alt - 3 : yabai -m window --space 3
      shift + alt - 4 : yabai -m window --space 4

      # Restart yabai
      ctrl + alt - r : yabai --restart-service
    '';
  };

  # Home-manager user config
  home-manager.users.${username} = { pkgs, lib, ... }: {
    imports = [
      ../../modules/home/default.nix
      ../../modules/home/qutebrowser.nix
    ];

    _module.args.sharedPackages = sharedPackages;

    home.username = username;
    home.homeDirectory = "/Users/${username}";
    home.packages = (darwinPackages pkgs) ++ (with pkgs; [ kitty qutebrowser ]);

    # Kitty is installed via homebrew cask; write config directly.
    home.file.".config/kitty/kitty.conf".text = ''
      macos_option_as_alt yes

      font_family JetBrainsMono Nerd Font
      bold_font auto
      italic_font auto
      bold_italic_font auto
      font_size 12.0

      # Classic monochrome theme
      foreground #d9d9d9
      background #000000
      background_opacity 1.0
      macos_titlebar_color background
      selection_foreground #000000
      selection_background #d9d9d9
      cursor #d9d9d9
      cursor_text_color #000000
      url_color #d9d9d9
      active_tab_foreground #d9d9d9
      active_tab_background #000000
      inactive_tab_foreground #808080
      inactive_tab_background #000000
      tab_bar_background #000000

      # ANSI palette: black, white, and grays only
      color0  #000000
      color1  #808080
      color2  #a8a8a8
      color3  #bcbcbc
      color4  #8a8a8a
      color5  #9e9e9e
      color6  #c6c6c6
      color7  #d9d9d9
      color8  #4d4d4d
      color9  #8c8c8c
      color10 #b3b3b3
      color11 #cfcfcf
      color12 #999999
      color13 #adadad
      color14 #e0e0e0
      color15 #ffffff
    '';
  };
}

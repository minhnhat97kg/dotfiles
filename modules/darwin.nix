{ inputs, pkgs, lib, username, useremail, sharedHomeConfig, ... }:
{
  system.stateVersion = 5;
  nixpkgs.config.allowUnfree = true;
  nixpkgs.hostPlatform = "aarch64-darwin";

  nix = {
    enable = true;
    package = pkgs.nix;
    gc = {
      automatic = true;
      options = "--delete-older-than 7d";
    };
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      substituters = [
        "https://cache.nixos.org"
        "https://mirror.sjtu.edu.cn/nix-channels/store"
        "https://nix-community.cachix.org"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];
      trusted-users = [ username ];
    };
  };

  # macOS-specific settings
  programs.zsh.enable = true;

  homebrew = {
    enable = true;
    casks = [ ];
  };

  environment.systemPackages = with pkgs; [
    nixfmt-rfc-style
    yabai
    skhd
    sketchybar
    jankyborders
    jq
    qutebrowser
  ];

  # Window management services
  services.yabai = {
    enable = true;
    enableScriptingAddition = true;
    config = {
      external_bar = "all:32:0";
      layout = "bsp";
      top_padding = 10;
      bottom_padding = 10;
      left_padding = 10;
      right_padding = 10;
      window_gap = 10;
      mouse_follows_focus = "off";
      focus_follows_mouse = "off";
      mouse_modifier = "fn";
      mouse_action1 = "move";
      mouse_action2 = "resize";
      mouse_drop_action = "swap";
      window_origin_display = "default";
      window_placement = "second_child";
      window_shadow = "on";
      window_opacity = "off";
      window_opacity_duration = "0.0";
      active_window_opacity = "1.0";
      normal_window_opacity = "0.90";
      auto_balance = "off";
      split_ratio = "0.50";
      window_border = "off";
      window_border_width = 6;
      active_window_border_color = "0xff775759";
      normal_window_border_color = "0xff555555";
    };
    extraConfig = ''
      yabai -m rule --add app="^System Settings$" manage=off
      yabai -m rule --add app="^System Preferences$" manage=off
      yabai -m rule --add app="^Archive Utility$" manage=off
      yabai -m rule --add app="^App Store$" manage=off
      yabai -m rule --add app="^Activity Monitor$" manage=off
      yabai -m rule --add app="^Calculator$" manage=off
      yabai -m rule --add app="^Dictionary$" manage=off
      yabai -m rule --add app="^Software Update$" manage=off
      yabai -m rule --add app="^About This Mac$" manage=off
      yabai -m rule --add app="^Finder$" title="(Co(py|nnect)|Move|Info|Pref)" manage=off
      yabai -m rule --add title="^skhd-whichkey$" manage=off sticky=on layer=above
      echo "yabai configuration loaded.."
    '';
  };

  services.skhd = {
    enable = true;
    skhdConfig = builtins.readFile ../skhd/skhdrc;
  };

  services.sketchybar = {
    enable = true;
    config = builtins.readFile ../sketchybar/sketchybarrc;
  };

  # JankyBorders service
  launchd.user.agents.jankyborders = {
    serviceConfig = {
      ProgramArguments = [
        "${pkgs.jankyborders}/bin/borders"
        "active_color=0xff89b4fa"
        "inactive_color=0xff6c7086"
        "width=5.0"
        "style=round"
      ];
      KeepAlive = true;
      RunAtLoad = true;
      StandardOutPath = "/tmp/jankyborders.out.log";
      StandardErrorPath = "/tmp/jankyborders.err.log";
    };
  };



  # Host & user configuration
  networking.hostName = "Nathan-Macbook";
  networking.computerName = "Nathan-Macbook";
  system.primaryUser = username;

  users.users."${username}" = {
    home = "/Users/${username}";
    description = username;
    shell = pkgs.zsh;
  };
}

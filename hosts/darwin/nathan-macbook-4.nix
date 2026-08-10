# Host-specific configuration for Nathan-Macbook-4
# Receives: username, sharedPackages, darwinPackages via extraSpecialArgs
{ pkgs, lib, username, sharedPackages, darwinPackages, ... }:
{
  # Host identity
  networking.hostName = "Nathan-Macbook-4";
  networking.computerName = "Nathan-Macbook-4";

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
      # Orion's link-hover preview popup is a real AXStandardWindow, so bsp
      # tiles it like any other window and squeezes everything else into a
      # 3-way split. Float it instead so it doesn't touch the layout.
      yabai -m rule --add app="Orion" title="^Orion Preview$" manage=off
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

      # Resize window — try the edge facing the keypress; if that edge has no bsp
      # fence (window is against the screen edge), fall back to the opposite edge.
      # Running both unconditionally (previous approach) double-resizes interior
      # windows and silently no-ops on edge windows, since one side always fails.
      ctrl + alt - h : yabai -m window --resize left:-40:0 || yabai -m window --resize right:40:0
      ctrl + alt - l : yabai -m window --resize right:40:0 || yabai -m window --resize left:-40:0
      ctrl + alt - j : yabai -m window --resize bottom:0:40 || yabai -m window --resize top:0:-40
      ctrl + alt - k : yabai -m window --resize top:0:-40 || yabai -m window --resize bottom:0:40

      # Float / fullscreen
      shift + alt - space : yabai -m window --toggle float --grid 4:4:1:1:2:2
      alt - f : yabai -m window --toggle zoom-fullscreen

      # Layout — set the current space's layout directly
      alt - b : yabai -m space --layout bsp
      alt - s : yabai -m space --layout stack
      alt - t : yabai -m space --layout float

      # Layout — cycle bsp -> stack -> float -> bsp on the current space.
      # yabai only ships these 3 layout types (no monocle), so cycling covers
      # all of them; avoids jq since skhd's launchd PATH doesn't include it.
      alt - space : t=$(yabai -m query --spaces --space | sed -n 's/.*"type":"\([a-z]*\)".*/\1/p'); if [ "$t" = "bsp" ]; then yabai -m space --layout stack; elif [ "$t" = "stack" ]; then yabai -m space --layout float; else yabai -m space --layout bsp; fi

      # Stack navigation (only meaningful when the space's layout is stack)
      alt - n : yabai -m window --focus stack.next
      alt - p : yabai -m window --focus stack.prev

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
      ../../modules/home/kitty.nix
    ];

    _module.args.sharedPackages = sharedPackages;

    home.username = username;
    home.homeDirectory = "/Users/${username}";
    home.packages = (darwinPackages pkgs) ++ (with pkgs; [ kitty ]);
  };
}

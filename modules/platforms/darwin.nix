{ inputs, pkgs, lib, username, useremail, ... }:
{
  system.stateVersion = 5;
  nixpkgs.config.allowUnfree = true;
  nixpkgs.hostPlatform = "aarch64-darwin";

  # Manage the Nix daemon + /etc/nix/nix.conf through nix-darwin. This assumes
  # Nix was installed with the OFFICIAL installer — bootstrap.sh uses it on
  # macOS for exactly this reason. If you switch a Mac to Determinate Nix,
  # set `nix.enable = false`: Determinate manages its own daemon, and the two
  # fight over /etc/nix and the launchd daemon.
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

  # Mission Control prerequisites for yabai on macOS 26 (Tahoe) — see
  # https://github.com/asmvik/yabai/wiki#installation-requirements
  system.defaults.spaces.spans-displays = false; # each display keeps its own Spaces
  system.defaults.dock.mru-spaces = false; # keep space order stable for alt-1..4 shortcuts
  system.defaults.WindowManager.StandardHideDesktopIcons = false; # "Show Items On Desktop" — multi-display focus reliability
  system.defaults.WindowManager.EnableStandardClickToShowDesktop = false; # "Click wallpaper to reveal Desktop" -> Only in Stage Manager

  homebrew = {
    enable = true;
    brews = [ ];
    casks = [ "kitty" "alacritty" ];
  };

  environment.systemPackages = with pkgs; [
    nixfmt
    jq
  ];

  # Clipse clipboard manager listener
  launchd.user.agents.clipse = {
    serviceConfig = {
      ProgramArguments = [
        "${pkgs.clipse}/bin/clipse"
        "-listen"
      ];
      KeepAlive = true;
      RunAtLoad = true;
      StandardOutPath = "/tmp/clipse.out.log";
      StandardErrorPath = "/tmp/clipse.err.log";
    };
  };

  # SSH Server — speed-optimized for LAN and Tailscale
  # Port 22: macOS built-in Remote Login — password auth allowed (default)
  # Port 2222: custom sshd instance — key-only auth (no passwords)
  #   ET: et -p 2222 <username>@<host>
  #   ET needs port 2022 (default) open for its own connection
  # Shared sshd config (applies to both ports)
  services.openssh = {
    enable = true;
    extraConfig = ''
      PermitRootLogin no
      UseDNS no
      Compression no
      ClientAliveInterval 60
      ClientAliveCountMax 3
      MaxSessions 10
      Ciphers aes256-gcm@openssh.com,chacha20-poly1305@openssh.com
      MACs hmac-sha2-256-etm@openssh.com,hmac-sha2-512-etm@openssh.com
    '';
  };

  # Custom sshd on port 2222 — key-only auth, no passwords
  launchd.daemons.sshd-custom = {
    serviceConfig = {
      Label = "org.nixos.sshd-custom";
      ProgramArguments = [
        "/usr/sbin/sshd"
        "-D"
        "-f" "/etc/ssh/sshd_config"
        "-o" "Port=2222"
        "-o" "PasswordAuthentication=no"
        "-o" "KbdInteractiveAuthentication=no"
      ];
      KeepAlive = true;
      RunAtLoad = true;
      StandardErrorPath = "/var/log/sshd-custom.log";
    };
  };

  system.primaryUser = username;

  users.users."${username}" = {
    home = "/Users/${username}";
    description = username;
    shell = pkgs.zsh;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAA_REPLACE_WITH_PUBLIC_KEY user@example-host"
    ];
  };
}

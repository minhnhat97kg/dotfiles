{ inputs, pkgs, lib, username, useremail, ... }:
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
    brews = [ ];
    casks = [ "kitty" ];
  };

  environment.systemPackages = with pkgs; [
    nixfmt-rfc-style
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

  system.primaryUser = username;

  users.users."${username}" = {
    home = "/Users/${username}";
    description = username;
    shell = pkgs.zsh;
  };
}

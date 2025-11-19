{ inputs, pkgs, username, sharedHomeConfig, ... }:
{
  system.stateVersion = 5;
  nixpkgs.config.allowUnfree = true;
  nixpkgs.hostPlatform = "aarch64-darwin";
  nix = {
    enable = true;
    package = pkgs.nix;
    gc = { automatic = true; options = "--delete-older-than 7d"; };
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      substituters = [ "https://cache.nixos.org" "https://nix-community.cachix.org" ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];
    };
  };
  programs.zsh.enable = true;
  environment.systemPackages = with pkgs; [ nixfmt-rfc-style jq yabai skhd sketchybar jankyborders qutebrowser ];
  services.yabai.enable = true;
  services.skhd.enable = true;
  services.sketchybar.enable = true;
  networking.hostName = "Nathan-Macbook";
  networking.computerName = "Nathan-Macbook";
  system.primaryUser = username;
  users.users."${username}".shell = pkgs.zsh;
  nix.settings.trusted-users = [ username ];
}

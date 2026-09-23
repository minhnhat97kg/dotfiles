# modules/platforms/linux.nix
# Shared home-manager configuration for all Linux platforms
# (Ubuntu bare-metal, Termux via Nix standalone home-manager)
{ pkgs, lib, ... }:
{
  imports = [ ../home/default.nix ];

  # Required for standalone home-manager
  programs.home-manager.enable = true;

  # Required by nix.settings — must specify the Nix package
  nix.package = pkgs.nix;

  # Enable Nix flakes + keep the store from growing forever. Standalone
  # home-manager hosts get no GC otherwise (nix-darwin does this for macOS in
  # modules/platforms/darwin.nix). GC runs via a systemd user timer — harmless
  # where systemd --user isn't running (e.g. Termux).
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    auto-optimise-store = true;
  };
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };
}

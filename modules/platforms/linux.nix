# modules/platforms/linux.nix
# Shared home-manager configuration for all Linux platforms
# (Ubuntu bare-metal, WSL, Termux via Nix standalone home-manager)
{ pkgs, lib, ... }:
{
  imports = [ ../home/default.nix ];

  # Required for standalone home-manager
  programs.home-manager.enable = true;

  # Required by nix.settings — must specify the Nix package
  nix.package = pkgs.nix;

  # Enable Nix flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
}

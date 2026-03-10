# modules/platforms/linux.nix
# Shared home-manager configuration for all Linux platforms
# (Ubuntu bare-metal, WSL, Termux via Nix standalone home-manager)
{ lib, ... }:
{
  imports = [ ../home/default.nix ];

  # Required for standalone home-manager
  programs.home-manager.enable = true;

  # Enable Nix flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
}

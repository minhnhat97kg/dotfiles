# Host-specific configuration for nathan-macbook
# Receives: username, darwinPackages via specialArgs (sharedPackages reaches
# home-manager through its extraSpecialArgs)
{ pkgs, lib, username, darwinPackages, ... }:
{
  networking.hostName = "nathan-macbook";
  networking.computerName = "nathan-macbook";

  home-manager.users.${username} = { pkgs, lib, ... }: {
    imports = [
      ../../modules/home/default.nix
      ../../modules/home/kitty.nix
      ../../modules/home/qutebrowser.nix
      ../../modules/home/caelestia-static.nix
    ];

    home.username = username;
    home.homeDirectory = "/Users/${username}";
    home.packages = darwinPackages pkgs; # kitty comes from the Homebrew cask
  };
}

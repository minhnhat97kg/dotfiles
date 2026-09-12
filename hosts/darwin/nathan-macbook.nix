# Host-specific configuration for nathan-macbook
# Receives: username, sharedPackages, darwinPackages via extraSpecialArgs
{ pkgs, lib, username, sharedPackages, darwinPackages, ... }:
{
  # Host identity
  networking.hostName = "nathan-macbook";
  networking.computerName = "nathan-macbook";

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

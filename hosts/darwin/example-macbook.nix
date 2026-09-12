# Host-specific configuration for an example MacBook
# Receives: username, sharedPackages, darwinPackages via extraSpecialArgs
{ pkgs, lib, username, sharedPackages, darwinPackages, ... }:
{
  # Host identity
  networking.hostName = "nhath";
  networking.computerName = "nhath";

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

# Host-specific configuration for Nathan's MacBook
# Receives: username, sharedPackages, darwinPackages via extraSpecialArgs
{ pkgs, lib, username, sharedPackages, darwinPackages, ... }:
{
  # Host identity
  networking.hostName = "Nathan-Macbook";
  networking.computerName = "Nathan-Macbook";

  # Home-manager user config
  home-manager.users.${username} = { pkgs, lib, ... }: {
    imports = [ ../../modules/home/default.nix ];

    _module.args.sharedPackages = sharedPackages;

    home.username = username;
    home.homeDirectory = "/Users/${username}";
    home.packages = (darwinPackages pkgs) ++ (with pkgs; [ kitty ]);

  };
}

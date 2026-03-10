# hosts/linux/ubuntu.nix
# Home-manager config for Ubuntu bare-metal (x86_64-linux)
{ pkgs, lib, sharedPackages, ... }:
{
  home.username = "nhath";
  home.homeDirectory = "/home/nhath";
  home.stateVersion = "24.11";

  _module.args.sharedPackages = sharedPackages;
}

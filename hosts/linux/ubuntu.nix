# hosts/linux/ubuntu.nix
# Home-manager config for Ubuntu bare-metal (x86_64-linux) — niri desktop.
{ ... }:
{
  imports = [ ../../modules/home/linux-desktop.nix ];

  home.username = "nhathuynh";
  home.homeDirectory = "/home/nhathuynh";
  home.stateVersion = "24.11";
}

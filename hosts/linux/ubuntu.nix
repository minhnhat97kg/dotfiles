# hosts/linux/ubuntu.nix
# Home-manager config for Ubuntu bare-metal (x86_64-linux) — niri desktop.
{ pkgs, lib, sharedPackages, linuxDesktopPackages, ... }:
{
  imports = [
    ../../modules/home/niri.nix
    ../../modules/home/qutebrowser.nix
    ../../modules/home/fcitx5.nix
    ../../modules/home/tui-tools.nix
    ../../modules/home/kitty.nix
    ../../modules/home/podman.nix
  ];

  home.username = "nhathuynh";
  home.homeDirectory = "/home/nhathuynh";
  home.stateVersion = "24.11";

  _module.args.sharedPackages = sharedPackages;

  home.packages = linuxDesktopPackages pkgs;

  # qutebrowser package is a pip venv, not Nix — see modules/home/qutebrowser.nix.
  programs.zsh.shellAliases.qutebrowser =
    "QT_WAYLAND_DISABLE_WINDOWDECORATION=1 ~/.local/venvs/qutebrowser/bin/qutebrowser";
}

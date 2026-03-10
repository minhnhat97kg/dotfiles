# hosts/linux/wsl.nix
# Home-manager config for WSL (Windows Subsystem for Linux)
{ pkgs, lib, sharedPackages, ... }:
{
  home.username = "nhath";
  home.homeDirectory = "/home/nhath";
  home.stateVersion = "24.11";

  _module.args.sharedPackages = sharedPackages;

  # WSL-specific shell config
  programs.zsh.initContent = lib.mkAfter ''
    # WSL: Open browser via Windows default
    export BROWSER="wslview"

    # Fix DISPLAY for GUI apps if needed
    export DISPLAY=$(cat /etc/resolv.conf | grep nameserver | awk '{print $2}'):0.0
  '';
}

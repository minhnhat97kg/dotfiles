# hosts/linux/wsl.nix
# Home-manager config for WSL (Windows Subsystem for Linux)
{ pkgs, lib, sharedPackages, ... }:
{
  home.username = "nhath";
  home.homeDirectory = "/home/nhath";
  home.stateVersion = "24.11";

  _module.args.sharedPackages = sharedPackages;

  # WSL-specific packages
  home.packages = [ pkgs.wslu ];

  # WSL-specific shell config
  programs.zsh.initContent = lib.mkAfter ''
    # WSL: Open browser via Windows default
    export BROWSER="wslview"

    # Fix DISPLAY for GUI apps — only set if not already provided by WSLg
    if [ -z "$DISPLAY" ] && [ -f /etc/resolv.conf ]; then
      export DISPLAY=$(awk '/nameserver/{print $2; exit}' /etc/resolv.conf):0.0
    fi
  '';
}

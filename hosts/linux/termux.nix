# hosts/linux/termux.nix
# Home-manager config for Termux (Nix installed via nix-installer in Termux)
# Architecture: aarch64-linux
# Home dir: /data/data/com.termux/files/home  (standard Termux)
{ pkgs, lib, sharedPackages, ... }:
{
  home.username = "your-username";
  home.homeDirectory = "/data/data/com.termux/files/home";
  home.stateVersion = "24.11";

  # Termux: sharedPackages is now minimal and matches nvim language support.
  _module.args.sharedPackages = sharedPackages;

  # Termux-specific overrides
  programs.zsh.initContent = lib.mkAfter ''
    export TMPDIR=/data/data/com.termux/files/usr/tmp
    export EDITOR=nvim
    export VISUAL=nvim
    export PAGER=less
    export LESS="-R -F -X -S"
  '';

  # Nix package for aarch64 (overrides linux.nix default)
  nix.package = lib.mkForce pkgs.nix;
}

# modules/home/qutebrowser.nix
# Config only. On Linux the package is NOT from Nix: the Nix-built qutebrowser
# fails EGL/GPU init on non-NixOS (see hosts/linux/ubuntu-qutebrowser-venv.sh /
# `make qutebrowser-venv`); the shell alias is in modules/home/linux-desktop.nix.
# On macOS it's the Homebrew app, which reads ~/.qutebrowser; its quickmarks and
# bookmarks there are left alone (they're local, not these Linux ones).
{ pkgs, lib, ... }:
let
  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
  dir = if isDarwin then ".qutebrowser" else ".config/qutebrowser";
in
{
  home.file = {
    "${dir}/config.py".source = ../../shared/qutebrowser/config.py;
  } // lib.optionalAttrs (!isDarwin) {
    "${dir}/quickmarks".source = ../../shared/qutebrowser/quickmarks;
    "${dir}/bookmarks/urls".source = ../../shared/qutebrowser/bookmarks/urls;
  };
}

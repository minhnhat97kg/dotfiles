# modules/home/qutebrowser.nix
# Config only — cross-platform, shared by both the Linux and macOS hosts.
# The *package* is per-platform (see each host file):
#   - macOS: plain Nix package (works fine — no GPU/EGL issue there).
#   - Linux (ubuntu): NOT from Nix — the Nix-built qutebrowser fails EGL/GPU
#     init on that machine (QtWebEngine hits the same non-NixOS Mesa mismatch
#     as kitty, but harder: the window never paints and it exits silently).
#     Installed into a pip venv instead (see
#     hosts/linux/ubuntu-qutebrowser-venv.sh / `make qutebrowser-venv`), with
#     a shell alias pointing at it (see hosts/linux/ubuntu.nix).
{ ... }:
{
  home.file.".config/qutebrowser/config.py".source = ../../shared/qutebrowser/config.py;
  home.file.".config/qutebrowser/quickmarks".source = ../../shared/qutebrowser/quickmarks;
  home.file.".config/qutebrowser/bookmarks/urls".source = ../../shared/qutebrowser/bookmarks/urls;
}

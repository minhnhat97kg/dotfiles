# modules/platforms/linux.nix
# Shared home-manager configuration for all Linux platforms
# (Ubuntu bare-metal, Termux via Nix standalone home-manager)
{ pkgs, lib, ... }:
{
  imports = [ ../home/default.nix ];

  # Required for standalone home-manager
  programs.home-manager.enable = true;
  # Its man page build (options.json) trips a "derivation without a proper
  # context" warning on every switch; `home-manager option` still works.
  manual.manpages.enable = false;

  # Required by nix.settings — must specify the Nix package
  nix.package = pkgs.nix;

  # Enable Nix flakes + keep the store from growing forever. Standalone
  # home-manager hosts get no GC otherwise (nix-darwin does this for macOS in
  # modules/platforms/darwin.nix). GC runs via a systemd user timer — harmless
  # where systemd --user isn't running (e.g. Termux).
  # Only unrestricted settings belong here: this is the user's nix.conf, and
  # the daemon ignores (and warns about) restricted ones like
  # auto-optimise-store or substituters for a non-trusted user.
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    warn-dirty = false;
  };
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };
}

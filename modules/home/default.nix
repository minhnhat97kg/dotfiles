# Entry point for shared home-manager configuration.
# Imported by all platforms via hosts/*.nix — sharedPackages passed via _module.args.
{ pkgs, sharedPackages, ... }:
{
  imports = [
    ./shell.nix
    ./editor.nix
    ./terminal.nix
    ./git.nix
    ./files.nix
  ];

  home.stateVersion = "24.11";
  home.packages = sharedPackages pkgs;
}

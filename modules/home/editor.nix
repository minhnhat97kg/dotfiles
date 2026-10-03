{ pkgs, neovim-src, ... }:
{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    # Provider support pulled into the build only if used — init.lua disables
    # all providers at runtime (loaded_*_provider = 0), so keep them out.
    withNodeJs = false;
    withPython3 = false;
    withRuby = false;
    package = pkgs.neovim-unwrapped.overrideAttrs (_: {
      src = neovim-src;
      version = "0.12.5";
      # The functional test suite is flaky/unavailable in the Nix sandbox for
      # a source version that differs from nixpkgs' own pin.
      doCheck = false;
      doInstallCheck = false;
    });
  };
}

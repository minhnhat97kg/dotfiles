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
      version = "0.12.0";
    });
  };
}

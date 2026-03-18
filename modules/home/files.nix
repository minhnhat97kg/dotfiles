{ ... }:
{
  programs.lazygit = {
    enable = true;
    enableZshIntegration = false; # Disable lg() function, use simple alias instead
  };

  programs.direnv.enable = true;

  home.file.".config/nvim/" = {
    source = ../../nvim;
    recursive = true;
    force = true;
  };
  home.file.".scripts/" = {
    source = ../../scripts;
    recursive = true;
    executable = true;
    force = true;
  };
}

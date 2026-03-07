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
  };
  home.file.".config/kitty/kitty.conf".source = ../../kitty/kitty.conf;
  home.file.".scripts/" = {
    source = ../../scripts;
    recursive = true;
    executable = true;
    force = true;
  };
  home.file.".config/dotfiles/scripts/load-aliases.sh" = {
    source = ../../scripts/load-aliases.sh;
    executable = true;
  };
  home.file.".fzf.zsh".source = ../../fzf/fzf.zsh;
}

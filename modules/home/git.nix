{ lib, ... }:
{
  programs.git = {
    enable = true;
    includes = [
      { path = "~/.config/git/gitconfig"; }
      { condition = "gitdir:~/work/**"; path = "~/.config/git/work.gitconfig"; }
      { condition = "gitdir:~/projects/**"; path = "~/.config/git/personal.gitconfig"; }
    ];
  };

  home.file.".config/git/gitconfig".source = ../../shared/git/gitconfig;
  home.file.".config/git/personal.gitconfig".source = ../../shared/git/personal.gitconfig;
  home.file.".config/git/work.gitconfig" = lib.mkIf (builtins.pathExists ../../shared/git/work.gitconfig) {
    source = ../../shared/git/work.gitconfig;
    force = true;
  };
}

{ lib, ... }:
{
  programs.git = {
    enable = true;
    includes = [
      { path = "~/.config/git/gitconfig"; }
      { condition = "gitdir:~/buuuk/**"; path = "~/.config/git/buuuk.gitconfig"; }
      { condition = "gitdir:~/Documents/work/company/buuuk/**"; path = "~/.config/git/buuuk.gitconfig"; }
      { condition = "gitdir:~/work/**"; path = "~/.config/git/work.gitconfig"; }
      { condition = "gitdir:~/projects/**"; path = "~/.config/git/minhnhat97kg.gitconfig"; }
    ];
  };

  home.file.".config/git/gitconfig".source = ../../git/gitconfig;
  home.file.".config/git/minhnhat97kg.gitconfig".source = ../../git/minhnhat97kg.gitconfig;
  home.file.".config/git/work.gitconfig" = lib.mkIf (builtins.pathExists ../../git/work.gitconfig) {
    source = ../../git/work.gitconfig;
    force = true;
  };
  home.file.".config/git/buuuk.gitconfig" = lib.mkIf (builtins.pathExists ../../git/buuuk.gitconfig) {
    source = ../../git/buuuk.gitconfig;
  };
}

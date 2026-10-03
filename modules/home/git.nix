# work.gitconfig is gitignored, so the flake can't see it — copy
# shared/git/work.gitconfig.template to ~/.config/git/work.gitconfig by hand.
{ ... }:
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
}

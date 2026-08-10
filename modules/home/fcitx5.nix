# modules/home/fcitx5.nix
# Fcitx5 input method config — Vietnamese via the "Lotus" method (fcitx5-unikey).
# fcitx5 itself and its GTK/Qt frontend modules must stay apt-installed: they
# register into system-wide immodule paths that a user-level Nix profile can't
# reach on a non-NixOS machine.
{ ... }:
{
  home.file.".config/fcitx5/profile".source = ../../linux/fcitx5/profile;
  home.file.".config/fcitx5/config".source = ../../linux/fcitx5/config;
  home.file.".config/fcitx5/conf" = {
    source = ../../linux/fcitx5/conf;
    recursive = true;
  };
}

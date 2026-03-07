# Host-specific configuration for Nathan's MacBook
# Receives: username, sharedPackages, darwinPackages via extraSpecialArgs
{ pkgs, lib, username, sharedPackages, darwinPackages, ... }:
{
  # Host identity
  networking.hostName = "Nathan-Macbook";
  networking.computerName = "Nathan-Macbook";

  # Home-manager user config
  home-manager.users.${username} = { pkgs, lib, ... }: {
    imports = [ ../../modules/home/default.nix ];

    _module.args.sharedPackages = sharedPackages;

    home.username = username;
    home.homeDirectory = "/Users/${username}";
    home.packages = (darwinPackages pkgs) ++ (with pkgs; [ kitty ]);

    home.file.".config/kitty/kitty.conf" = {
      source = ../../kitty/kitty.conf;
      force = true;
    };
    home.file.".ideavimrc".source = ../../shell/.ideavimrc;
    home.file.".config/git/ignore" = {
      source = ../../git/ignore;
      force = true;
    };
    home.file.".config/lazygit/" = {
      source = ../../lazygit;
      recursive = true;
    };
    home.file.".pspgconf".source = ../../pspg/pspgconf;
    home.file.".config/qutebrowser/config.py".source = ../../qutebrowser/config.py;
    home.file.".config/qutebrowser/profiles.yaml".source = ../../qutebrowser/profiles.yaml;
    home.file.".local/bin/qb-profile" = {
      source = ../../qutebrowser/qb-profile;
      executable = true;
    };
    home.file.".local/bin/qb-picker" = {
      source = ../../qutebrowser/qb-picker;
      executable = true;
    };
    home.file.".local/bin/qb-picker-gui" = {
      source = ../../qutebrowser/qb-picker-gui;
      executable = true;
    };
    home.file.".config/qutebrowser/create-qb-launcher.sh" = {
      source = ../../qutebrowser/create-qb-launcher.sh;
      executable = true;
    };
  };
}

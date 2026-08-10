# modules/home/tui-tools.nix
# btop (system monitor) + superfile (TUI file manager) config.
# Packages come from linuxDesktopPackages (see flake.nix).
{ ... }:
{
  home.file.".config/btop/btop.conf".source = ../../shared/btop/btop.conf;

  home.file.".config/superfile/config.toml".source = ../../shared/superfile/config.toml;
  home.file.".config/superfile/hotkeys.toml".source = ../../shared/superfile/hotkeys.toml;
}

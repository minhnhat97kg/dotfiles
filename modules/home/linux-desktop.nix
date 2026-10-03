# modules/home/linux-desktop.nix
# The niri desktop role: compositor + Caelestia shell, GTK look, input method,
# browser/terminal configs, containers. A Linux host with a screen imports this
# and adds only its identity (see hosts/linux/ubuntu.nix).
{ pkgs, linuxDesktopPackages, ... }:
{
  imports = [
    ./niri.nix
    ./gtk.nix
    ./qutebrowser.nix
    ./fcitx5.nix
    ./tui-tools.nix
    ./kitty.nix
    ./podman.nix
  ];

  home.packages = linuxDesktopPackages pkgs;

  # qutebrowser package is a pip venv, not Nix — see modules/home/qutebrowser.nix.
  programs.zsh.shellAliases.qutebrowser =
    "QT_WAYLAND_DISABLE_WINDOWDECORATION=1 ~/.local/venvs/qutebrowser/bin/qutebrowser";

  # Plugging in a headset/DAC makes it the default output and mic (like
  # PulseAudio's switch-on-connect). Unplugging falls back to the next device.
  xdg.configFile."pipewire/pipewire-pulse.conf.d/switch-on-connect.conf".text = ''
    pulse.cmd = [
      { cmd = "load-module" args = "module-switch-on-connect" flags = [ ] }
    ]
  '';
}

# modules/home/gtk.nix
# GTK appearance for the macOS-look desktop: WhiteSur theme, icons, cursor.
# Packages come from linuxDesktopPackages (see packages.nix); imported via
# modules/home/linux-desktop.nix.
#
# The Caelestia shell draws its own theme and ignores GTK; what this reaches
# is every GTK application window, the symbolic icons the tray pulls, and the
# pointer.
{ pkgs, config, ... }:
{
  gtk = {
    enable = true;
    theme = {
      name = "WhiteSur-Dark";
      package = pkgs.whitesur-gtk-theme;
    };
    iconTheme = {
      name = "WhiteSur-dark";
      package = pkgs.whitesur-icon-theme;
    };
    # home.stateVersion here (24.11) predates the 26.05 default flip, where
    # gtk4.theme stops inheriting gtk.theme automatically; pin the current
    # (still-inheriting) behavior explicitly so home-manager stops warning.
    gtk4.theme = config.gtk.theme;
  };

  # Set through home.pointerCursor rather than gtk.cursorTheme so XCURSOR_THEME
  # is exported too — niri, and any Wayland client that reads the env rather
  # than gsettings, needs that to pick the cursor up.
  home.pointerCursor = {
    enable = true;
    name = "WhiteSur-cursors";
    package = pkgs.whitesur-cursors;
    size = 24;
    gtk.enable = true;
    x11.enable = true;
  };
}

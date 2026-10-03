# modules/home/kitty.nix
# Single source of truth for kitty config across all hosts (Linux + macOS).
# Platform differences (font, macos_* options, shell path, Kanagawa theme
# include) are conditioned on pkgs.stdenv.hostPlatform.isDarwin below.
{ pkgs, lib, config, ... }:
let
  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
in
{
  home.file = {
    ".config/kitty/kitty.conf".text = ''
      ${if isDarwin then ''
        macos_option_as_alt yes

        font_family JetBrainsMono NFM
        bold_font auto
        italic_font auto
        bold_italic_font auto
      '' else ''
        font_family      JetBrainsMono NFM
        bold_font        auto
        italic_font      auto
        bold_italic_font auto
      ''}
      font_size ${if isDarwin then "14" else "12"}

      map ctrl+shift+equal    change_font_size all +0.5
      map ctrl+shift+plus     change_font_size all +0.5
      map ctrl+shift+kp_add   change_font_size all +0.5
      map ctrl+shift+minus    change_font_size all -0.5
      map ctrl+shift+kp_subtract change_font_size all -0.5
      map ctrl+shift+backspace change_font_size all 0

      ${if isDarwin then "macos_titlebar_color background" else "shell /usr/bin/zsh"}

      window_padding_width 1
      hide_window_decorations ${if isDarwin then "no" else "yes"}
      cursor_shape beam
      cursor_blink_interval 0
      tab_bar_edge top
      tab_bar_style powerline
      tab_powerline_style slanted
      allow_remote_control yes
      # Glass: translucent background. On Linux niri blurs behind it (see the
      # kitty window-rule in niri/config.kdl); background_blur is macOS-only.
      background_opacity 0.9
      dynamic_background_opacity yes
      ${if isDarwin then "background_blur 20" else ""}
      # Linux's default (1.0 0) makes light text on dark glass look thin and
      # washed out; thicken it (gamma 1.7) and add 30% contrast.
      ${if isDarwin then "" else "text_composition_strategy 1.7 30"}

      # BEGIN_KITTY_THEME
      # Kanagawa-Wave
      include current-theme.conf
      # END_KITTY_THEME
      ${if isDarwin then "" else ''
        # Caelestia shell palette (light/dark); overrides the
        # theme above and is live-reloaded by the shell on every change.
        include ${config.home.homeDirectory}/.local/state/quickshell/user/generated/terminal/kitty-theme.conf
      ''}
      # A preset scheme's colours (empty for the seed scheme), written by
      # caelestia-theme-sync (modules/home/niri.nix) on Linux and by
      # modules/home/caelestia-static.nix on macOS.
      include ${config.home.homeDirectory}/.local/state/caelestia/kitty-colors.conf
    '';
    ".config/kitty/current-theme.conf".source = ../../shared/kitty/current-theme.conf;
  };
}

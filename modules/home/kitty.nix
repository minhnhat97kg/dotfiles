# modules/home/kitty.nix
# Single source of truth for kitty config across all hosts (Linux + macOS).
# Platform differences (font, macos_* options, shell path, Kanagawa theme
# include) are conditioned on pkgs.stdenv.hostPlatform.isDarwin below.
{ pkgs, lib, ... }:
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
      hide_window_decorations no
      cursor_shape beam
      cursor_blink_interval 0
      tab_bar_edge top
      tab_bar_style powerline
      tab_powerline_style slanted

      # BEGIN_KITTY_THEME
      # Kanagawa-Wave
      include current-theme.conf
      # END_KITTY_THEME
    '';
    ".config/kitty/current-theme.conf".source = ../../shared/kitty/current-theme.conf;
  };
}

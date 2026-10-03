# modules/home/caelestia-static.nix
# macOS has no Caelestia shell, so write the files it would: the palette from
# shared/theme/theme.nix, taken from the shell's own preset table, as
# scheme.json (read by Neovim's colors/caelestia.lua and qutebrowser's
# config.py), tmux-theme.conf and kitty-colors.conf (same format as
# caelestia-theme-sync in modules/home/niri.nix). Presets only; a "dynamic"
# scheme needs the shell to generate it.
# Each file also comes in a -light/-dark pair (theme.nix's scheme plus its
# counterpart flavour, same pairing as niri.nix) so kitty, tmux and Neovim
# follow the macOS appearance.
{ pkgs, lib, caelestia-shell, ... }:
let
  theme = import ../../shared/theme/theme.nix;
  inherit (lib) elemAt splitString;
  pair = {
    "catppuccin latte" = "catppuccin mocha"; "catppuccin frappe" = "catppuccin latte";
    "catppuccin macchiato" = "catppuccin latte"; "catppuccin mocha" = "catppuccin latte";
    "rosepine dawn" = "rosepine main"; "rosepine main" = "rosepine dawn";
    "rosepine moon" = "rosepine dawn";
  }.${theme.scheme} or theme.scheme;
  other = if theme.mode == "light" then "dark" else "light";
  # gen <scheme> <mode> <suffix>: scheme.json, tmux-theme.conf, kitty-colors.conf
  gen = scheme: mode: sfx: let
    name = elemAt (splitString " " scheme) 0;
    flavour = elemAt (splitString " " scheme) 1;
  in ''
    jq --arg n ${name} --arg f ${flavour} --arg m ${mode} \
      '{name: $n, flavour: $f, mode: $m, variant: "tonalspot", colours: .[$n][$f]}' \
      ${caelestia-shell}/services/scheme.json > $out/scheme${sfx}.json
    c() { jq -r --arg k "$1" '"#" + .colours[$k]' $out/scheme${sfx}.json; }
    cat > $out/tmux-theme${sfx}.conf <<EOF
    set -g @c_bg        "$(c background)"
    set -g @c_surface   "$(c surfaceContainerHigh)"
    set -g @c_gray3     "$(c outlineVariant)"
    set -g @c_border    "$(c outlineVariant)"
    set -g @c_dim       "$(c outline)"
    set -g @c_muted     "$(c onSurfaceVariant)"
    set -g @c_text      "$(c onSurface)"
    set -g @c_accent    "$(c primary)"
    set -g @c_on_accent "$(c onPrimary)"
    set -g @c_sel       "$(c primaryContainer)"
    set -g @c_yellow    "$(c term3)"
    set -g @c_green     "$(c term2)"
    set -g @c_red       "$(c error)"
    EOF
    {
      echo "background $(c background)"
      echo "foreground $(c onSurface)"
      echo "cursor $(c primary)"
      echo "selection_background $(c primaryContainer)"
      echo "selection_foreground $(c onPrimaryContainer)"
      for i in $(seq 0 15); do echo "color$i $(c term$i)"; done
    } > $out/kitty-colors${sfx}.conf
  '';
  files = pkgs.runCommand "caelestia-static-theme" { nativeBuildInputs = [ pkgs.jq ]; } ''
    mkdir $out
    ${gen theme.scheme theme.mode ""}
    ${gen theme.scheme theme.mode "-${theme.mode}"}
    ${gen pair other "-${other}"}
  '';
in
{
  home.file = lib.genAttrs
    (map (f: ".local/state/caelestia/${f}") (lib.concatMap (s: [ "scheme${s}.json" "tmux-theme${s}.conf" "kitty-colors${s}.conf" ]) [ "" "-light" "-dark" ]))
    (p: { source = "${files}/${baseNameOf p}"; }) // {
    # kitty swaps these in when macOS changes appearance, over kitty.conf's colours.
    ".config/kitty/light-theme.auto.conf".source = "${files}/kitty-colors-light.conf";
    ".config/kitty/dark-theme.auto.conf".source = "${files}/kitty-colors-dark.conf";
  };
}

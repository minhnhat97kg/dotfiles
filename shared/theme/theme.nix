# The desktop theme, in one place. The Caelestia shell, GTK (WhiteSur
# Light/Dark), kitty, tmux, Neovim and niri's focus ring all follow it (see
# modules/home/niri.nix). Change a value, run `make install` (the shell restarts
# into it), and everything re-themes; the wallpaper no longer sets colours.
{
  # A preset palette "<name> <flavour>", or "dynamic default" to build one from
  # `seed` below. Presets: catppuccin latte|frappe|macchiato|mocha, rosepine
  # dawn|main|moon, gruvbox hard|medium|soft, darkgreen hard|medium, onedark,
  # oldworld, shadotheme (all `default` flavour). Pick a flavour matching `mode`
  # (latte and dawn are the light ones).
  scheme = "catppuccin latte";
  mode = "light"; # "light" or "dark"
  seed = "#8B6F47"; # used by "dynamic default": sepia, cream "paper" surfaces
  # How the palette is built from the seed: tonalspot (calm, default),
  # vibrant, expressive, fidelity, content, neutral, monochrome, rainbow,
  # fruitsalad.
  variant = "tonalspot";
}

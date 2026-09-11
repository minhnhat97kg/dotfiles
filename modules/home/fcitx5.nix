# modules/home/fcitx5.nix
# Fcitx5 input method config — Vietnamese via the "Lotus" method (fcitx5-unikey).
# fcitx5 itself and its GTK/Qt frontend modules must stay apt-installed: they
# register into system-wide immodule paths that a user-level Nix profile can't
# reach on a non-NixOS machine.
{ lib, ... }:
let
  # fcitx5 OWNS all of its config at runtime. It rewrites `profile` (last-active
  # IM), `config` (global settings/hotkeys), and every per-addon `conf/*.conf`:
  # Lotus writes the active `Mode` on each mode-switch (a keyboard shortcut used
  # during normal typing), and its settings GUI rewrites app rules, macros and
  # keymaps. A read-only Nix symlink therefore loses the race on every
  # `home-manager switch` and spawns *.hmbak backups (we had 27 pile up).
  #
  # So we SEED each file once, only when it is absent, and let fcitx5 own it
  # thereafter — exactly the pattern already used for `profile`. Consequence:
  # editing a file in the repo does NOT update an existing install; to re-seed,
  # delete the target (or edit it in place). The repo copy is the fresh-install
  # seed and the source of truth in version control.
  seedIfAbsent = src: dst: ''
    if [ ! -e "${dst}" ]; then
      run mkdir -p "$(dirname "${dst}")"
      run cp -T "${src}" "${dst}"
      run chmod 600 "${dst}"
    fi
  '';
in
{
  home.activation.seedFcitx5 = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ${seedIfAbsent "${../../linux/fcitx5/profile}" "$HOME/.config/fcitx5/profile"}
    ${seedIfAbsent "${../../linux/fcitx5/config}" "$HOME/.config/fcitx5/config"}

    # Seed every conf/*.conf that isn't already present.
    for src in ${../../linux/fcitx5/conf}/*; do
      dst="$HOME/.config/fcitx5/conf/$(basename "$src")"
      if [ ! -e "$dst" ]; then
        run mkdir -p "$(dirname "$dst")"
        run cp -T "$src" "$dst"
        run chmod 600 "$dst"
      fi
    done
  '';
}

# modules/home/niri.nix
# Wayland desktop stack: niri (compositor) + Caelestia shell (bar, launcher,
# dashboard, notifications, OSD, wallpaper) + kanata (keyboard remapper).
# Packages come from linuxDesktopPackages (see packages.nix); imported via
# modules/home/linux-desktop.nix.
{ config, pkgs, caelestia-shell, nixgl, ... }:
let
  theme = import ../../shared/theme/theme.nix;

  # Python for the shell's scripts/ (colour generation, manga/novel readers,
  # web wallpapers). They look for a venv at CAELESTIA_VIRTUAL_ENV, else use
  # python3 from PATH — this env serves as both.
  caelestiaPython = pkgs.python3.withPackages (ps: with ps; [
    materialyoucolor pillow opencv4 numpy
    requests curl-cffi beautifulsoup4 lxml urllib3
  ]);

  # The launcher's OCR/Lens actions run `qs -c <config> ipc ...`; with the
  # Nix package the config is passed by path instead, so drop `-c <name>`.
  qsShim = pkgs.writeShellScriptBin "qs" ''
    [ "$1" = -c ] && shift 2
    exec caelestia-shell "$@"
  '';

  # Programs the shell calls that the fork's package doesn't ship: matugen
  # (wallpaper colour scheme, light/dark), app2unit (launching apps),
  # tesseract (OCR), jq (scripts read shell.json). withCli adds `caelestia`,
  # which the control center's colour-scheme picker calls.
  #
  # Patches:
  # - nixpkgs' materialyoucolor renamed primary_paletteKeyColor, which made the
  #   palette generator crash and leave material_colors.scss empty.
  # - CMake installs the fork's .sh scripts without the exec bit (e.g.
  #   applycolor.sh, which writes kitty's theme): "Permission denied". It also
  #   copies its templates out of the read-only store, so the second theme
  #   change couldn't overwrite them — copy without the store's mode. Its
  #   kitty template also has a trailing // comment, which kitty rejects.
  # - The launcher started apps as children of the shell, so they inherited
  #   nixGL's Mesa and Nix Qt's plugin paths and crashed (qutebrowser, other
  #   system-Qt/GTK apps). Launch through app2unit instead; APP2UNIT_TYPE=service
  #   (unit Environment below) gives each app the session's clean environment.
  #   The default terminal is foot, which isn't installed; use kitty.
  # - switchwall.sh sets the GTK theme to adw-gtk3, which isn't installed; it
  #   replaced WhiteSur (modules/home/gtk.nix) and made snapd-desktop-integration
  #   offer to install "missing themes". Switch between WhiteSur Light/Dark.
  # - Colours come from shared/theme/theme.nix's seed instead of the
  #   wallpaper: CAELESTIA_SEED (unit Environment) makes both the shell's
  #   matugen run and the palette script build from it. Its startup
  #   regeneration raced the scheme state loading, so regenerate once
  #   explicitly after start; no wallpaper is needed with a seed.
  # - The launcher's Light/Dark actions only regenerated the dynamic scheme, so
  #   on a preset (e.g. Catppuccin Latte) they flipped `mode` but kept the
  #   colours. Now a preset switches to its light/dark flavour (Latte <->
  #   Mocha, Dawn <-> Main), or falls back to the seed scheme if it has none.
  # - The live terminal recolour sent the background as `OSC 11;[100]#rrggbb`
  #   (urxvt's alpha syntax), which kitty rejects: the foreground changed but
  #   the background didn't, leaving light-on-light text after a mode switch.
  # - Clicking a notification destroyed its card inside the card's own click
  #   handler, which can wedge the pointer grab (shell stops responding).
  #   Discards are deferred one event-loop turn instead.
  # - Lock screen PAM: the fork's config adds pam_faillock, which can't write
  #   its tally as a normal user, so it would refuse every password. Plain
  #   pam_unix needs /run/wrappers/bin/unix_chkpwd, and the shell's polkit
  #   agent needs /run/wrappers/bin/polkit-agent-helper-1; without it the
  #   prompt loops holding exclusive keyboard focus, freezing the desktop
  #   (both linked by hosts/linux/ubuntu-apt-deps.sh).
  caelestia = (caelestia-shell.packages.${pkgs.system}.default.override {
    withCli = true;
    extraRuntimeDeps = [ pkgs.matugen pkgs.app2unit pkgs.tesseract pkgs.jq caelestiaPython qsShim ];
  }).overrideAttrs (old: {
    postPatch = (old.postPatch or "") + ''
      substituteInPlace scripts/colors/generate_colors_material.py \
        --replace-fail "material_colors['primary_paletteKeyColor']" "material_colors['primaryPaletteKeyColor']"
      echo 'auth required pam_unix.so' > assets/pam.d/passwd
      sed -i 's| *//.*$||' scripts/colors/terminal/kitty-theme.conf
      # Leave the 256-colour greys (232-255) alone: the templates repaint them
      # with palette colours for starship, which turns apps that use them
      # (Claude Code's code text is 236, its message background 255) into
      # near-white-on-white or brown bars.
      sed -i '/^color2[3-5][0-9] /d' scripts/colors/terminal/kitty-theme.conf
      sed -i -E 's/\x1b\]4;2[3-5][0-9];[^\x1b]*\x1b\\//g' scripts/colors/terminal/sequences.txt
      substituteInPlace modules/launcher/services/Apps.qml \
        --replace-fail 'command: [...entry.command],' 'command: ["app2unit", "--", ...entry.command],' \
        --replace-fail 'command: [...Config.general.apps.terminal,' 'command: ["app2unit", "--", ...Config.general.apps.terminal,'
      substituteInPlace config/GeneralConfig.qml --replace-fail '["foot"]' '["kitty"]'
      substituteInPlace services/Schemes.qml --replace-fail \
        '["matugen", "image", colorSource,' \
        '[...(Quickshell.env("CAELESTIA_SEED") ? ["matugen", "color", "hex", Quickshell.env("CAELESTIA_SEED")] : ["matugen", "image", colorSource]),'
      substituteInPlace services/Schemes.qml \
        --replace-fail '            if (!wallpaper) {' '            if (!wallpaper && !Quickshell.env("CAELESTIA_SEED")) {' \
        --replace-fail '    // Process for generating dynamic scheme from wallpaper using matugen' \
          '    Timer { interval: 1500; running: Quickshell.env("CAELESTIA_SEED") !== null; onTriggered: { const s = (Quickshell.env("CAELESTIA_SCHEME") || "dynamic default").split(" "); root.setScheme(s[0], s[1]); } }'
      substituteInPlace scripts/colors/generate_colors_material.py \
        --replace-fail $'\nimport argparse\n' $'\nimport argparse, os\n' \
        --replace-fail "default=None, help='generate colorscheme from color'" "default=os.environ.get('CAELESTIA_SEED'), help='generate colorscheme from color'" \
        --replace-fail $'\nif args.path is not None:' $'\nif args.color is None and args.path is not None:'
      substituteInPlace scripts/colors/switchwall.sh \
        --replace-fail "'adw-gtk3-dark'" "'WhiteSur-Dark'" \
        --replace-fail "'adw-gtk3'" "'WhiteSur-Light'"
      substituteInPlace scripts/colors/applycolor.sh --replace-fail \
        'cp "$SCRIPT_DIR/terminal/' 'cp -f --no-preserve=mode "$SCRIPT_DIR/terminal/'
      # On a preset scheme (scheme.json carries term0..15) caelestia-theme-sync
      # themes the terminals; this would still push the seed palette (sepia) to
      # every pty, and whichever ran last won — tmux panes ended up sepia.
      substituteInPlace scripts/colors/applycolor.sh --replace-fail \
        $'apply_term() {\n' \
        $'apply_term() {\n  [ -n "$(jq -r \'.colours.term0 // empty\' "$HOME/.local/state/caelestia/scheme.json" 2>/dev/null)" ] && return\n'
      substituteInPlace services/Schemes.qml --replace-fail \
        $'        if (root.currentScheme.startsWith("dynamic")) {\n            setScheme("dynamic", "default");\n        }' \
        $'        if (root.currentScheme.startsWith("dynamic")) {\n            setScheme("dynamic", "default");\n            return;\n        }\n        const [name, flavour] = root.currentScheme.split(" ");\n        const bg = schemesDataFile.json?.[name]?.[flavour]?.background ?? "";\n        if ((parseInt(bg.slice(0, 2), 16) > 128) === Colours.light) {\n            setScheme(name, flavour);\n            return;\n        }\n        const pair = { "catppuccin latte": "mocha", "catppuccin frappe": "latte", "catppuccin macchiato": "latte", "catppuccin mocha": "latte", "rosepine dawn": "main", "rosepine main": "dawn", "rosepine moon": "dawn" }[root.currentScheme];\n        if (pair) setScheme(name, pair);\n        else setScheme("dynamic", "default");'
      substituteInPlace scripts/colors/terminal/sequences.txt \
        --replace-fail ']11;[100]#' ']11;#' --replace-fail ']708;[100]#' ']708;#'
      substituteInPlace services/Notifs.qml --replace-fail \
        'function discardNotification(id: int): void {' \
        $'function discardNotification(id: int): void { Qt.callLater(root._discardNow, id); }\n    function _discardNow(id: int): void {'
    '';
    postInstall = (old.postInstall or "") + ''
      find $out/share/caelestia-shell/scripts -name '*.sh' -exec chmod +x {} +
    '';
  });

  lock = "${caelestia}/bin/caelestia-shell ipc call lock lock";

  # The shell writes its active palette to scheme.json on every scheme change
  # (seed or preset like Catppuccin; material_colors.scss only follows the
  # seed). This turns it into tmux's @c_* palette and niri's focus ring, and
  # reloads tmux. Neovim reads scheme.json itself
  # (shared/nvim/colors/caelestia.lua). kitty gets the shell's own generated
  # kitty-theme.conf (modules/home/kitty.nix).
  themeSync = pkgs.writeShellScript "caelestia-theme-sync" ''
    scheme=$HOME/.local/state/caelestia/scheme.json
    out=$HOME/.local/state/caelestia/tmux-theme.conf
    [ -s "$scheme" ] || exit 0
    c() { ${pkgs.jq}/bin/jq -r --arg k "$1" '"#" + .colours[$k]' "$scheme"; }
    mkdir -p "''${out%/*}"
    cat > "$out" <<EOF
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
    # niri's focus ring/border; linux/niri/config.kdl includes this file and
    # live-reloads when it changes.
    cat > "''${out%/*}/niri-colors.kdl" <<EOF
    layout {
        focus-ring { active-color "$(c primary)"; inactive-color "$(c outlineVariant)"; }
        border { active-color "$(c primary)"; inactive-color "$(c outlineVariant)"; urgent-color "$(c error)"; }
    }
    EOF
    # kitty: the shell only writes terminal colours for the seed scheme, so for a
    # preset (whose scheme.json carries term0..15) write them here — a file for
    # new windows (modules/home/kitty.nix includes it last), escape sequences
    # for the running terminals and tmux panes, as the shell's applycolor.sh does.
    kitty=''${out%/*}/kitty-colors.conf
    if [ -n "$(${pkgs.jq}/bin/jq -r '.colours.term0 // empty' "$scheme")" ]; then
      osc="\033]10;$(c onSurface)\007\033]11;$(c background)\007\033]12;$(c primary)\007"
      {
        echo "background $(c background)"
        echo "foreground $(c onSurface)"
        echo "cursor $(c primary)"
        echo "selection_background $(c primaryContainer)"
        echo "selection_foreground $(c onPrimaryContainer)"
        for i in $(seq 0 15); do
          echo "color$i $(c term$i)"
          osc="$osc\033]4;$i;$(c term$i)\007"
        done
      } > "$kitty"
      for pts in /dev/pts/[0-9]*; do [ -O "$pts" ] && printf "$osc" > "$pts" 2>/dev/null || true; done
    else
      : > "$kitty"
    fi
    # Undo the greys (232-255) earlier palettes repainted (see the caelestia
    # postPatch) in the running terminals and tmux panes.
    reset="\033]104$(printf ';%s' $(seq 232 255))\007"
    for pts in /dev/pts/[0-9]*; do [ -O "$pts" ] && printf "$reset" > "$pts" 2>/dev/null || true; done
    ${pkgs.procps}/bin/pkill -USR1 -x kitty || true
    # qutebrowser reads scheme.json in its config.py; re-source it in a running
    # instance (only if one is running, or this would open a window).
    qb=$HOME/.local/venvs/qutebrowser/bin/qutebrowser
    if [ -x "$qb" ] && ${pkgs.procps}/bin/pgrep -f "$qb" >/dev/null; then "$qb" :config-source || true; fi

    tmux=${pkgs.tmux}/bin/tmux
    $tmux source-file "$out" 2>/dev/null || exit 0
    $tmux list-clients -F '#{client_name}' | while read -r cl; do $tmux refresh-client -S -t "$cl"; done
  '';
in
{
  # Auto reload/restart changed systemd user units on `home-manager switch`
  # instead of requiring a manual `systemctl --user daemon-reload`.
  systemd.user.startServices = "sd-switch";

  # systemd --user's own default PATH doesn't include the Nix profile — only
  # login shells get that via /etc/zshrc. Without this, niri.service (and
  # anything it spawns: the shell, kitty) can't find their binaries.
  #
  # This must NOT go through `systemd.user.sessionVariables` (home-manager
  # hardcodes that into "10-home-manager.conf") — Ubuntu ships
  # /usr/lib/environment.d/99-environment.conf and 990-snapd.conf, which sort
  # *after* "10-..." and unconditionally reset PATH, wiping this out. environment.d
  # merges by lexicographic filename across ALL of /usr/lib, /run, /etc, and
  # ~/.config — last filename wins per-key, so ours must sort after those too.
  #
  # This only takes effect on the *next* full login (environment.d is read
  # once at user-manager startup) — the running session needs a manual
  # `systemctl --user set-environment PATH=...` to pick it up immediately.
  xdg.configFile."environment.d/zz-nix-path.conf".text = ''
    PATH=$HOME/.nix-profile/bin:$PATH
  '';

  # No fonts.fontconfig.enable here: the Caelestia wrapper sets its own
  # FONTCONFIG_FILE with the fonts it needs, and everything else uses
  # ~/.local/share/fonts, which fontconfig searches by default.

  home.file.".config/niri" = {
    source = ../../linux/niri;
    recursive = true;
  };

  home.file.".config/swaylock/config".source = ../../linux/swaylock/config;

  home.file.".config/warpd/config".source = ../../linux/warpd/config;

  home.file.".config/kanata/kanata.kbd".source = ../../linux/kanata/kanata.kbd;

  # kanshi: dynamic output profiles by connected-monitor set. See linux/kanshi/config
  # for the profiles and kanshi.service below for how it is run.
  home.file.".config/kanshi/config".source = ../../linux/kanshi/config;

  # kanata needs read/write on /dev/uinput — add the user to the "input"
  # group and set up the matching udev rule outside of home-manager (requires
  # root); this repo only manages the config + service.
  systemd.user.services.kanata = {
    Unit = {
      Description = "Kanata keyboard remapper";
      After = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.kanata}/bin/kanata --cfg %h/.config/kanata/kanata.kbd";
      Restart = "on-failure";
      RestartSec = 2;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  # kanshi: applies the output layout matching the connected-monitor set (see
  # linux/kanshi/config). It talks to niri over the wlr-output-management protocol via
  # the Wayland socket, so — like swayidle — it just needs WAYLAND_DISPLAY
  # from graphical-session.target, not niri's IPC socket. Restarts on failure and
  # re-applies whenever outputs change on their own.
  systemd.user.services.kanshi = {
    Unit = {
      Description = "kanshi — dynamic output profiles";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
      Requisite = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.kanshi}/bin/kanshi";
      Restart = "on-failure";
      RestartSec = 2;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  # Caelestia shell: bar, launcher, dashboard, notifications, OSD, clipboard,
  # wallpaper, session menu.
  # Driven over IPC from linux/niri/config.kdl (`caelestia-shell ipc call ...`).
  #
  # Run through nixGL: Nix's Mesa fails eglGetDisplay on this host (the same
  # reason kitty is apt-installed), and Quickshell needs real GL for its
  # shaders. Only this unit is wrapped — the IPC calls need no GL.
  #
  # Config is ~/.config/niri_caelestia/shell.json (this fork's path, not
  # upstream's ~/.config/caelestia) — edit it live from the control center.
  # The lock screen is Caelestia's too (see the PAM patch above).
  systemd.user.services.caelestia = {
    Unit = {
      Description = "Caelestia shell";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
      Requisite = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${nixgl.packages.${pkgs.system}.nixGLIntel}/bin/nixGLIntel ${caelestia}/bin/caelestia-shell";
      Environment = [
        "CAELESTIA_VIRTUAL_ENV=${caelestiaPython}"
        "APP2UNIT_TYPE=service"
        "CAELESTIA_SEED=${theme.seed}"
        # Quoted: systemd splits Environment= on spaces ("catppuccin latte").
        "\"CAELESTIA_SCHEME=${theme.scheme}\""
        # Qt has no platform theme here, so tray/menu icons fell back to the
        # missing-icon checkerboard. Use the GTK icon theme, which lives in
        # the Nix profile (not on the default XDG_DATA_DIRS).
        "QS_ICON_THEME=${config.gtk.iconTheme.name}"
        "XDG_DATA_DIRS=%h/.nix-profile/share:/usr/local/share:/usr/share:/var/lib/snapd/desktop"
      ];
      # Start in theme.nix's mode: the shell reads light/dark from scheme.json
      # and regenerates every palette from the seed on startup. (The launcher's
      # >light / >dark still switch until the next restart.)
      ExecStartPre = "${pkgs.writeShellScript "caelestia-theme-mode" ''
        f=$HOME/.local/state/caelestia/scheme.json
        mkdir -p "''${f%/*}"
        [ -s "$f" ] || echo '{"variant":"tonalspot","colours":{}}' > "$f"
        ${pkgs.jq}/bin/jq --arg s "${theme.scheme}" '($s | split(" ")) as [$n, $fl] | .name=$n | .flavour=$fl | .mode="${theme.mode}" | .variant="${theme.variant}"' "$f" > "$f.tmp" && mv "$f.tmp" "$f"
      ''}";
      Restart = "always";
      RestartSec = 1;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  home.packages = [ caelestia ];

  # The shell's scripts (e.g. applycolor.sh, kitty's theme) cd into the
  # config's conventional path, and `qs -c niri-caelestia-shell` finds it here.
  xdg.configFile."quickshell/niri-caelestia-shell".source = "${caelestia}/share/caelestia-shell";

  systemd.user.services.caelestia-theme-sync = {
    Unit.Description = "Sync tmux and niri colours with the Caelestia palette";
    Service = { Type = "oneshot"; ExecStart = "${themeSync}"; };
    Install.WantedBy = [ "graphical-session.target" ];
  };
  systemd.user.paths.caelestia-theme-sync = {
    Unit.Description = "Watch the Caelestia palette";
    Path.PathChanged = "%h/.local/state/caelestia/scheme.json";
    Install.WantedBy = [ "graphical-session.target" ];
  };

  # Idle management: lock after 5 min, blank the monitors after 5.5 min, and
  # suspend after 30 min. The screen also locks right before suspend (the
  # sleep gives the async IPC lock time to cover the screen), so it is already
  # locked on resume. niri powers monitors back on automatically on input.
  #
  # The `lock`/`unlock` handlers route `loginctl lock-session` /
  # `unlock-session` to the Caelestia lock screen.
  #
  # Escape hatch if the lock ever can't unlock: switch to a TTY, then
  # `systemctl --user restart caelestia` (niri keeps the session locked) and
  # `WAYLAND_DISPLAY=wayland-1 swaylock` — apt's swaylock is still installed.
  systemd.user.services.swayidle = {
    Unit = {
      Description = "swayidle — lock on idle, on request, and before sleep";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
      Requisite = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = ''
        ${pkgs.swayidle}/bin/swayidle -w \
          timeout 300 '${lock}' \
          timeout 330 '${pkgs.niri}/bin/niri msg action power-off-monitors' \
          timeout 1800 '/usr/bin/systemctl suspend' \
          lock '${lock}' \
          unlock '${caelestia}/bin/caelestia-shell ipc call lock unlock' \
          before-sleep '${lock}; sleep 1'
      '';
      Restart = "on-failure";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  # Clipboard history: watch the Wayland clipboard and record every change into
  # cliphist's store. wl-paste is the apt build (/usr/bin); cliphist is from Nix.
  # Caelestia's clipboard drawer reads this store (Mod+Shift+C).
  systemd.user.services.cliphist = {
    Unit = {
      Description = "cliphist — record clipboard history";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
      Requisite = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "/usr/bin/wl-paste --watch ${pkgs.cliphist}/bin/cliphist store";
      Restart = "on-failure";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  # Power management (AC/battery profiles, device runtime-PM) is handled
  # system-wide by TLP, installed via hosts/linux/ubuntu-apt-deps.sh.
}

# modules/home/niri.nix
# Wayland desktop stack: niri (compositor) + waybar (bar) + fuzzel (launcher)
# + swaync (notifications) + kanata (keyboard remapper).
# Packages come from linuxDesktopPackages (see flake.nix) — imported by hosts
# that run this desktop (currently just hosts/linux/ubuntu.nix).
{ ... }:
{
  # Auto reload/restart changed systemd user units on `home-manager switch`
  # instead of requiring a manual `systemctl --user daemon-reload`.
  systemd.user.startServices = "sd-switch";

  # systemd --user's own default PATH doesn't include the Nix profile — only
  # login shells get that via /etc/zshrc. Without this, niri.service (and
  # anything it spawns: waybar, fuzzel, kitty) can't
  # find their binaries now that the apt/manual duplicates are gone.
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

  home.file.".config/niri" = {
    source = ../../linux/niri;
    recursive = true;
  };

  home.file.".config/waybar" = {
    source = ../../linux/waybar;
    recursive = true;
  };

  home.file.".config/fuzzel" = {
    source = ../../linux/fuzzel;
    recursive = true;
  };

  # swaync: notification daemon + control center, replacing mako. Linked as a
  # directory because it is two files that must stay in step — config.json
  # (behaviour) and style.css (appearance, GTK4 dialect; see the note at the
  # top of that file for why it differs from waybar's GTK3 stylesheet).
  home.file.".config/swaync" = {
    source = ../../linux/swaync;
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
      ExecStart = "%h/.nix-profile/bin/kanata --cfg %h/.config/kanata/kanata.kbd";
      Restart = "on-failure";
      RestartSec = 2;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  # kanshi: applies the output layout matching the connected-monitor set (see
  # linux/kanshi/config). It talks to niri over the wlr-output-management protocol via
  # the Wayland socket, so — like waybar/swayidle — it just needs WAYLAND_DISPLAY
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
      ExecStart = "%h/.nix-profile/bin/kanshi";
      Restart = "on-failure";
      RestartSec = 2;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  # Waybar itself, supervised directly by systemd. Running the binary as the
  # unit's main process (rather than as a disowned child of a wrapper script)
  # is what makes Restart=always actually work: when the compositor restarts,
  # waybar's Wayland connection breaks and it exits ("Error reading events from
  # display: Broken pipe") — systemd then brings it right back. The previous
  # design supervised the watcher wrapper instead, so a waybar crash left the
  # wrapper blocked in inotifywait and the bar never came back.
  systemd.user.services.waybar = {
    Unit = {
      Description = "Waybar status bar";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
      Requisite = [ "graphical-session.target" ];
    };
    Service = {
      # launch.sh picks the active output (built-in when the lid is open,
      # external when closed), bakes it into a runtime config, then `exec`s
      # waybar — so waybar stays the unit's main process and Restart works.
      ExecStart = "%h/.config/waybar/scripts/launch.sh";
      Restart = "always";
      RestartSec = 1;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  # Hot-reload watcher: on a config/style edit (e.g. `home-manager switch`
  # swapping the symlink) restart the supervised waybar.service above. This no
  # longer launches waybar itself — it only pokes systemd.
  systemd.user.services.waybar-watch = {
    Unit = {
      Description = "Restart waybar when its config or style changes";
      PartOf = [ "graphical-session.target" ];
      After = [ "waybar.service" ];
      Requisite = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "%h/.config/waybar/scripts/watch-reload.sh";
      Restart = "on-failure";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  # swaync — notification daemon + control center. A supervised unit, unlike the
  # `spawn-at-startup "mako"` it replaces: that made the daemon an orphan
  # reparented to systemd --user, so if it died notifications stopped silently
  # for the rest of the session, and restarting niri spawned a second copy that
  # could not claim the org.freedesktop.Notifications bus name. Restart=always
  # fixes both.
  #
  # X-Config-Path is not read by systemd (it ignores X- keys) — it exists so the
  # unit's text changes whenever linux/swaync/ changes, which is what makes
  # sd-switch restart the daemon on `home-manager switch`. Without it a config
  # edit would sit in the store unread until the next login, since swaync only
  # reads config.json at startup.
  systemd.user.services.swaync = {
    Unit = {
      Description = "swaync — notification daemon and control center";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
      Requisite = [ "graphical-session.target" ];
      X-Config-Path = "${../../linux/swaync}";
    };
    Service = {
      # launch.sh copies config.json into $XDG_RUNTIME_DIR and draws the toggle
      # labels from live state, then execs swaync -c against that copy — so swaync
      # stays the unit's main process and Restart works. Same shape as waybar.
      ExecStart = "%h/.config/swaync/scripts/launch.sh";
      Restart = "always";
      RestartSec = 1;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  # Idle management: lock after 5 min, blank the monitors after 5.5 min, and
  # suspend after 30 min. swaylock always runs right before suspend too, so the
  # screen is already locked on resume. swaylock reads its appearance from
  # ~/.config/swaylock/config and is apt-installed, not Nix — the Nix build
  # lacks PAM and can't read /etc/shadow, so it can never unlock (see
  # hosts/linux/ubuntu-apt-deps.sh). niri powers monitors back on automatically
  # on input.
  #
  # The `lock`/`unlock` handlers make swayidle the single owner of swaylock: any
  # `loginctl lock-session` request (e.g. the waybar powermenu's "Lock" entry)
  # triggers a lock, and unlocking the session kills the locker. This is why the
  # powermenu routes through logind instead of spawning swaylock directly.
  systemd.user.services.swayidle = {
    Unit = {
      Description = "swayidle — lock on idle, on request, and before sleep";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
      Requisite = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = ''
        %h/.nix-profile/bin/swayidle -w \
          timeout 300 '/usr/bin/swaylock -f' \
          timeout 330 '%h/.nix-profile/bin/niri msg action power-off-monitors' \
          timeout 1800 '/usr/bin/systemctl suspend' \
          lock '/usr/bin/swaylock -f' \
          unlock '/usr/bin/pkill -x swaylock' \
          before-sleep '/usr/bin/swaylock -f'
      '';
      Restart = "on-failure";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  # Clipboard history: watch the Wayland clipboard and record every change into
  # cliphist's store. wl-paste is the apt build (/usr/bin); cliphist is from Nix.
  # Browse/restore entries with fuzzel via Mod+Shift+C (see clipboard.sh).
  systemd.user.services.cliphist = {
    Unit = {
      Description = "cliphist — record clipboard history";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
      Requisite = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "/usr/bin/wl-paste --watch %h/.nix-profile/bin/cliphist store";
      Restart = "on-failure";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  # Power management (AC/battery profile switching, device runtime-PM) is now
  # handled system-wide by TLP, installed via hosts/linux/ubuntu-apt-deps.sh.
  # The old ac-watch.sh + power-profiles-daemon service that used to live here
  # has been retired — TLP and PPD conflict.
}

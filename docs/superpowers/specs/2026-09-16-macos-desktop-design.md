# macOS 26 (Tahoe) desktop for the Ubuntu/niri host

Date: 2026-09-16
Status: design, awaiting review

## Goal

Make the `ubuntu` host's Wayland desktop read as macOS 26 "Tahoe" at a glance —
not "a dark Linux bar with Apple-ish glyphs". The test is the silhouette: a
transparent menu bar at the top, a floating glass dock at the bottom, real
backdrop blur, and macOS window chrome on GTK apps.

## Why the first attempt failed

A first pass restyled `linux/waybar/style.css`, `linux/fuzzel/fuzzel.ini` and
`linux/swaync/style.css` with a macOS palette. Measured against a screenshot of
the result, it was wrong on structure, not colour:

| First attempt | macOS 26 Tahoe |
| --- | --- |
| Dark translucent bar + hairline separator | Menu bar draws **no background at all**; no separator, no blur |
| Dark panels everywhere (`rgba(30,30,32,0.78)`) | Liquid Glass **lightens**: `rgba(255,255,255,0.10–0.16)` over a blurred backdrop |
| Spotlight selection in accent blue | Selection is a light translucent fill; accent-blue rows are the pre-Tahoe look |
| No dock | Every convincing clone has the **two-strip silhouette**: bar on top, dock at the bottom |
| CSS-only | CSS cannot reach tray icons, GTK window chrome, or cursors |

The single largest error was a false premise: that niri cannot blur. It can (see
Verified facts), which removes the main reason macOS rices have been
Hyprland-only.

## Amendment, 2026-09-16: the shell replacement was reverted

The approach below was executed as far as installing Noctalia, and then undone.
Noctalia builds and installs correctly but dies at startup with
`fatal: eglGetDisplay failed`. Its Wayland side comes up fine — layer-shell
bound, output detected, workspace backend chosen — and only GPU init fails.

This was foreseeable from inside this repo. `flake.nix` already documents that
Nix-built GUI applications fail EGL init on this host because Nix's bundled
Mesa/EGL does not match the system GPU driver; that is exactly why kitty is
apt-installed and qutebrowser lives in a pip venv. The research behind this spec
was sound, but it was never checked against that constraint.

Two cheap fixes were tried and ruled out: pointing
`__EGL_VENDOR_LIBRARY_DIRS` at the system ICD has no effect, and a blanket
`LD_LIBRARY_PATH` breaks glibc. Qt dlopens EGL, so a real fix means a
nixGL-style wrapper over the whole driver stack — a host-wide decision that
would change how every Nix GUI app here is launched, not a detail of this work.

**The revised approach keeps waybar, fuzzel and swaync**, and builds the macOS
silhouette on them: a wallpaper, niri's blur, a transparent menu bar, and a
second waybar instance as a floating dock.

This is not a retreat to the rejected option. waybar was rejected on the belief
that niri had no blur. It has: blur is a compositor-side `layer-rule` that
applies to waybar exactly as it would have to Noctalia. Combined with WhiteSur
and SF Pro, which are already installed, nothing about the achievable look
depended on which program drew the bar.

One design point changes as a result: **the menu bar gets no blur at all.** The
Tahoe menu bar has none — it is plain transparent. Blur is for the dock, the
launcher and the notification surfaces.

## Approach (original — superseded above for the shell, still current for everything else)

Replace the hand-tuned three-component shell (waybar + fuzzel + swaync) with
**Noctalia**, a Quickshell-based shell with first-class niri support that
provides bar, dock, launcher, notifications, control center, tray, OSD,
wallpaper and lock screen as one integrated whole. Then supply the parts no
shell provides: GTK theme, icon theme, cursors, and the real SF Pro font.

The alternative — keep waybar and push its CSS further — was rejected because
the best-looking waybar-based macOS clone found in research
(`kboost/hyprland-tahoe`) still reads as a Linux rice in its own screenshots.
Hand-written bar CSS has a visible ceiling.

## Verified facts

Checked directly on this machine, not taken from research:

- `niri --version` → **26.04 (Nixpkgs)**.
- `blur { passes 2; offset 3.0; noise 0.03; saturation 1.0 }` → `config is valid`.
  Note `radius` is **not** a key; an earlier probe using it produced a
  false negative that briefly suggested blur was untunable.
- `layer-rule { match namespace="…" background-effect { blur true; xray false } }`
  → `config is valid`.
- `layer-rule { match namespace="^noctalia-backdrop" place-within-backdrop true }`
  → `config is valid`.
- `whitesur-gtk-theme`, `whitesur-icon-theme`, `whitesur-cursors`, `swaybg`,
  `quickshell` and `noctalia-shell` all exist in nixpkgs.
- **No wallpaper is set on this host at all** — no swaybg/swww configured, no
  such process running. A transparent menu bar currently has nothing to reveal.
- SF Pro is **not** in nixpkgs, under any of `sf-pro`, `apple-fonts`,
  `san-francisco-font`, `sf-mono`.

## Unverified — must be confirmed during implementation

These come from research and are load-bearing, so each gets checked before it is
written into config:

- The nixpkgs `noctalia-shell` is **4.7.7**, a major version behind the v5 that
  all current docs describe. The plan uses the upstream **flake input**, whose
  home-manager module and TOML config model are v5 features.
- `noctalia msg panel-toggle notifications` for the notification center is
  reported as inferred rather than documented.
- v4-era settings names (`backgroundOpacity`, `frameRadius`, `outerCorners`,
  dock `floating`/`auto_hide`/`opacity`/`size`) are **not** confirmed to exist in
  v5, and the "macOS-Dark" scheme referenced in research is a third-party v4
  artifact, not a Noctalia builtin. Expect to hand-write a palette.
- No documented Noctalia command opens a clipboard-history panel.

## Design

### 1. Foundation (no rip-out, safe to do first)

- **Wallpaper.** Required before anything transparent means anything. Noctalia
  manages wallpaper itself, so swaybg is not needed; niri gets
  `layer-rule { match namespace="^noctalia-backdrop" place-within-backdrop true }`.
- **niri effects.** Global `blur { passes 2; offset 3.0; noise 0.03 }`, a
  `layer-rule` enabling `background-effect` on Noctalia's layer namespaces,
  `shadow` on windows, `gaps 16`, and the corner radius already raised to 20.
- **Themes.** `whitesur-gtk-theme`, `whitesur-icon-theme`, `whitesur-cursors`
  added to `linuxDesktopPackages`, wired through
  `gtk.theme` / `gtk.iconTheme` / `home.pointerCursor`. This is the part CSS
  cannot fake, and it restyles every GTK app window — most of the screen.
- **SF Pro.** Not redistributable via nixpkgs, so it follows this repo's
  existing precedent for things Nix cannot provide
  (`hosts/linux/ubuntu-apt-deps.sh`, `ubuntu-qutebrowser-venv.sh`): a new
  `hosts/linux/ubuntu-sf-fonts.sh` plus a `make` target, fetching and extracting
  Apple's package into `~/.local/share/fonts`. `fonts.fontconfig.enable` is
  already on.

### 2. Shell replacement

- Add the Noctalia flake input with `inputs.nixpkgs.follows = "nixpkgs"`, import
  `homeModules.default`, enable `programs.noctalia` with `systemd.enable`.
- Keep the config as a real file at `linux/noctalia/config.toml`, referenced by
  path from the module — matching this repo's "real config files live in
  `linux/`, Nix only links them" pattern.
- Hand-write a macOS Tahoe palette at `linux/noctalia/palettes/`.
- Rewire niri keybinds: `Mod+D` → `noctalia msg panel-toggle launcher`,
  `Mod+Tab` → `noctalia msg window-switcher`, `Mod+N` → notification panel,
  `Mod+Ctrl+N` → `noctalia msg notification-dnd-toggle`.
- **`Mod+Shift+C` keeps cliphist + fuzzel**, since Noctalia documents no
  clipboard-panel command. fuzzel therefore stays installed as a dmenu backend
  even though it stops being the app launcher.

### 3. Known GUI/declarative conflict

Noctalia's settings GUI writes `~/.local/state/noctalia/settings.toml`, which
loads *after* and overrides the declarative `~/.config/noctalia/*.toml`. So the
read-only-store problem this repo solves for waybar and swaync with runtime
copies does **not** apply here — but changes made in the GUI will silently
diverge from the repo. That trade is accepted and documented rather than worked
around.

## What is discarded

The custom waybar scripts — `network.sh` (dual-uplink default-route logic),
`brightness.sh`, `volume.sh`, `workspaces.sh`, `power-draw.sh`,
`notifications.sh` — have no home in Noctalia. This is the real cost of the
migration and is not recoverable by configuration.

## What stays untouched

kanata, kanshi, warpd, cliphist, kitty, podman, fcitx5, the tmux/nvim configs,
and every non-`ubuntu` host (macOS, WSL, Termux, Android). swaylock stays until
Noctalia's lock screen is confirmed working.

## Rollback

waybar/fuzzel/swaync configs stay in the repo as independent `home.file` links
through the whole migration, so reverting is a revert commit plus
`home-manager switch`, with home-manager generations as a backstop. The existing
macOS-styled waybar work is deliberately **not** reverted up front — it keeps a
working desktop available if Noctalia does not pan out.

## Risk

Noctalia ships roughly every 1–2 weeks and only recently stabilised v5; the
v4→v5 break (schemes→palettes, JSON→TOML) is the kind of churn to expect again.
A pinned flake input limits the blast radius to whenever the input is updated
deliberately.

## Success criteria

1. Screenshot shows the two-strip silhouette: transparent menu bar, floating dock.
2. Real backdrop blur visible behind bar, dock and launcher.
3. GTK apps draw WhiteSur headerbars with traffic lights.
4. Launcher, notifications, DND and window switcher all work from their keybinds.
5. Every other host still evaluates (`nix flake check` or a per-host build).
